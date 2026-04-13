# Mali Monorepo

This repository contains the Mali personal finance platform codebase.

## Structure

- `mali_api/` - Go backend API
- `mali_app/` - Flutter mobile application

## Docker Backend Workflow

Run these commands from the repository root:

- Start API + infra: `make -C mali_api dev`
- Run tests: `make -C mali_api test`
- Run migrations: `make -C mali_api migrate-up`

