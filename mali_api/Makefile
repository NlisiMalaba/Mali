.PHONY: dev test migrate-up migrate-down build docker-build

APP_ENTRYPOINT ?= ./cmd/api
BINARY_NAME ?= mali_api
MIGRATIONS_DIR ?= ./db/migrations
DOCKER_IMAGE ?= mali_api:latest
DATABASE_URL ?= postgres://postgres:postgres@localhost:5432/mali?sslmode=disable

dev:
	air

test:
	go test ./...

migrate-up:
	migrate -path "$(MIGRATIONS_DIR)" -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path "$(MIGRATIONS_DIR)" -database "$(DATABASE_URL)" down 1

build:
	go build -o bin/$(BINARY_NAME) "$(APP_ENTRYPOINT)"

docker-build:
	docker build -t "$(DOCKER_IMAGE)" .

