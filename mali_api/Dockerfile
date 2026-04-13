FROM golang:1.25-alpine

WORKDIR /app

RUN apk add --no-cache git curl bash make \
    && go install github.com/air-verse/air@latest \
    && go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest \
    && go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

ENV PATH="/go/bin:${PATH}"

COPY go.mod go.sum ./
RUN go mod download

COPY . .

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]

