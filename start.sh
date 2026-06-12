#!/bin/sh
set -e

# Ensure bun globals are in PATH
export PATH="/root/.bun/bin:$PATH"

echo "[gbrain-render] gbrain version: $(gbrain --version)"

PORT="${PORT:-3000}"
PUBLIC_URL="${GBRAIN_PUBLIC_URL:-}"

if [ -z "$DATABASE_URL" ]; then
  echo "[gbrain-render] ERROR: DATABASE_URL not set"
  exit 1
fi

echo "[gbrain-render] Initialising brain on Postgres (idempotent)..."

# Write config.json before init so gbrain picks up API keys from env
mkdir -p /root/.gbrain
cat > /root/.gbrain/config.json << ENDJSON
{
  "engine": "postgres",
  "database_url": "$DATABASE_URL",
  "anthropic_api_key": "$ANTHROPIC_API_KEY",
  "voyage_api_key": "$VOYAGE_API_KEY"
}
ENDJSON

# Init / migrate schema against Supabase (idempotent)
gbrain init --postgres "$DATABASE_URL" --embedding-model voyage:voyage-3-large 2>&1 || \
gbrain apply-migrations --yes --non-interactive 2>&1 || true

echo "[gbrain-render] Brain ready — starting HTTP MCP server..."

if [ -n "$PUBLIC_URL" ]; then
  exec gbrain serve --http --port "$PORT" --bind 0.0.0.0 --public-url "$PUBLIC_URL"
else
  exec gbrain serve --http --port "$PORT" --bind 0.0.0.0
fi
