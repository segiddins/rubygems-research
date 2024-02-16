package main

import (
	"database/sql"
	"time"

	"github.com/jmoiron/sqlx"
)

var dumpDB *sqlx.DB = sqlx.MustConnect("postgres", "host=/var/run/postgresql/ user=postgres dbname=rubygems_production sslmode=disable")

type DumpVersion struct {
	Id          int64
	RubygemName string `db:"rubygem_name"`
	Number      string
	Platform    string
	Sha256      string         `db:"sha256"`
	SpecSha256  sql.NullString `db:"spec_sha256"`
	UploadedAt  time.Time      `db:"uploaded_at"`
	Metadata    any
}

func DumpVersions() (versions []*DumpVersion, err error) {
	err = dumpDB.Select(&versions,
		`SELECT rubygems.name AS rubygem_name, versions.number, versions.platform, versions.sha256, versions.spec_sha256, versions.created_at as uploaded_at , versions.metadata
FROM versions
	JOIN rubygems ON versions.rubygem_id = rubygems.id
WHERE versions.indexed = true
ORDER BY versions.full_name ASC
	;`,
	)
	return
}
