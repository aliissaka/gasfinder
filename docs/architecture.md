# Architecture

## High-level

```
End-user Flutter app  ──┐
                        │   HTTPS (JWT, gzip, ETag)
Retailer Flutter app  ──┼──▶  ASP.NET Core API  ──▶  PostgreSQL (Neon, Frankfurt)
                        │            │
Admin Blazor          ──┘            ├──▶  Cloudflare R2 (logos, photos)
                                     └──▶  Firebase Cloud Messaging (data push)
```

## Layers (backend)

- **GasFinder.Api** — HTTP entry point. Controllers, middleware, DI wiring, `Program.cs`.
- **GasFinder.Domain** — Pure C#: entities, value objects, enums. No framework dependencies.
- **GasFinder.Infrastructure** — EF Core, PostgreSQL adapter (Npgsql), Cloudflare R2 client, JWT, FCM.
- **GasFinder.Shared** — DTOs used by both API and Admin Blazor. Source of truth for OpenAPI generation.

## Offline-first sync

- Retailer app writes stock changes to a local outbox (Isar). `workmanager` flushes when network returns.
- End-user app downloads a regional snapshot once, then delta-syncs via `GET /api/sync/retailers?since={cursor}&bbox={lat1,lon1,lat2,lon2}`.
- Backend issues opaque cursors; the server is the source of truth for ordering.

See [sync_protocol.md](sync_protocol.md) for details.

## Auth

Phone number + 4-digit PIN. PIN is Argon2-hashed server-side. JWT issued on login, refresh token stored in Isar.
