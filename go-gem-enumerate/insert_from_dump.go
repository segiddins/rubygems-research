package main

import (
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"log"
)

type Server struct {
	Id  int64  `db:"id"`
	Url string `db:"url"`
}

type Rubygem struct {
	Id       int64  `db:"id"`
	ServerId int64  `db:"server_id"`
	Name     string `db:"name"`
}

func EachSlice[T any](slice []T, size int, f func([]T) error) error {
	for i := 0; i < len(slice); i += size {
		if err := f(slice[i:min(i+size, len(slice))]); err != nil {
			return err
		}
	}
	return nil
}

func base64ToHex(b64 string) (string, error) {
	b, err := base64.StdEncoding.DecodeString(b64)
	if err != nil {
		return "", err
	}
	h := hex.EncodeToString(b)
	return h, nil
}

func InsertRubygemsAndVersionsFromDump() (versions []*Version, err error) {
	var dumpedVersions []*DumpVersion
	dumpedVersions, err = DumpVersions()
	if err != nil {
		err = fmt.Errorf("failed to dump versions: %w", err)
		return
	}

	log.Println("Dumped versions:", len(dumpedVersions))

	tx := db.MustBegin()
	defer tx.Rollback()

	row := tx.QueryRowx("SELECT id, url FROM servers WHERE url = ?", "https://rubygems.org")
	if err = row.Err(); err != nil {
		return
	}
	var server Server
	err = row.StructScan(&server)
	if err != nil {
		return
	}

	log.Printf("Server: %v\n", server)

	rubygems := []*Rubygem{}
	versions = make([]*Version, 0, len(dumpedVersions))
	names := make(map[string]bool)
	for _, v := range dumpedVersions {
		if _, ok := names[v.RubygemName]; !ok {
			names[v.RubygemName] = true
			rubygems = append(rubygems, &Rubygem{Name: v.RubygemName, ServerId: server.Id})
		}
	}

	err = EachSlice(rubygems, (1<<15)/2-2, func(slice []*Rubygem) error {
		_, err := tx.NamedExec("INSERT INTO rubygems (name, server_id, created_at, updated_at) VALUES (:name, :server_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING", slice)
		if err != nil {
			return err
		}

		return nil
	})

	err = tx.Select(&rubygems, "SELECT id, name, server_id FROM rubygems WHERE server_id = ?", server.Id)
	if err != nil {
		return
	}
	log.Println("Inserted rubygems:", len(rubygems))
	rubygemIds := make(map[string]int64)
	for _, r := range rubygems {
		rubygemIds[r.Name] = r.Id
	}

	for _, v := range dumpedVersions {
		rubygemId, ok := rubygemIds[v.RubygemName]
		if !ok {
			log.Printf("Rubygem not found: %v\n", v.RubygemName)
			continue
		}
		var sha256, spec_sha256 string
		sha256, err = base64ToHex(v.Sha256)
		if err != nil {
			return
		}
		if v.SpecSha256.Valid {
			spec_sha256, err = base64ToHex(v.SpecSha256.String)
			if err != nil {
				return
			}
		}

		versions = append(versions, &Version{
			RubygemId:   rubygemId,
			RubygemName: v.RubygemName,
			Number:      v.Number,
			Platform:    v.Platform,
			Sha256:      sql.NullString{String: sha256, Valid: true},
			SpecSha256:  sql.NullString{String: spec_sha256, Valid: true},
			UploadedAt:  sql.NullTime{Time: v.UploadedAt, Valid: true},
			Indexed:     v.Indexed,
			// Metadata:    v.Metadata,
		})
	}

	err = EachSlice(versions, (1<<15)/7-2, func(slice []*Version) error {
		_, err := tx.NamedExec(
			`INSERT INTO versions (rubygem_id, number, platform, sha256, spec_sha256, uploaded_at, indexed, created_at, updated_at)
			VALUES (:rubygem_id, :number, :platform, :sha256, :spec_sha256, :uploaded_at, :indexed, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
			ON CONFLICT do update set indexed = excluded.indexed, updated_at = excluded.updated_at where indexed != excluded.indexed`, slice)
		if err != nil {
			return fmt.Errorf("error inserting versions from dump: %w", err)
		}

		return nil
	})

	err = tx.Select(&versions,
		`SELECT versions.id, rubygem_id, number, platform, sha256, spec_sha256, uploaded_at, rubygems.name, indexed
		FROM versions JOIN rubygems ON versions.rubygem_id = rubygems.id 
		WHERE rubygems.server_id = ?`, server.Id)
	if err != nil {
		err = fmt.Errorf("error selecting from versions: %w", err)
		return
	}

	log.Println("Inserted versions:", len(versions))

	err = tx.Commit()

	return
}
