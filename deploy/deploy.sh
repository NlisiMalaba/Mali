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
echo "Waiting for health..."
for i in $(seq 1 30); do
  if curl -fsS "https://mali-api.nlisimalaba.co.zw/health" >/dev/null 2>&1; then
    echo "OK: https://mali-api.nlisimalaba.co.zw/health"
    exit 0
  fi
  sleep 2
done

echo "Health check did not succeed yet; check: docker compose -f docker-compose.prod.yml logs"
exit 1
