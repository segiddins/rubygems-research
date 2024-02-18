package main

import (
	"bufio"
	"bytes"
	"context"
	"crypto/md5"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/klauspost/compress/gzip"
	"github.com/segiddins/go-gem-enumerate/common"
	"github.com/segiddins/go-gem-enumerate/db"
	"go.uber.org/zap"
	"golang.org/x/sync/semaphore"
)

type compactIndexEntry struct {
	Path         string
	Contents     []byte
	Etag         string
	LastModified time.Time `db:"last_modified"`
	Sha256       string    `db:"sha256"`
	changed      bool
}

func (e *compactIndexEntry) Decompressed() ([]byte, error) {
	buf := bytes.NewBuffer(e.Contents)
	reader, err := gzip.NewReader(buf)
	if err != nil {
		return nil, err
	}
	return io.ReadAll(reader)
}

func compactIndexRequest(ctx context.Context, serverID int64, path string, expectedMd5 string) (*compactIndexEntry, error) {
	row := db.DB.QueryRowx("select path, contents, etag, last_modified, sha256 from compact_index_entries where path = ? and server_id = ?", path, serverID)
	var entry compactIndexEntry
	if err := row.StructScan(&entry); err != nil && err != sql.ErrNoRows {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://index.rubygems.org/"+path, nil)
	if err != nil {
		return nil, err
	}

	var pre []byte
	if len(entry.Etag) > 0 {
		pre, err = entry.Decompressed()
		if err != nil {
			return nil, fmt.Errorf("failed to decompress %s: %w", entry.Path, err)
		}

		if expectedMd5 != "" {
			sum := md5.Sum(pre)
			if hex.EncodeToString(sum[:]) == expectedMd5 {
				common.Logger.Debug("info checksums match", zap.String("path", path))
				entry.changed = false
				return &entry, nil
			}
		}

		pre = pre[:len(pre)-1]
		req.Header.Add("Range", fmt.Sprintf("bytes=%d-", len(pre)))
		req.Header.Add("Etag", entry.Etag)
	}

	resp, err := common.Client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var reader io.Reader

	switch resp.StatusCode {
	case http.StatusOK:
		reader = resp.Body
	case http.StatusPartialContent:
		reader = io.MultiReader(bytes.NewReader(pre), resp.Body)
	case http.StatusRequestedRangeNotSatisfiable:
		req.Header.Del("Range")
		resp.Body.Close()

		resp, err := common.Client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("expected OK for %s, got %s", resp.Request.URL.String(), resp.Status)
		}
		reader = resp.Body

	default:
		return nil, fmt.Errorf("unexpected status %s for %s", resp.Status, resp.Request.URL.String())
	}

	hash := sha256.New()
	reader = io.TeeReader(reader, hash)

	buf := new(bytes.Buffer)
	writer := gzip.NewWriter(buf)
	entry.Etag = resp.Header.Get("Etag")
	entry.Sha256 = resp.Header.Get("Digest")
	entry.Path = path
	entry.LastModified, err = http.ParseTime(resp.Header.Get("last-modified"))
	if err != nil {
		return nil, err
	}
	_, err = io.Copy(writer, reader)
	if err != nil {
		return nil, err
	}
	err = writer.Close()
	if err != nil {
		return nil, err
	}
	entry.Contents = buf.Bytes()
	entry.changed = true

	read := "sha-256=\"" + base64.StdEncoding.EncodeToString(hash.Sum(nil)) + "\""
	if !strings.Contains(entry.Sha256, "\"") {
		read = strings.ReplaceAll(read, "\"", "")
	}
	if read != entry.Sha256 {
		return nil, fmt.Errorf("sha256 does not match: found %s, expected %s", read, entry.Sha256)
	}

	return &entry, nil
}

func storeCompactIndexEntry(ctx context.Context, serverID int64, entry *compactIndexEntry) (bool, error) {
	result, err := db.DB.ExecContext(ctx, `insert into compact_index_entries (server_id, path, contents, etag, last_modified, sha256, created_at, updated_at) 
	values (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
	on conflict(path, server_id) do update
		set contents = excluded.contents, etag = excluded.etag, last_modified=excluded.last_modified, sha256=excluded.sha256, updated_at = excluded.updated_at
		where etag != excluded.etag or sha256 != excluded.sha256 or contents != excluded.contents
	`,
		serverID, entry.Path, entry.Contents, entry.Etag, entry.LastModified, entry.Sha256,
	)
	if err != nil {
		return false, fmt.Errorf("failed to insert: %w", err)
	}

	updated, err := result.RowsAffected()
	if err != nil {
		return false, fmt.Errorf("failed to get rows affected: %w", err)
	}

	return updated == 1, nil
}

func main() {
	ctx := context.Background()

	entry, err := compactIndexRequest(ctx, db.Server.Id, "versions", "")
	if err != nil {
		common.Logger.Panic("versions", zap.Error(err))
	}
	versions := entry

	newVersions, err := storeCompactIndexEntry(ctx, db.Server.Id, entry)
	if err != nil {
		common.Logger.Panic("versions", zap.Error(err))
	}

	if !newVersions && false {
		return
	}

	entry, err = compactIndexRequest(ctx, db.Server.Id, "names", "")
	if err != nil {
		common.Logger.Panic("name", zap.Error(err))
	}

	_, err = storeCompactIndexEntry(ctx, db.Server.Id, entry)
	if err != nil {
		common.Logger.Panic("name", zap.Error(err))
	}

	s, err := versions.Decompressed()
	infoChecksums := map[string]string{}
	if err != nil {
		common.Logger.Panic("failed to read versions content", zap.Error(err))
	}
	scanner := bufio.NewScanner(bytes.NewBuffer(s))
	scanner.Buffer(make([]byte, 0, 1024*1024), 1024*1024)

	concurrency := int64(200)
	sema := semaphore.NewWeighted(concurrency)
	var count, errCount, updatedCount atomic.Int64
	seenDelim := false

	for scanner.Scan() {
		line := scanner.Text()
		if line == "---" {
			seenDelim = true
			continue
		}
		if !seenDelim {
			continue
		}
		// line = strings.TrimPrefix(line, "-") // yank

		parts := strings.Split(line, " ")
		name, infoChecksum := parts[0], parts[len(parts)-1]
		infoChecksums[name] = infoChecksum
	}
	if scanner.Err() != nil {
		common.Logger.Panic("failed to scan lines", zap.Error(scanner.Err()))
	}
	common.Logger.Info("found versions", zap.Int("count", len(infoChecksums)))

	m := sync.Mutex{}

	for name, cs := range infoChecksums {
		if err := sema.Acquire(ctx, 1); err != nil {
			common.Logger.Panic("err", zap.Error(err))
		}

		path := "info/" + name
		cs := cs

		go func() {
			defer sema.Release(1)
			defer func() {
				v := count.Add(1)
				if v%20000 == 0 {
					common.Logger.Info("download progress", zap.Int64("count", count.Load()), zap.Int64("errors", errCount.Load()), zap.Int64("updated", updatedCount.Load()))
				}
			}()
			entry, err := compactIndexRequest(ctx, db.Server.Id, path, cs)
			if err != nil {
				errCount.Add(1)
				common.Logger.Error("info get error", zap.Error(err), zap.String("path", path))
				return
			}
			if !entry.changed {
				return
			}

			m.Lock()
			defer m.Unlock()

			updated, err := storeCompactIndexEntry(ctx, db.Server.Id, entry)
			if err != nil {
				common.Logger.Panic("info store error", zap.Error(err), zap.String("path", path))
			}
			if updated {
				updatedCount.Add(1)
			} else {
				common.Logger.Warn("didn't update", zap.String("path", path))
			}
		}()
	}
	if err := sema.Acquire(ctx, concurrency); err != nil {
		common.Logger.Panic("err", zap.Error(err))
	}
	common.Logger.Info("download finished", zap.Int64("count", count.Load()), zap.Int64("errors", errCount.Load()), zap.Int64("updated", updatedCount.Load()))
}
