FROM golang:1.19.4-alpine as base
WORKDIR /opt/

RUN apk add git

COPY go.mod go.sum ./
RUN go mod download

COPY cmd cmd
COPY pkg pkg

# Build service in seperate stage.
FROM base as builder
WORKDIR /opt/cmd/searchd
RUN CGO_ENABLED=0 go build


# Test build.
FROM base as testing

RUN apk add build-base

CMD go vet ./... && go test -test.short ./...


# Development build.
FROM base as development

RUN ["go", "install", "github.com/githubnemo/CompileDaemon@latest"]
EXPOSE 9014

CMD CompileDaemon -log-prefix=false -build="go build" -command="./searchd"


# Productive build
FROM scratch

LABEL org.opencontainers.image.title="OpenSlides Search Service"
LABEL org.opencontainers.image.escription="The Search Service is a http endpoint where the clients can search for collections."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/OpenSlides/openslides-search-service"

COPY --from=builder /opt/cmd/searchd/searchd ./openslides-search-service
EXPOSE 9014
ENTRYPOINT ["/openslides-search-service"]
#HEALTHCHECK CMD ["/openslides-search-service", "health"]
