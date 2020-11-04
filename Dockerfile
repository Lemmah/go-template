FROM --platform=${BUILDPLATFORM} golang:1.14.3-alpine AS build

WORKDIR /src
COPY . .
ENV CGO_ENABLED=0
ARG TARGETOS
ARG TARGETARCH
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /out/example .

FROM scratch AS bin

COPY --from=build /out/example /