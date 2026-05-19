#!/usr/bin/env bash
# Manual deploy trigger for Render.
# Normally Render auto-deploys on git push to main. Use this only if auto-deploy is off.
#
# Prereqs:
#   - RENDER_API_KEY in env
#   - RENDER_SERVICE_ID in env (find in Render dashboard URL)

set -euo pipefail

: "${RENDER_API_KEY:?Set RENDER_API_KEY}"
: "${RENDER_SERVICE_ID:?Set RENDER_SERVICE_ID}"

curl -sS -X POST "https://api.render.com/v1/services/$RENDER_SERVICE_ID/deploys" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -d '{"clearCache":"do_not_clear"}' | jq .
