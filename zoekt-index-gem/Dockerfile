# syntax=docker/dockerfile:1

# Build the application from source
FROM golang:1.22 AS build-stage

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o /zoekt-index-gem

# Run the tests in the container
FROM build-stage AS run-test-stage
RUN go test -v ./...

FROM debian:11 AS ctags-build-stage

RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
  --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
  apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  gcc make \
  pkg-config autoconf automake \
  python3-docutils \
  libseccomp-dev \
  libjansson-dev \
  libyaml-dev \
  libxml2-dev

WORKDIR /build

ADD https://github.com/universal-ctags/ctags.git#v6.1.0 /build/ctags

WORKDIR /build/ctags

RUN ./autogen.sh && \
  LDFLAGS=-static ./configure --enable-json --enable-seccomp --program-prefix=universal- --prefix=/out && \
  make -j4 && make install

# Deploy the application binary into a lean image
FROM gcr.io/distroless/base-debian11 AS build-release-stage

WORKDIR /

COPY --from=build-stage /zoekt-index-gem /zoekt-index-gem
COPY --from=ctags-build-stage /out/bin/* /usr/local/bin/
COPY --from=ctags-build-stage /out/share/* /usr/local/share/

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/zoekt-index-gem"]
