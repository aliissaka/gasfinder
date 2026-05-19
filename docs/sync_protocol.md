# Sync protocol

## Goals

- Work on intermittent / very slow networks.
- Minimise data transfer: only send what changed since the client's last successful sync.
- Idempotent: retrying after a partial failure produces the same final state.
- Bandwidth-friendly: gzip + ETag → "no changes" round-trip is ~100 B.

## Cursor

The server issues an opaque cursor per resource. Clients store it and pass it back next sync.

```
GET /api/sync/retailers?cursor=<opaque>&bbox=14.6,-17.5,14.8,-17.4
```

Response:

```json
{
  "cursor": "<new-opaque-cursor>",
  "changes": [
    { "id": "...", "shop_name": "...", "lat": 14.71, "lon": -17.46, "updated_at": "2026-05-19T10:23:00Z" }
  ],
  "deletes": ["uuid-of-deleted-retailer", "..."]
}
```

If nothing has changed: HTTP `304 Not Modified` (with `If-None-Match: <etag>`).

## Outbox (retailer app)

Every stock change is written to a local Isar collection `outbox`:

```
{
  id: uuid (client-generated, idempotency key),
  endpoint: "/api/stock",
  body: { ... },
  attempt_count: 0,
  created_at: ...
}
```

`workmanager` flushes the queue when connectivity returns:

1. POST batched outbox items.
2. Server deduplicates by `client_outbox_id` (unique index on `stock_updates`).
3. On 2xx, client deletes the outbox row.
4. On 5xx, increment `attempt_count`, retry with exponential backoff.
5. On 4xx, mark as `failed` and surface to user (rare — usually a code bug).

## Stale-data badge

Each cached retailer record shows `last_synced_at`. UI shows "Updated X ago" with colour:

- < 1 h: green
- 1–6 h: yellow
- > 6 h: red (encourage user to refresh when network returns)
