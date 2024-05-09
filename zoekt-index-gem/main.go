// Copyright 2016 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime/pprof"
	"strings"

	"github.com/sourcegraph/zoekt"
	"github.com/sourcegraph/zoekt/build"
	"github.com/sourcegraph/zoekt/cmd"
	"go.uber.org/automaxprocs/maxprocs"
)

type fileInfo struct {
	name string
	size int64
}

type fileAggregator struct {
	ignoreDirs map[string]struct{}
	sizeMax    int64
	sink       chan fileInfo
}

func (a *fileAggregator) add(path string, info os.FileInfo, err error) error {
	if err != nil {
		return err
	}

	if info.IsDir() {
		base := filepath.Base(path)
		if _, ok := a.ignoreDirs[base]; ok {
			return filepath.SkipDir
		}
	}

	if info.Mode().IsRegular() {
		a.sink <- fileInfo{path, info.Size()}
	}
	return nil
}

func main() {
	cpuProfile := flag.String("cpu_profile", "", "write cpu profile to file")
	ignoreDirs := flag.String("ignore_dirs", ".git,.hg,.svn", "comma separated list of directories to ignore.")
	// gemName := flag.String("gem_name", "", "name of the gem")
	// gemVersion := flag.String("gem_version", "", "version of the gem")
	// gemPlatform := flag.String("gem_platform", "", "platform of the gem")
	// gemCreated := flag.String("gem_created", "", "date the gem was created")
	flag.Parse()

	// Tune GOMAXPROCS to match Linux container CPU quota.
	_, _ = maxprocs.Set()

	opts := cmd.OptionsFromFlags()
	if *cpuProfile != "" {
		f, err := os.Create(*cpuProfile)
		if err != nil {
			log.Fatal(err)
		}
		if err := pprof.StartCPUProfile(f); err != nil {
			log.Fatal(err)
		}
		defer pprof.StopCPUProfile()
	}

	ignoreDirMap := map[string]struct{}{}
	if *ignoreDirs != "" {
		dirs := strings.Split(*ignoreDirs, ",")
		for _, d := range dirs {
			d = strings.TrimSpace(d)
			if d != "" {
				ignoreDirMap[d] = struct{}{}
			}
		}
	}
	for _, arg := range flag.Args() {
		opts.RepositoryDescription.Source = arg
		if err := indexGemOnDisk(*opts, arg); err != nil {
			log.Fatal(err)
		}
	}

	http.DefaultServeMux.HandleFunc("/index-gem", func(w http.ResponseWriter, r *http.Request) {
		type indexReq struct {
			Name      string `json:"name"`
			Version   string `json:"version"`
			Platform  string `json:"platform"`
			FullName  string `json:"full_name"`
			Server    string `json:"server"`
			RubygemId uint32 `json:"rubygem_id"`

			Gem []byte `json:"gem"`
		}

		dec := json.NewDecoder(r.Body)
		dec.DisallowUnknownFields()
		req := indexReq{}

		if err := dec.Decode(&req); err != nil {
			http.Error(w, fmt.Sprintf("decoding request: %s", err), http.StatusBadRequest)
			return
		}

		reqOpts := *opts
		reqOpts.RepositoryDescription.Name = req.FullName
		reqOpts.CTagsMustSucceed = true
		reqOpts.RepositoryDescription.ID = req.RubygemId

		err := indexGem(reqOpts, req.Gem)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})
	panic(http.ListenAndServe(":8080", nil))
}

func indexGemOnDisk(opts build.Options, arg string) error {
	opts.RepositoryDescription.Name = filepath.Base(arg)
	contents, err := os.ReadFile(arg)
	if err != nil {
		return err
	}
	return indexGem(opts, contents)
}

func indexGem(opts build.Options, contents []byte) error {

	builder, err := build.NewBuilder(opts)
	if err != nil {
		return fmt.Errorf("NewBuilder: %w", err)
	}

	// we don't need to check error, since we either already have an error, or
	// we returning the first call to builder.Finish.
	defer builder.Finish() // nolint:errcheck

	buffer := bytes.NewBuffer(contents)

	tarReader := tar.NewReader(buffer)

	for {
		entry, err := tarReader.Next()
		if err != nil {
			if err == io.EOF {
				return builder.Finish()
			}
			return fmt.Errorf("tarReader.Next: %w", err)
		}
		// fmt.Printf("header: %v\n", entry)

		switch entry.Name {
		case "data.tar.gz":
			dataTarGzReader, err := gzip.NewReader(tarReader)
			if err != nil {
				return fmt.Errorf("gzip.NewReader: %w", err)
			}
			dataTarReader := tar.NewReader(dataTarGzReader)
			for {
				dataEntry, err := dataTarReader.Next()
				if err != nil {
					if err == io.EOF {
						break
					}
					return fmt.Errorf("dataTarReader.Next: %w", err)
				}
				if dataEntry.Size > int64(opts.SizeMax) && !opts.IgnoreSizeMax(dataEntry.Name) {
					if err := builder.Add(zoekt.Document{
						Name:       dataEntry.Name,
						SkipReason: fmt.Sprintf("document size %d larger than limit %d", dataEntry.Size, opts.SizeMax),
					}); err != nil {
						return fmt.Errorf("builder.Add: %w", err)
					}
					continue
				}
				// fmt.Printf("data entry: %v\n", dataEntry)
				fileContents, err := io.ReadAll(dataTarReader)
				if err != nil {
					return fmt.Errorf("io.ReadAll: %w", err)
				}
				if err := builder.AddFile(dataEntry.Name, fileContents); err != nil {
					return fmt.Errorf("builder.AddFile: %w", err)
				}
			}
		case "metadata.gz":
			metadataReader, err := gzip.NewReader(tarReader)
			if err != nil {
				return fmt.Errorf("gzip.NewReader: %w", err)
			}
			metadata, err := io.ReadAll(metadataReader)
			if err != nil {
				return fmt.Errorf("io.ReadAll: %w", err)
			}
			if err := builder.AddFile("metadata.gz", metadata); err != nil {
				return fmt.Errorf("builder.AddFile: %w", err)
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
			return fmt.Errorf("unexpected file in gem: %v", entry.Name)
		}
	}

}
