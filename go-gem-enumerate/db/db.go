package db

import (
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
	"github.com/segiddins/go-gem-enumerate/common"
	"go.uber.org/zap"
	sqlxtrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/jmoiron/sqlx"
)

var DB *sqlx.DB
var Server *common.Server

func init() {
	DB = sqlxtrace.MustConnect("sqlite3", "/root/Development/github.com/segiddins/rubygems-research/db/development/data.sqlite3")

	row := DB.QueryRowx("SELECT id, url FROM servers WHERE url = ?", "https://rubygems.org")
	Server = &common.Server{}
	err := row.StructScan(Server)
	if err != nil {
		common.Logger.Panic("failed to find server", zap.Error(err))
	}
}
