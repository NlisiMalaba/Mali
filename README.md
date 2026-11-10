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

## Production deploy (VPS + Cloudflare)

Public API URL: `https://mali-api.nlisimalaba.co.zw`

### Cloudflare DNS

1. In Cloudflare → DNS for `nlisimalaba.co.zw`, create an **A** record:
   - Name: `mali-api`
   - IPv4: your VPS public IP
   - Proxy status: **DNS only** (grey cloud) so Caddy can obtain a Let's Encrypt certificate
2. On the VPS firewall, allow inbound **TCP 80** and **TCP 443**.

### Server (Docker Compose + existing nginx)

This VPS already uses **nginx** on ports 80/443, so prod compose does **not** run Caddy. The API is published on host **8085**, and nginx terminates TLS.

From the repository root on the VPS:

```bash
cp .env.production.example .env
# Edit .env: set strong POSTGRES_PASSWORD, JWT_SECRET, JWT_REFRESH_SECRET, and matching DATABASE_URL
docker compose -f docker-compose.prod.yml up -d --build

sudo cp deploy/nginx-mali-api.conf /etc/nginx/sites-available/mali-api
sudo ln -sf /etc/nginx/sites-available/mali-api /etc/nginx/sites-enabled/mali-api
sudo nginx -t && sudo systemctl reload nginx

# TLS (certbot must already be set up for nginx on this host)
sudo certbot --nginx -d mali-api.nlisimalaba.co.zw

curl -fsS https://mali-api.nlisimalaba.co.zw/health
```

Migrations run automatically via the one-shot `migrate` service before `api` starts.

### Release APK

Default API URL is already `https://mali-api.nlisimalaba.co.zw` in `mali_app/lib/core/config/api_config.dart`.

```powershell
cd mali_app
flutter build apk --release
```

APK path: `mali_app/build/app/outputs/flutter-apk/app-release.apk`

## Flutter mobile app

See [mali_app/README.md](mali_app/README.md) for `flutter run` commands (Android emulator, physical device, API URL).

