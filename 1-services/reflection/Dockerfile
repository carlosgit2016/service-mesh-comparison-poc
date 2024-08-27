FROM golang:bookworm as base

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -o main

FROM scratch

ENV PORT=80
ENV HTTP_CODE=200
ENV GIND_MODE=release

COPY --from=base /app/main /main

CMD ["/main"]
