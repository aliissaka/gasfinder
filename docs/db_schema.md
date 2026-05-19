# Database schema

PostgreSQL 16 + PostGIS (Neon free tier).

## Tables (initial)

### users
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| phone | text | unique, E.164 |
| pin_hash | text | Argon2id |
| role | text | `consumer` \| `retailer` \| `admin` |
| display_name | text | nullable |
| created_at | timestamptz | |
| updated_at | timestamptz | bumped on every change — used for sync cursor |

### retailers
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK to users (owner account) |
| shop_name | text | |
| location | geography(Point, 4326) | PostGIS — for `ST_DWithin` queries |
| address | text | nullable |
| phone | text | public-facing |
| photo_url | text | shop front photo (R2) |
| opening_hours | jsonb | per-weekday open/close |
| status | text | `pending` \| `approved` \| `suspended` |
| created_at | timestamptz | |
| updated_at | timestamptz | sync cursor |

### brands
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| name | text | `Shell`, `Total`, `Oryx`, ... |
| logo_url | text | WebP in R2 |
| display_order | int | for UI sort |
| created_at | timestamptz | |
| updated_at | timestamptz | sync cursor |

### stock_items
Current stock per retailer per brand.

| Column | Type | Notes |
|---|---|---|
| retailer_id | uuid | FK |
| brand_id | uuid | FK |
| status | text | `available` \| `low` \| `out` |
| quantity | int | nullable |
| last_updated_at | timestamptz | sync cursor |

Primary key: `(retailer_id, brand_id)`.

### stock_updates
Append-only audit log for fraud detection and analytics.

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| retailer_id | uuid | FK |
| brand_id | uuid | FK |
| status | text | snapshot |
| quantity | int | snapshot |
| reported_at | timestamptz | client-supplied wall clock |
| received_at | timestamptz | server time |
| client_outbox_id | uuid | idempotency key from client |

Unique index on `(retailer_id, client_outbox_id)` → idempotent retries from offline outbox.

## Indices

- `retailers USING GIST(location)` — geo lookups
- `users(phone)` — login
- `retailers(updated_at)` — sync cursor
- `stock_items(retailer_id)`, `stock_items(last_updated_at)`
- `stock_updates(received_at)`, `stock_updates(retailer_id, client_outbox_id) UNIQUE`
