#!/bin/sh
set -e

# Ensure bun globals are in PATH
export PATH="/root/.bun/bin:$PATH"

echo "[gbrain] version: $(gbrain --version)"

PORT="${PORT:-8080}"
PUBLIC_URL="${GBRAIN_PUBLIC_URL:-}"

if [ -z "$DATABASE_URL" ]; then
  echo "[gbrain] ERROR: DATABASE_URL not set"
  exit 1
fi

echo "[gbrain] Initialising brain on Postgres..."
gbrain init --url "$DATABASE_URL" --embedding-model voyage:voyage-3-large 2>&1

echo "[gbrain] Configuring API keys..."
gbrain config set anthropic_api_key "$ANTHROPIC_API_KEY" 2>&1 || true

echo "[gbrain] Starting HTTP MCP server on port $PORT..."
if [ -n "$PUBLIC_URL" ]; then
  exec gbrain serve --http --port "$PORT" --bind 0.0.0.0 --public-url "$PUBLIC_URL"
else
  exec gbrain serve --http --port "$PORT" --bind 0.0.0.0
fi
