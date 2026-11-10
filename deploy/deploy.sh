#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.production.example to .env and set secrets first."
  exit 1
fi

docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml ps

if [[ -f deploy/nginx-mali-api.conf ]]; then
  cp deploy/nginx-mali-api.conf /etc/nginx/sites-available/mali-api
  ln -sf /etc/nginx/sites-available/mali-api /etc/nginx/sites-enabled/mali-api
  nginx -t
  systemctl reload nginx
fi

echo "Waiting for health on host :8085 ..."
for i in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:8085/health" >/dev/null 2>&1; then
    echo "OK: http://127.0.0.1:8085/health"
    echo "If HTTPS is not ready yet, run: certbot --nginx -d mali-api.nlisimalaba.co.zw"
    exit 0
  fi
  sleep 2
done

echo "Health check did not succeed yet; check: docker compose -f docker-compose.prod.yml logs"
exit 1
