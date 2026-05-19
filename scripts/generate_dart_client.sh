#!/usr/bin/env bash
# Generates a typed Dart API client in shared_flutter/lib/api_client/
# from the OpenAPI spec exposed by GasFinder.Api at runtime.
#
# Prereqs:
#   - dotnet 9
#   - npx (Node 18+)
#   - The API project running OR an exported swagger.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
API_DIR="$ROOT/backend/src/GasFinder.Api"
OUT_DIR="$ROOT/shared_flutter/lib/api_client"
SWAGGER_JSON="$ROOT/backend/swagger.json"

echo "==> Exporting OpenAPI spec from $API_DIR"
pushd "$API_DIR" >/dev/null
# Generate swagger.json without running the server (requires Swashbuckle.AspNetCore.Cli)
dotnet tool restore || true
dotnet swagger tofile --output "$SWAGGER_JSON" "$(ls bin/Debug/net9.0/GasFinder.Api.dll)" v1
popd >/dev/null

echo "==> Generating Dart client into $OUT_DIR"
rm -rf "$OUT_DIR"
npx --yes @openapitools/openapi-generator-cli generate \
  -i "$SWAGGER_JSON" \
  -g dart-dio \
  -o "$OUT_DIR" \
  --additional-properties=pubName=gasfinder_api,nullableFields=true

echo "==> Done. Run \`flutter pub get\` in mobile_user and mobile_retailer."
