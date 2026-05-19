#!/usr/bin/env bash
# Applies pending EF Core migrations to the database in $ConnectionStrings__Default.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT/backend"
dotnet tool restore
dotnet ef database update \
  --project src/GasFinder.Infrastructure \
  --startup-project src/GasFinder.Api
