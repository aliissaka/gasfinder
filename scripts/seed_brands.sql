-- Initial brand catalog for West Africa LPG market.
-- Run after migrations; idempotent (uses ON CONFLICT).

INSERT INTO brands (id, name, logo_url, display_order, created_at, updated_at) VALUES
  (gen_random_uuid(), 'Shell',    'https://assets.gasfinder.app/brands/shell.webp',    10, now(), now()),
  (gen_random_uuid(), 'Total',    'https://assets.gasfinder.app/brands/total.webp',    20, now(), now()),
  (gen_random_uuid(), 'Oryx',     'https://assets.gasfinder.app/brands/oryx.webp',     30, now(), now()),
  (gen_random_uuid(), 'Oilibya',  'https://assets.gasfinder.app/brands/oilibya.webp',  40, now(), now()),
  (gen_random_uuid(), 'Vivo',     'https://assets.gasfinder.app/brands/vivo.webp',     50, now(), now()),
  (gen_random_uuid(), 'Puma',     'https://assets.gasfinder.app/brands/puma.webp',     60, now(), now())
ON CONFLICT (name) DO NOTHING;
