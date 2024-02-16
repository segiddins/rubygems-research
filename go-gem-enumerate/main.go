package main

import (
	"archive/tar"
	"bytes"
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"hash"
	"io"
	"math"
	"os"
	"os/signal"
	"path"
	"runtime/trace"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/klauspost/compress/gzip"

	"net/http"
	_ "net/http/pprof"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	_ "github.com/mattn/go-sqlite3"
	"github.com/segiddins/go-gem-enumerate/pipes"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	sqlxtrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/jmoiron/sqlx"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
	"gopkg.in/natefinch/lumberjack.v2"
)

// var base = "/Users/segiddins/Development/github.com/akr/gem-codesearch/mirror/gems/"
var db *sqlx.DB

var logger *zap.Logger

var transport http.RoundTripper = &http.Transport{
	MaxIdleConns:       50,
	IdleConnTimeout:    5 * time.Second,
	MaxConnsPerHost:    50,
	DisableCompression: true,
}
var client *http.Client = httptrace.WrapClient(&http.Client{
	Transport: transport,
})

var gzWriterPool = sync.Pool{
	New: func() interface{} {
		return gzip.NewWriter(nil)
	},
}
var sha256Pool = sync.Pool{
	New: func() interface{} {
		return sha256.New()
	},
}

func readAlreadyGzipped(reader io.Reader) (Blob, error) {
	sha := sha256Pool.Get().(hash.Hash)
	defer sha256Pool.Put(sha)
	defer sha.Reset()
	gzipped := new(bytes.Buffer)
	reader = io.TeeReader(reader, gzipped)
	gzipReader, err := gzip.NewReader(reader)
	if err != nil {
		return Blob{}, fmt.Errorf("error creating gzip reader: %w", err)
	}
	defer gzipReader.Close()
	reader = io.TeeReader(gzipReader, sha)
	blob := Blob{}
	blob.Size, err = io.Copy(io.Discard, reader)
	if err != nil {
		return blob, err
	}
	blob.Contents = gzipped.Bytes()
	blob.Compression = sql.NullString{String: "gzip", Valid: true}
	blob.SHA256 = hex.EncodeToString(sha.Sum(nil))
	return blob, nil
}

type Blobs struct {
	contents map[string]Blob
}

func (b *Blobs) Len() int {
	return len(b.contents)
}

func (b *Blobs) EachSlice(n int, f func([]*Blob) error) error {
	slice := make([]*Blob, 0, n)
	for _, blob := range b.contents {
		blob := blob
		slice = append(slice, &blob)
		if len(slice) == n {
			if err := f(slice); err != nil {
				return err
			}
			slice = make([]*Blob, 0, n)
		}
	}
	if len(slice) > 0 {
		return f(slice)
	}
	return nil
}

func (b *Blobs) EachSliceWithoutId(n int, f func([]*Blob) error) error {
	slice := make([]*Blob, 0, n)
	for _, blob := range b.contents {
		blob := blob
		if blob.Id.Valid {
			continue
		}
		slice = append(slice, &blob)
		if len(slice) == n {
			if err := f(slice); err != nil {
				return err
			}
			slice = make([]*Blob, 0, n)
		}
	}
	if len(slice) > 0 {
		return f(slice)
	}
	return nil
}

func (b *Blobs) SetId(sha string, id int64) {
	blob, ok := b.contents[sha]
	if !ok {
		panic("missing blob for sha")
	}
	blob.Id = sql.NullInt64{Int64: id, Valid: true}
	contents := blob.Contents
	if contents != nil {
		blob.Compression = sql.NullString{}
		blob.Contents = nil
	}
	b.contents[sha] = blob
}

func (b *Blobs) Add(blob Blob) {
	if existing, ok := b.contents[blob.SHA256]; ok {
		if existing.Size != blob.Size || existing.SHA256 != blob.SHA256 {
			panic(fmt.Sprintf("expected to find blob for sha256 %s, but found %v", blob.SHA256, existing))
		}
		return
	}
	b.contents[blob.SHA256] = blob
}

type Blob struct {
	SHA256      string
	Contents    []byte
	Compression sql.NullString
	Size        int64
	Id          sql.NullInt64
}

type Entry struct {
	FullName  string `json:",omitempty"`
	Content   Blob   `json:",omitempty"`
	TarHeader *tar.Header
}

type ResultLine struct {
	Path    string
	Entries []Entry

	task     *trace.Task
	Err      string
	Metadata Blob
	Package  Blob

	SourceDateEpoch sql.NullTime

	Duration time.Duration
}

func entryToBlob(r io.Reader, e *tar.Header) (blob Blob, err error) {
	sha := sha256Pool.Get().(hash.Hash)
	sha.Reset()
	defer sha256Pool.Put(sha)
	defer sha.Reset()

	var gz *bytes.Buffer

	plain := bytes.NewBuffer(make([]byte, 0, int(e.Size)))
	var l int64
	r = io.TeeReader(r, sha)
	r = io.TeeReader(r, plain)
	if e.Size >= 32*1024 {
		gz = bytes.NewBuffer(make([]byte, 0, int(e.Size)/16))
		gzWriter := gzWriterPool.Get().(*gzip.Writer)
		gzWriter.Reset(gz)
		l, err = io.Copy(gzWriter, r)
		if err != nil {
			err = fmt.Errorf("error copying to gzip writer: %w", err)
			return
		}
		if err = gzWriter.Close(); err != nil {
			err = fmt.Errorf("error closing gzip writer: %w", err)
			return
		}
		gzWriter.Reset(nil)
		gzWriterPool.Put(gzWriter)
	} else {
		l, err = io.Copy(io.Discard, r)
		if err != nil {
			err = fmt.Errorf("error copying to /dev/null: %w", err)
			return
		}
	}

	if l != e.Size {
		return Blob{}, fmt.Errorf("expected to read %d bytes, but read %d", e.Size, l)
	}
	if l != int64(plain.Len()) {
		return Blob{}, fmt.Errorf("expected to read %d bytes, but read %d", e.Size, plain.Len())
	}

	blob.SHA256 = hex.EncodeToString(sha.Sum(nil))
	blob.Size = e.Size
	if gz != nil && plain.Len()-gz.Len() > 2048 {
		blob.Contents = gz.Bytes()
		blob.Compression = sql.NullString{String: "gzip", Valid: true}
	} else {
		blob.Contents = plain.Bytes()
	}

	if blob.Contents == nil {
		return blob, fmt.Errorf("missing blob contents for blob=%#v", blob)
	}

	return blob, nil
}

func readDataTarGz(r io.Reader) ([]Entry, error) {
	gz, err := gzip.NewReader(r)
	if err != nil {
		return nil, fmt.Errorf("error creating gzip reader: %w", err)
	}
	defer gz.Close()

	tarReader := tar.NewReader(gz)

	var entries []Entry
	for {
		entry, err := tarReader.Next()
		if err != nil {
			if err == io.EOF {
				break
			}
			return nil, fmt.Errorf("error reading data.tar.gz: %w", err)
		}
		blob, err := entryToBlob(tarReader, entry)
		if err != nil {
			return nil, fmt.Errorf("error reading data.tar.gz entry %s: %w", entry.Name, err)
		}
		entries = append(entries, Entry{
			FullName:  entry.Name,
			Content:   blob,
			TarHeader: entry,
		})
	}
	return entries, nil
}

func findContent(sha string) (content []byte) {
	row := db.QueryRow("select contents from blobs where sha256 = ? and contents is not null and compression is null", sha)

	if row.Scan(&content) != nil {
		content = nil
	}
	return
}

func readPackage(v *Version) (*ResultLine, error) {
	ctx, task := trace.NewTask(context.Background(), "readPackage")
	defer trace.StartRegion(ctx, "readPackage").End()
	path := "https://rubygems.org/gems/" + v.FullName() + ".gem"
	trace.Logf(ctx, "", "package path = %s", path)
	start := time.Now()
	r := &ResultLine{
		Path: path,
		task: task,
	}
	defer func() {
		logger.Debug("finished reading package",
			zap.String("path", r.Path), zap.String("sha256", r.Package.SHA256), zap.Duration("duration", r.Duration),
			zap.String("err", r.Err), zap.Int("entries", len(r.Entries)), zap.Time("source_date_epoch", r.SourceDateEpoch.Time),
		)
	}()
	defer func() {
		r.Duration = time.Since(start)
	}()

	var buffer *bytes.Buffer

	if content := findContent(v.Sha256.String); content != nil && v.Sha256.Valid {
		logger.Debug("found content for gem in db", zap.Any("version", v))
		buffer = bytes.NewBuffer(content)
	} else if strings.HasPrefix(path, "https://") {
		logger.Debug("falling back to downloading gem", zap.Any("version", v))
		region := trace.StartRegion(ctx, "download")
		resp, err := client.Get(path)
		if err != nil {
			r.Err = fmt.Sprintf("error downloading .gem: %v", err)
			region.End()
			return r, nil
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			r.Err = fmt.Sprintf("error downloading .gem: %v", resp.Status)
			region.End()
			return r, nil
		}

		contents, err := io.ReadAll(resp.Body)
		if err != nil {
			r.Err = fmt.Sprintf("error reading .gem: %v", err)
			region.End()
			return r, nil
		}
		buffer = bytes.NewBuffer(contents)
		resp.Body.Close()
		region.End()
	} else {
		contents, err := os.ReadFile(path)
		if err != nil {
			r.Err = fmt.Sprintf("error reading .gem: %v", err)
			return r, nil
		}
		buffer = bytes.NewBuffer(contents)
	}

	r.Package.Size = int64(buffer.Len())

	r.Package.Contents = bytes.Clone(buffer.Bytes())

	if r.Package.Size != int64(len(r.Package.Contents)) {
		return r, fmt.Errorf("package size mismatch, expected %d but got %d", r.Package.Size, len(r.Package.Contents))
	}

	sha := sha256Pool.Get().(hash.Hash)
	defer sha256Pool.Put(sha)
	defer sha.Reset()

	var reader io.Reader = buffer
	reader = io.TeeReader(reader, sha)

	tarReader := tar.NewReader(reader)

loop:
	for {
		entry, err := tarReader.Next()
		if err != nil {
			if err == io.EOF {
				break loop
			}
			r.Err = fmt.Sprintf("error reading .gem tar: %v", err)
			return r, nil
		}

		r.SourceDateEpoch.Time = entry.ModTime

		switch entry.Name {
		case "data.tar.gz":
			entries, err := readDataTarGz(tarReader)
			if err != nil {
				r.Err = fmt.Sprintf("error reading data.tar.gz: %v", err)
				return r, nil
			}
			r.Entries = append(r.Entries, entries...)
		case "metadata.gz":
			r.Metadata, err = readAlreadyGzipped(tarReader)
			if err != nil {
				r.Err = fmt.Sprintf("error reading metadata.gz: %v", err)
				return r, nil
			}
		case "checksums.yaml.gz.asc":
		case "checksums.yaml.gz.sig":
		case "checksums.yaml.gz":
		case "credentials.tar.gz":
		case "data.tar.gz.asc":
		case "data.tar.gz.sig":
		case "metadata.gz.asc":
		case "metadata.gz.sig":
		default:
			r.Err = fmt.Sprintf("unexpected file in gem: %v", entry.Name)
			return r, nil
		}
	}

	_, err := io.Copy(io.Discard, reader)
	if err != nil {
		r.Err = fmt.Sprintf("error reading rest of .gem: %v", err)
	}

	r.Package.SHA256 = hex.EncodeToString(sha.Sum(nil))

	return r, nil
}

type Version struct {
	Id          int64
	RubygemId   int64  `db:"rubygem_id"`
	RubygemName string `db:"name"`
	Number      string
	Platform    string
	Sha256      sql.NullString `db:"sha256"`
	SpecSha256  sql.NullString `db:"spec_sha256"`
	UploadedAt  sql.NullTime   `db:"uploaded_at"`
	// Metadata       any
	CreatedAt      sql.NullTime  `db:"created_at"`
	UpdatedAt      sql.NullTime  `db:"updated_at"`
	MetadataBlobId sql.NullInt64 `db:"metadata_blob_id"`
	// Position       sql.

	VersionDataEntriesCount int64 `db:"version_data_entries_count"`
}

func (v *Version) FullName() string {
	if v.RubygemName == "" {
		panic("expected RubygemName to be non-empty")
	}
	if v.Platform == "ruby" {
		return fmt.Sprintf("%s-%s", v.RubygemName, v.Number)
	} else {
		return fmt.Sprintf("%s-%s-%s", v.RubygemName, v.Number, v.Platform)
	}
}

var insertBlobsStatements map[int]*sqlx.Stmt = map[int]*sqlx.Stmt{}

func insertBlobs(db *sqlx.DB, tx *sqlx.Tx, blobs *Blobs) error {
	if blobs.Len() == 0 {
		return nil
	}

	err := blobs.EachSlice((1<<15)/1-2, func(slice []*Blob) error {
		sha256Slice := make([]string, 0, len(slice))
		for _, b := range slice {
			sha256Slice = append(sha256Slice, b.SHA256)
		}
		query, binds, err := sqlx.In("SELECT id, sha256 FROM blobs WHERE sha256 IN (?) and contents is not null", sha256Slice)
		if err != nil {
			return err
		}
		existing, err := tx.Queryx(query, binds...)
		if err != nil {
			return err
		}
		defer existing.Close()

		for existing.Next() {
			var id int64
			var sha256 string
			err := existing.Scan(&id, &sha256)
			if err != nil {
				return err
			}
			blobs.SetId(sha256, id)
		}
		return existing.Err()
	})
	if err != nil {
		return err
	}

	return blobs.EachSliceWithoutId((1<<15)/4-2, func(slice []*Blob) error {
		statement := insertBlobsStatements[len(slice)]
		if statement == nil {
			var err error
			rep := ",(?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
			query := fmt.Sprintf("INSERT INTO blobs (sha256, size, contents, compression, created_at, updated_at) VALUES %s ON CONFLICT(sha256) DO UPDATE set contents = EXCLUDED.contents, compression=EXCLUDED.compression WHERE contents is null RETURNING blobs.sha256, blobs.id, blobs.size", strings.Repeat(rep, len(slice))[1:])

			statement, err = db.Preparex(query)
			if err != nil {
				return err
			}
			insertBlobsStatements[len(slice)] = statement
		}

		args := make([]interface{}, 0, len(slice)*4)
		for _, b := range slice {
			contents := b.Contents

			args = append(args, b.SHA256, b.Size, contents, b.Compression)
		}
		rows, err := tx.Stmtx(statement).Queryx(args...)
		if err != nil {
			return err
		}
		defer rows.Close()
		count := 0
		for rows.Next() {
			var sha256 string
			var id int64
			var size int64
			err := rows.Scan(&sha256, &id, &size)
			if err != nil {
				return err
			}
			blob, ok := blobs.contents[sha256]
			if !ok {
				return fmt.Errorf("expected to find blob for sha256 %s", sha256)
			}
			if blob.Size != size {
				return fmt.Errorf("expected blob %s size to be %d, but was %d", sha256, blob.Size, size)
			}
			blobs.SetId(sha256, id)
			count += 1
		}
		if err := rows.Err(); err != nil {
			return err
		}
		if count != len(slice) {
			missing := make([]string, 0, len(slice)-count)
			for _, b := range slice {
				if !b.Id.Valid {
					missing = append(missing, b.SHA256)
				}
			}
			query, binds, err := sqlx.In("SELECT id, sha256, size FROM blobs where sha256 IN (?)", missing)
			if err != nil {
				return err
			}
			rows, err := tx.Queryx(query, binds...)
			if err != nil {
				return err
			}
			for rows.Next() {
				var b Blob
				var id int64
				err := rows.Scan(&id, &b.SHA256, &b.Size)
				if err != nil {
					return err
				}
				blobs.SetId(b.SHA256, id)
				count += 1
			}
			if err := rows.Err(); err != nil {
				return err
			}
		}
		if count != len(slice) {
			return fmt.Errorf("expected to insert %d blobs, but inserted %d", len(slice), count)
		}
		return nil
	})

}

var entriesStatements = map[int]*sqlx.Stmt{}

func insertEntries(tx *sqlx.Tx, version *Version, entries []Entry, blobs *Blobs) error {

	for len(entries) > 2000 {
		chunk := entries[:2000]
		entries = entries[2000:]
		if err := insertEntries(tx, version, chunk, blobs); err != nil {
			return err
		}
	}

	if len(entries) == 0 {
		return nil
	}

	statement := entriesStatements[len(entries)]
	if statement == nil {
		var err error
		rep := ",(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
		query := fmt.Sprintf("INSERT INTO version_data_entries (version_id, blob_id, full_name, name, mode, uid, gid, mtime, linkname, sha256, created_at, updated_at) VALUES %s ON CONFLICT(full_name, version_id) DO NOTHING", strings.Repeat(rep, len(entries))[1:])

		statement, err = db.Preparex(query)
		if err != nil {
			return err
		}
		entriesStatements[len(entries)] = statement
	}

	args := make([]interface{}, 0, len(entries)*9)
	for _, e := range entries {
		content := e.Content
		blob, ok := blobs.contents[content.SHA256]
		if !ok || blob.SHA256 != content.SHA256 || !blob.Id.Valid {
			return fmt.Errorf("expected to find blob for entry %s", e.FullName)
		}
		linkname := sql.NullString{String: e.TarHeader.Linkname, Valid: e.TarHeader.Typeflag == tar.TypeLink || e.TarHeader.Typeflag == tar.TypeSymlink}
		args = append(args, version.Id, blob.Id, e.FullName, path.Base(e.FullName), e.TarHeader.Mode, e.TarHeader.Uid, e.TarHeader.Gid, e.TarHeader.ModTime, linkname, blob.SHA256)
	}

	rows, err := tx.Stmtx(statement).Exec(args...)
	if err != nil {
		return err
	}
	if _, err := rows.LastInsertId(); err != nil {
		return err
	}
	if _, err := rows.RowsAffected(); err != nil {
		return err
	}

	return nil
}

type insertVersionInfoResults struct {
	skips     map[string][]string
	skipCount int
	total     int
}

func insertSingleVersionInfo(ctx context.Context, version *Version, r *ResultLine) error {
	span, ctx := tracer.StartSpanFromContext(ctx, "insertSingleVersionInfo")
	defer span.Finish()
	defer r.task.End()
	blobs := &Blobs{
		contents: map[string]Blob{},
	}
	blobs.Add(r.Package)
	blobs.Add(r.Metadata)

	for _, e := range r.Entries {
		content := e.Content
		blobs.Add(content)
	}

	tx := db.MustBeginTx(ctx, nil)
	defer tx.Rollback()

	err := insertBlobs(db, tx, blobs)
	if err != nil {
		return err
	}

	err = insertEntries(tx, version, r.Entries, blobs)
	if err != nil {
		return fmt.Errorf("error inserting %d entries: %w", len(r.Entries), err)
	}

	metadataBlobId := blobs.contents[r.Metadata.SHA256].Id
	if !metadataBlobId.Valid {
		return fmt.Errorf("expected to find metadata blob")
	}

	_, err = tx.Exec("INSERT INTO version_packages (version_id, sha256, source_date_epoch, created_at, updated_at) VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING", version.Id, r.Package.SHA256, r.SourceDateEpoch)
	if err != nil {
		return err
	}

	var result sql.Result
	result, err = tx.Exec("UPDATE versions SET metadata_blob_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", metadataBlobId, version.Id)
	if err != nil {
		return err
	}
	var rowsAffected int64
	rowsAffected, err = result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected != 1 {
		return fmt.Errorf("expected to update 1 row, but updated %d", err)
	}

	return tx.Commit()

}

func insertVersionInfo(versionsByBasename map[string]*Version) func(ctx context.Context, r *ResultLine) (insertVersionInfoResults, error) {
	return func(ctx context.Context, r *ResultLine) (res insertVersionInfoResults, err error) {
		res.skips = map[string][]string{}
		res.total += 1

		if len(r.Err) != 0 {
			res.skips[r.Err] = append(res.skips[r.Err], r.Path)
			res.skipCount += 1
			return
		}
		version := versionsByBasename[path.Base(r.Path)]
		if version == nil {
			res.skips["no version"] = append(res.skips["no version"], r.Path)
			res.skipCount += 1
			return
		}
		if !version.Sha256.Valid || len(version.Sha256.String) == 0 {
			res.skips["no SHA256"] = append(res.skips["no SHA256"], fmt.Sprintf("%s (version %d)", r.Path, version.Id))
			res.skipCount += 1
			return
		}
		if r.Package.SHA256 != version.Sha256.String {
			res.skips["mismatched SHA256"] = append(res.skips["mismatched SHA256"], fmt.Sprintf("%s (version %d, disk %s, db %s)", r.Path, version.Id, r.Package.SHA256, version.Sha256.String))
			res.skipCount += 1
			return
		}

		if err := insertSingleVersionInfo(ctx, version, r); err != nil {
			res.skips[err.Error()] = append(res.skips[err.Error()], r.Path)
			res.skipCount += 1
		}

		return
	}
}

func main() {
	tracer.Start(
		tracer.WithService("go-gem-enumerate"),
	)
	defer tracer.Stop()

	w := zapcore.AddSync(&lumberjack.Logger{
		Filename:   "/var/log/go-gem-enumerate/go-gem-enumerate.log",
		MaxSize:    500, // megabytes
		MaxBackups: 3,
		MaxAge:     28, // days
	})
	filecore := zapcore.NewCore(
		zapcore.NewJSONEncoder(zap.NewProductionEncoderConfig()),
		w,
		zap.DebugLevel,
	)
	stdoutcore := zapcore.NewCore(
		zapcore.NewConsoleEncoder(zap.NewDevelopmentEncoderConfig()),
		zapcore.AddSync(os.Stdout),
		zap.InfoLevel,
	)

	logger = zap.New(zapcore.NewTee(filecore, stdoutcore))

	go func() {
		err := http.ListenAndServe("localhost:6060", nil)
		logger.Info("Debug handler exited", zap.Error(err))
	}()
	// logf, err := os.Create("/tmp/go-gem-enumerate.log.jsonl")
	// if err != nil {
	// 	panic(err)
	// }
	// defer logf.Close()
	// slog.SetDefault(slog.New(
	// 	slog.NewJSONHandler(logf, &slog.HandlerOptions{}),
	// ))

	// var lg sqldblogger.Logger = &dblogger{}
	// sqldb := sqldblogger.OpenDriver("/root/Development/github.com/segiddins/rubygems-research/db/development/data.sqlite3", &sqlite3.SQLiteDriver{}, lg)
	// db = sqlx.NewDb(sqldb, "sqlite3")
	db = sqlxtrace.MustConnect("sqlite3", "/root/Development/github.com/segiddins/rubygems-research/db/development/data.sqlite3")
	defer db.Close()

	db.SetMaxOpenConns(4)

	versions, err := InsertRubygemsAndVersionsFromDump()
	if err != nil {
		panic(err)
	}

	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, os.Interrupt)

	versionsPipe := pipes.Map(pipes.From(versions...), func(v *Version) (*Version, error) {
		select {
		case <-sigchan:
			signal.Stop(sigchan)
			return nil, fmt.Errorf("cancelled on %#v", v)
		default:
			return v, nil
		}
	})
	chunkSize := 10000
	concurrency := 1
	if s, ok := os.LookupEnv("CONCURRENCY"); ok {
		i, err := strconv.ParseInt(s, 10, 16)
		if err != nil {
			logger.Panic("invalid value for CONCURRENCY", zap.Error(err), zap.String("concurrency", s))
		}
		concurrency = int(i)
	}
	packagesPipe := pipes.ConcurrentMap(versionsPipe, readPackage, concurrency).Buffered(concurrency)

	versionsByBasename := map[string]*Version{}
	for _, v := range versions {
		basename := v.FullName() + ".gem"
		versionsByBasename[basename] = v
	}

	start := time.Now()
	last := start

	insertions := pipes.Map(packagesPipe, insertVersionInfo(versionsByBasename))
	chunked := pipes.Chunk(insertions, chunkSize)

	result, err := pipes.Reduce(chunked, func(acc insertVersionInfoResults, results []insertVersionInfoResults) (insertVersionInfoResults, error) {
		for _, res := range results {
			acc.skipCount += res.skipCount
			acc.total += res.total
			for k, v := range res.skips {
				acc.skips[k] = append(acc.skips[k], v...)
			}
		}

		now := time.Now()
		dur := now.Sub(start)
		perS := float64(acc.total) / dur.Seconds()
		perS = math.Round(perS*100) / 100

		eta := time.Duration(float64(len(versions)-acc.total)/time.Nanosecond.Seconds()/perS) * time.Nanosecond
		logger.Info(
			"Chunk completed", zap.Duration("elapsed", dur), zap.Int("completed", acc.total), zap.Int("total", len(versions)), zap.Float64("rate", perS),
			zap.Int("skips", acc.skipCount), zap.Duration("eta", eta),
		)
		fmt.Printf("[%s] elapsed=%s progress=%d/%d iter=%s rate=%f/s skips=%d eta=%s\n", now.Round(time.Millisecond).Format(time.RFC3339), dur.Round(time.Millisecond), acc.total, len(versions), now.Sub(last).Round(time.Millisecond), perS, acc.skipCount, eta.Round(time.Second))
		last = now

		return acc, nil
	}, insertVersionInfoResults{
		skips: map[string][]string{},
	}).Collect()

	if err != nil {
		logger.Error("top-level error", zap.Error(err))
	}

	if len(result) != 1 {
		logger.Sugar().Panicf("expected to reduce to 1 result, got %v", result)
	}

	logger.Sugar().Infof("Inserted %d/%d versions skips=%d\n", result[0].total, len(versions), result[0].skipCount)

	f, err := os.Create("/tmp/go-gem-skips.json")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	err = json.NewEncoder(f).Encode(result[0].skips)

	if err != nil {
		panic(err)
	}
}
