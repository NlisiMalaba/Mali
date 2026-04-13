.PHONY: dev test migrate-up migrate-down build docker-build sqlc-gen

APP_ENTRYPOINT ?= ./cmd/api
BINARY_NAME ?= mali_api
MIGRATIONS_DIR ?= ./db/migrations
COMPOSE ?= docker compose

dev:
	$(COMPOSE) up api

test:
	$(COMPOSE) run --rm api go test ./...

migrate-up:
	$(COMPOSE) up -d postgres redis
	$(COMPOSE) run --rm api migrate -path "$(MIGRATIONS_DIR)" -database "$$DATABASE_URL" up

migrate-down:
	$(COMPOSE) up -d postgres redis
	$(COMPOSE) run --rm api migrate -path "$(MIGRATIONS_DIR)" -database "$$DATABASE_URL" down 1

build:
	$(COMPOSE) run --rm api sh -c "mkdir -p bin && go build -o bin/$(BINARY_NAME) $(APP_ENTRYPOINT)"

docker-build:
	$(COMPOSE) build api

sqlc-gen:
	$(COMPOSE) run --rm api sqlc generate

