# Deploy and Host Typesense with Railway

Typesense is an open-source, typo-tolerant search engine with a simple REST API: instant full-text search, filters, facets, geo search, vector and hybrid search, and conversational (RAG) search. This template runs the official Typesense server on a Railway volume with a generated admin key, plus a password-protected web dashboard.

## About Hosting Typesense

Typesense keeps its indexes in memory and persists data on disk, so hosting it needs a persistent volume, an admin API key, enough RAM for your data and a stable restart path. This community template builds the official `typesense/typesense` image (pinned by digest) with a start script that listens dual-stack, sizes thread pools from the service's CPU limit instead of the host's 96 cores, lets the single-node Raft state survive the new IP of every redeploy, and never fails a deploy on a bad variable. A second service serves the open-source Typesense Dashboard behind a Caddy login and proxies its API calls to Typesense over the private network.

## Common Use Cases

- Instant search for websites, docs and product catalogs (InstantSearch adapter, JS/Python/PHP/Go clients)
- Search backend for your app or CMS over Railway's private network
- Semantic and hybrid search with built-in or OpenAI embeddings
- A self-hosted, cost-predictable alternative to Algolia

## Dependencies for Typesense Hosting

- Typesense server (official image) with a Railway volume at `/data`
- Typesense Dashboard (static web app, served by Caddy with a login)

### Deployment Dependencies

- [Typesense documentation](https://typesense.org/docs/)
- [Server configuration](https://typesense.org/docs/latest/api/server-configuration.html)
- [API keys](https://typesense.org/docs/latest/api/api-keys.html)
- [Typesense Dashboard](https://github.com/bfritscher/typesense-dashboard)

### Implementation Details

| Service | What runs inside | Volume | Port |
|---|---|---|---|
| Typesense | Typesense 30.2 | `/data` | 8108, public domain (API) |
| Typesense Dashboard | Typesense Dashboard 2.5.0 + Caddy login | - | 8080, public domain |

**First login**

1. Open the **Typesense Dashboard** service's domain and log in with `DASHBOARD_USERNAME` (default `admin`) and `DASHBOARD_PASSWORD` (generated, see its Variables tab).
2. The dashboard connects automatically: it talks to Typesense through `/api` on its own domain, so the admin key never leaves the login-protected page.
3. Create a collection, import documents (JSON/JSONL) and try searches in the dashboard.

**Using the API**

- Health: `https://{typesense-domain}/health`
- Admin requests send the header `X-TYPESENSE-API-KEY: {TYPESENSE_API_KEY}`. Keep this key on your backend.
- For browsers, create a search-only key: `POST /keys` with `{"description":"search","actions":["documents:search"],"collections":["*"]}` and the admin key, then use the returned key in your frontend.
- Other Railway services connect privately with `${{Typesense.TYPESENSE_URL}}` (for example `http://typesense.railway.internal:8108`).

**Variables**

| Variable | Default | Purpose |
|---|---|---|
| `TYPESENSE_API_KEY` | generated, 40 chars | Admin key; at least 16 characters |
| `TYPESENSE_ENABLE_CORS` / `TYPESENSE_CORS_DOMAINS` | `true` / all | Browser access from your sites |
| `TYPESENSE_THREAD_POOL_SIZE` | 8 per CPU (16-128) | Concurrent request threads |
| `TYPESENSE_SNAPSHOT_INTERVAL_SECONDS` | `3600` | Raft snapshot interval |
| `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` | `admin` / generated | Dashboard login |

Other [server options](https://typesense.org/docs/latest/api/server-configuration.html) can be added as `TYPESENSE_*` variables. A key shorter than 16 characters (or a dashboard password outside 12-72 characters) locks the API or login with a random secret and the log explains the fix; invalid numbers fall back to defaults instead of crashing.

**Backups**

Create a snapshot with `POST /operations/snapshot?snapshot_path=/data/backups/{name}` (admin key). Snapshots count toward the volume size; copy them off the volume for real backups.

**Scaling and upgrades**

Typesense holds the searchable index in RAM: plan roughly 2-3x the size of the indexed fields, and raise the service's memory as data grows. This template is a single node (Raft cluster of one); the server can be clustered with three nodes, which needs `TYPESENSE_NODES` and a peering setup not covered here. To upgrade, Eject the repo, change the tag and digest in `services/typesense/Dockerfile` after reading the release notes, take a snapshot, and redeploy.

**Resources**

Measured on Railway idle: Typesense about 80 MB with a small collection, the dashboard about 14 MB (static site behind Caddy). Trial is enough for small collections.

### Why Deploy Typesense on Railway?

Typesense needs a persistent disk, RAM you can grow, HTTPS and a private network to your app. Railway gives all of that with one click, so you get a secured search API and an admin dashboard in a few minutes and pay only for what your index uses. This is a community template, not affiliated with Typesense.
