[← Architecture Operations](architecture-operations.md) · [Back to README](../README.md) · [n8n →](04-n8n.md)

# PostgreSQL With Supabase-Related Components

This repository does not currently provide full self-hosted Supabase. The supported scope is PostgreSQL with selected Supabase-related components where they are actually implemented in `docker-compose/docker-compose.yml`.

## Current Scope

Implemented for `ai-stack`:
- PostgreSQL using the Supabase Postgres image (`supabase_db`).
- `pgvector` setup through `docker-compose/supabase/init.sql` and [pgvector](06-vector-db.md).
- Supabase Meta (`supabase_meta`) for Studio metadata access.
- Supabase Studio (`supabase_studio`) as a local admin UI.
- PgBouncer, Redis, n8n and n8n worker as part of the broader AI automation stack.

Not implemented in the current stack:
- Supabase Auth / GoTrue.
- PostgREST / REST API.
- Supabase Realtime.
- Supabase Storage.
- Edge Functions.
- Kong / API gateway.
- Full self-hosted Supabase platform support.

Full Supabase is deferred and not current support.

## Component Matrix

| Component | Current status | Documentation wording |
|---|---|---|
| PostgreSQL / Supabase Postgres image | Present | PostgreSQL using Supabase Postgres image |
| pgvector | Present | pgvector on PostgreSQL |
| Supabase Meta | Present | selected Supabase-related component for Studio |
| Supabase Studio | Present | optional local Studio UI |
| PgBouncer | Present | PostgreSQL connection pooling |
| Redis | Present | queue/cache component |
| n8n | Present | automation runtime |
| Supabase Auth / GoTrue | Not implemented | not part of the current implemented stack |
| PostgREST / REST API | Not implemented | not part of the current implemented stack |
| Supabase Realtime | Not implemented | not part of the current implemented stack |
| Supabase Storage | Not implemented | not part of the current implemented stack |
| Edge Functions | Not implemented | not part of the current implemented stack |
| Kong / API gateway | Not implemented | not part of the current implemented stack |

## Prerequisites

- Docker and Docker Compose installed: [Docker Installation](02-docker-installation.md).
- Generated local secrets in `docker-compose/.env`: [Secrets](13-secrets.md).
- `ai-stack` resources from [System Requirements](../requirements/system-requirements.md).

## Startup Path

Use the canonical `ai-stack` flow from [Quick Start](../QUICKSTART.md). The current compose stack starts the implemented services only; it does not start Auth, REST API, Realtime, Storage, Edge Functions or an API gateway.

For component scripts, `scripts/04-setup-supabase.sh` starts `supabase_db` only. Use the full compose flow when you need `supabase_meta` and `supabase_studio` as well.

## Local Endpoints

| Service | Local endpoint | Notes |
|---|---|---|
| PostgreSQL | `localhost:54322` | Password is `SUPABASE_DB_PASSWORD` in local `.env`; do not print it. |
| PgBouncer | `localhost:6432` | Used by n8n for PostgreSQL connection pooling. |
| Supabase Studio | `http://localhost:54323` | Local UI backed by `supabase_meta`. |

These ports are bound to `127.0.0.1` in the default compose file. For external access, use SSH tunnel or a reviewed Nginx/reverse proxy path.

## pgvector

`pgvector` setup is documented in [pgvector](06-vector-db.md). The SQL source of truth is `docker-compose/supabase/init.sql`.

Safe checks should avoid printing secrets. Prefer commands that use existing environment handling or run through documented scripts instead of pasting passwords into terminal history.

## Troubleshooting

If PostgreSQL is not reachable:
- Check that the `supabase_db` service is running.
- Check logs for `supabase_db` without printing `.env` contents.
- Confirm `docker-compose/.env` exists and was generated through [Secrets](13-secrets.md).

If Studio is not reachable:
- Check that both `supabase_meta` and `supabase_studio` are running in the compose stack.
- Confirm access uses `http://localhost:54323` unless a reviewed reverse proxy path is configured.

## See Also

- [Infrastructure Setup](03-infrastructure-setup.md) — AI stack component order.
- [pgvector](06-vector-db.md) — vector search setup on PostgreSQL.
- [Secrets](13-secrets.md) — `.env` generation and rotation.
- [Backups](10-backup-restore.md) — PostgreSQL backup and restore.
