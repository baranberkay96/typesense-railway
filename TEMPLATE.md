# TEMPLATE: Typesense 30.2 Search Engine

Composer spec. `template.json` is the machine-readable copy.

## Services

| Field | Typesense | Typesense Dashboard |
|---|---|---|
| Source | repo `baranberkay96/typesense-railway`, root `/services/typesense` | same repo, root `/services/dashboard` |
| Base | `typesense/typesense:30.2@sha256:610f2d34…` (2026-04-16) | `ghcr.io/bfritscher/typesense-dashboard:2.5.0@sha256:934356f6…` (2026-07-22) |
| Public domain | yes, port 8108 | yes, port 8080 |
| Healthcheck | `/health`, 600 s | `/healthz`, 300 s |
| Restart | ALWAYS | ALWAYS |
| Volume | `/data` | - |

Typesense variables: `TYPESENSE_API_KEY` (secret 40), `PORT` 8108, `TYPESENSE_ENABLE_CORS` true, `TYPESENSE_CORS_DOMAINS` empty, `TYPESENSE_THREAD_POOL_SIZE` empty (auto), `TYPESENSE_SNAPSHOT_INTERVAL_SECONDS` 3600, `TYPESENSE_URL`, `TYPESENSE_PUBLIC_URL`, `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` 30.
Dashboard variables: `DASHBOARD_USERNAME` admin, `DASHBOARD_PASSWORD` (secret 24), `TYPESENSE_HOST`/`TYPESENSE_PORT`/`TYPESENSE_API_KEY` (references), `PORT` 8080. No required inputs.

## Design

- `railway-typesense` (sh): `TYPESENSE_API_ADDRESS=::` (dual-stack since v30), data in the volume, key < 16 chars → random key (API locked, log explains), thread pool and parallel collection load from the cgroup CPU quota (8.15; upstream uses 8 x host cores), numbers validated (Typesense's `std::stoi` would abort), `TYPESENSE_RESET_PEERS_ON_ERROR=TRUE` because the single node's IP changes on each redeploy.
- Dashboard: Caddy with `basic_auth` (bcrypt via `caddy hash-password`) on everything except `/healthz`; `/api/*` → Typesense private domain (prefix stripped, `Authorization` header dropped); `config.json` (autologin, `host: SAME`, `path: /api`) written at start, served only after login with `no-store`.

## Improvements over market templates

- Market templates pin 29.0 or nothing, put Caddy in front only for IPv6, use a fixed thread pool of 64 on any size, and one ships a hardcoded API key. Typelens exposes a dashboard with `latest` images. This template pins 30.2 and the dashboard by digest, binds dual-stack natively, sizes pools from the real CPU limit, survives IP changes, validates every variable, and keeps the dashboard and its admin key behind a login.

## Resources

| Service | Idle RAM | Typical RAM | CPU |
|---|---|---|---|
| Typesense | ≈80 MB (measured, 65-158 MB, small collection) | grows with the index (≈2-3x indexed field size) | ≈0 idle |
| Typesense Dashboard | ≈14 MB (measured) | same | ≈0 |

Estimated cost: $1-5/month for small collections + volume. Minimum plan: Trial.

## Verification checklist

- Typesense `/health` → `{"ok":true}`; `/collections` 401 without a key.
- Dashboard: `/healthz` 200, `/` 401 without login, 200 with; `/api/health` and `/api/collections` work through the proxy after login.
- Create a collection, import documents, typo search; create a search-only key and check it cannot write.
- Redeploy (new IP): data still there, node healthy.
- Short API key / short dashboard password → deploy SUCCESS, locked, warning in the log.

## Open questions

- Single node only; a 3-node Raft cluster needs stable peer addresses and is not part of this template.
