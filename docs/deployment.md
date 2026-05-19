# Deployment

## Pilot stack (free)

| Service | Free tier | Region |
|---|---|---|
| Render Web Service | 1 service, sleeps after 15 min idle, 750 hr/mo | Frankfurt |
| Neon PostgreSQL | 0.5 GB storage, autoscale to zero | Frankfurt (eu-central-1) |
| Cloudflare R2 | 10 GB storage, 10 M class A ops/mo, **no egress fees** | global |
| Firebase Cloud Messaging | unlimited push | global |

Total: **0 €/mo**.

## Render setup

1. Push the repo to GitHub.
2. Render Dashboard → **New → Web Service** → connect GitHub repo.
3. Settings:
   - **Root directory**: `backend`
   - **Environment**: Docker
   - **Dockerfile path**: `backend/Dockerfile`
   - **Region**: Frankfurt
   - **Branch**: `main`
4. Environment variables (copy from `.env.example`):
   - `ConnectionStrings__Default` → Neon connection string (use the pooler URL, not direct)
   - `Jwt__SigningKey` → generate with `openssl rand -base64 64`
   - `Storage__*` → Cloudflare R2 creds
   - `Fcm__*` → Firebase service account
5. Auto-deploy on push.

## Neon setup

1. Create project in Neon dashboard, region **eu-central-1 (Frankfurt)**.
2. Enable PostGIS: `CREATE EXTENSION postgis;` in the SQL editor.
3. Copy the **pooled** connection string (PgBouncer) for the API → fewer connections.
4. Create a second branch for staging / migrations review.

## Cloudflare R2 setup

1. R2 dashboard → create bucket `gasfinder-assets`.
2. Generate an API token with read+write scoped to the bucket.
3. Add a public custom domain (`assets.gasfinder.app`) for image URLs.
4. Apply a CORS policy allowing GET from the Android app origin.

## Migration to production

When traffic justifies leaving the free tier:

1. **Backend**: spin up Hetzner CX22 (€5/mo) or Oracle Cloud Always Free ARM, run the same Docker image.
2. **DB**: Neon paid tier (more storage), or self-hosted Postgres on the same VPS with `pg_dump` migration.
3. **R2**: stays — no migration needed.

No code changes required. Update `ConnectionStrings__Default` and DNS only.
