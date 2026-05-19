# API

OpenAPI spec is generated automatically from `GasFinder.Api` and served at `/swagger/v1/swagger.json` when the API runs.

## Endpoint groups (planned)

| Group | Purpose |
|---|---|
| `/api/auth` | login, register-retailer, refresh-token |
| `/api/retailers` | search nearby, get by id, retailer profile CRUD |
| `/api/brands` | list catalog |
| `/api/stock` | retailer updates stock; consumers see availability |
| `/api/sync` | delta-sync endpoints for offline-first clients |
| `/api/admin` | retailer approval, brand catalog, analytics (admin role only) |

## Conventions

- All responses gzip-compressed.
- Cache-friendly reads use `ETag` + `If-None-Match`. `304 Not Modified` returns ~100 B.
- Auth via `Authorization: Bearer <jwt>`.
- Times are ISO-8601 UTC.
- Pagination uses opaque `cursor` strings, not offset.

## Client generation

```
./scripts/generate_dart_client.sh
```

Reads `backend/src/GasFinder.Api/swagger.json`, emits a typed Dart client into `shared_flutter/lib/api_client/`.
