package common

import (
	"net/http"
	"os"
	"path/filepath"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	httptrace "gopkg.in/DataDog/dd-trace-go.v1/contrib/net/http"
	"gopkg.in/natefinch/lumberjack.v2"
)

type Server struct {
	Id  int64  `db:"id"`
	Url string `db:"url"`
}

var Logger *zap.Logger

var transport http.RoundTripper = &http.Transport{
	MaxIdleConns:       50,
	IdleConnTimeout:    5 * time.Second,
	MaxConnsPerHost:    50,
	DisableCompression: true,
}
var Client *http.Client = httptrace.WrapClient(&http.Client{
	Transport: transport,
})

func init() {
	w := zapcore.AddSync(&lumberjack.Logger{
		Filename:   "/var/log/go-gem-enumerate/" + filepath.Base(os.Args[0]) + ".log",
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

	Logger = zap.New(zapcore.NewTee(filecore, stdoutcore))
}
