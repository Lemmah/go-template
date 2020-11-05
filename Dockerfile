# syntax = docker/dockerfile:1-experimental

FROM --platform=${BUILDPLATFORM} golang:1.15.3-alpine AS base

WORKDIR /src
ENV CGO_ENABLED=0
COPY go.* .
RUN go mod download

FROM base AS build
ARG TARGETOS
ARG TARGETARCH
ARG BIN_NAME=application
RUN --mount=target=. \
    --mount=type=cache,target=/root/.cache/go-build \
    GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/$BIN_NAME .

FROM base AS unit-test
RUN --mount=target=. \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -v .

FROM golangci/golangci-lint:v1.27-alpine AS lint-base

FROM base AS lint
RUN --mount=target=. \
    --mount=from=lint-base,src=/usr/bin/golangci-lint,target=/usr/bin/golangci-lint \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/.cache/golangci-lint \
    golangci-lint run --timeout 10m0s ./...

FROM scratch AS bin-unix
COPY --from=build /out/$BIN_NAME /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM scratch AS bin-windows
COPY --from=build /out/$BIN_NAME /$BIN_NAME.exe

FROM bin-${TARGETOS} AS bin