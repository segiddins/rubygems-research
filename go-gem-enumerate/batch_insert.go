package main

import (
	"github.com/jmoiron/sqlx"
)

type BatchInsertable interface {
	TableName() string
	PrimaryKeys() string
}

func BatchInsert[T any](insertQuery string, myStructs []*T, params int, tx *sqlx.Tx) (rows []*T, err error) {
	maxBulkInsert := ((1 << 15) / params) - 2

	// send batch requests
	for i := 0; i < len(myStructs); i += maxBulkInsert {
		var r *sqlx.Rows
		batch := myStructs[i:min(i+maxBulkInsert, len(myStructs))]
		r, err = tx.NamedQuery(insertQuery, batch)
		if err != nil {
			return
		}
		defer r.Close()
		for r.Next() {
			row := new(T)
			err = r.StructScan(row)
			if err != nil {
				return
			}
			rows = append(rows, row)
		}
		err = r.Err()
		if err != nil {
			return
		}
	}

	return
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
