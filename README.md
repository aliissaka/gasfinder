# Gas Finder

Mobile app for finding liquefied petroleum gas (LPG) retailers and checking domestic gas brand availability in West Africa.

## Audience

- **End users**: consumers looking for a gas retailer near them. UI designed for illiterate users (icons, brand logos, voice prompts in French).
- **Retailers**: shop owners updating their stock status.
- **Admin**: project owner, manages retailer approvals and brand catalog.

## Stack

| Layer | Tech |
|---|---|
| Backend | ASP.NET Core 8 Web API (C#), EF Core, PostgreSQL + PostGIS |
| End-user app | Flutter (Android) |
| Retailer app | Flutter (Android) |
| Admin | Blazor Server |
| Shared mobile | `shared_flutter/` Dart package (API client + design system) |
| Storage | Cloudflare R2 (images) |
| Push | Firebase Cloud Messaging (data-only) |

## Hosting (pilot, free)

- API: Render free web service (Frankfurt)
- DB: Neon free PostgreSQL (Frankfurt)
- Images: Cloudflare R2 free 10 GB

Migration path: Hetzner VPS or Oracle Cloud Always Free when paid traffic justifies it.

## Repo layout

```
gas-finder/
├── backend/          ASP.NET Core API + Domain + Infrastructure + Shared
├── mobile_user/      Flutter end-user app
├── mobile_retailer/  Flutter retailer app
├── shared_flutter/   Dart package shared by both Flutter apps
├── admin/            Blazor Server admin panel
├── docs/             Architecture, API, schema, UX, deployment docs
└── scripts/          Build, seed, codegen helpers
```

## Local development

Run the local Postgres + MinIO (R2 emulator) stack:

```bash
docker compose up -d
```

Backend:

```bash
cd backend
dotnet run --project src/GasFinder.Api
```

Flutter apps:

```bash
cd mobile_user   # or mobile_retailer
flutter run
```

## Status

Pilot phase. See `docs/` for design decisions.
