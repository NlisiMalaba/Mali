# Mali Monorepo

This repository contains the Mali personal finance platform codebase.

## Structure

- `mali_api/` - Go backend API
- `mali_app/` - Flutter mobile application

## Docker Backend Workflow

Run these commands from the repository root:

- Start API + infra: `docker compose up -d` (API on http://localhost:8082)
- Or via Make: `make -C mali_api dev`
- Run tests: `make -C mali_api test`
- Run migrations: `make -C mali_api migrate-up`

## Flutter mobile app

See [mali_app/README.md](mali_app/README.md) for `flutter run` commands (Android emulator, physical device, API URL).

