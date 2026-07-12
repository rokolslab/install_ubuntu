# Acceptance Criteria

[Back to README](../README.md) | [Profiles](profiles.md) | [Quality Checks](12-quality-checks.md) | [Ready Rules](14-ready-rules.md)

## Purpose

This document defines profile-level acceptance criteria. It does not replace [QUICKSTART](../QUICKSTART.md), [Scripts Order](15-scripts-order.md), or detailed component docs.

## Common Criteria

- Ubuntu 24.04 LTS is the clean VM smoke-test baseline.
- Ubuntu 26.04 LTS compatibility must be validated separately before compatibility claims.
- Preflight must be run for the selected profile before install steps.
- If preflight classifies the selected profile as `NO`, that install flow must not be continued on that host and must be documented as not run.
- Ready checks must be run for the same profile after install steps.
- Risky changes need rollback or recovery notes.
- Internal services must remain closed unless a documented public access path exists.

## minimal

- Required preflight: `scripts/00-preflight-check.sh --profile minimal`.
- Expected installed components: SSH key path, security baseline, firewall, fail2ban, unattended security updates where applicable.
- Required open ports: SSH only, using the configured SSH port.
- Ports that must remain closed: HTTP, HTTPS, Docker, database, cache, dashboard, and automation service ports unless explicitly added later.
- Verification commands: profile ready check, SSH reconnect test, firewall status review, fail2ban status review.
- Rollback/recovery expectations: keep a working SSH session open during hardening and document how to restore SSH access if key or firewall settings fail.
- Clean Ubuntu 24.04 VM smoke-test expectations: preflight and ready checks pass for `minimal` without Docker or `.env` requirements.
- Current clean Ubuntu 24.04 evidence: passed on 2026-07-12; see [Ubuntu 24.04 Smoke Test Evidence](16-ubuntu-24-04-smoke-test-evidence.md).
- Ubuntu 26.04 compatibility validation expectations: confirm package names, SSH, UFW, fail2ban, and unattended-upgrades behavior before claiming compatibility.

## proxy

- Required preflight: `scripts/00-preflight-check.sh --profile proxy`.
- Expected installed components: minimal security baseline plus explicit firewall allowance only for chosen proxy/VPN service ports.
- Required open ports: SSH and the human-approved proxy/VPN service ports.
- Ports that must remain closed: unknown panel ports, database ports, Docker API, Redis, PostgreSQL, PgBouncer, n8n, monitoring, and dashboards.
- Verification commands: profile ready check, firewall status review, and manual confirmation that only approved service ports are open.
- Rollback/recovery expectations: document how to remove an allowed service port and keep SSH recovery available.
- Clean Ubuntu 24.04 VM smoke-test expectations: proxy baseline can complete without installing a third-party proxy panel.
- Ubuntu 26.04 compatibility validation expectations: validate firewall and package behavior before documenting compatibility.

## docker-host

- Required preflight: `scripts/00-preflight-check.sh --profile docker-host`.
- Expected installed components: minimal security baseline, Docker Engine, Docker Compose plugin, Docker service enabled.
- Required open ports: SSH only by default.
- Ports that must remain closed: Docker API, database, cache, dashboards, and application ports unless an explicit app deployment opens them.
- Verification commands: profile ready check, `docker --version`, `docker compose version`, and Docker service status.
- Rollback/recovery expectations: document how to stop Docker workloads and remove or disable Docker if installation causes system issues.
- Clean Ubuntu 24.04 VM smoke-test expectations: Docker install and ready checks pass without deploying the AI stack.
- Current clean Ubuntu 24.04 evidence: forced installation-only check passed on the 2026-07-12 `fi-1` VPS after operator override; preflight still classified `docker-host` as `NO` due insufficient resources, so this does not validate workload capacity.
- Ubuntu 26.04 compatibility validation expectations: validate the official Docker stable apt repository flow before claiming compatibility.

## web

- Required preflight: `scripts/00-preflight-check.sh --profile web`.
- Expected installed components: minimal security baseline and Nginx/reverse proxy path.
- Required open ports: SSH, HTTP `80/tcp`, and HTTPS `443/tcp` when the web profile is intentionally enabled.
- Ports that must remain closed: database, cache, Docker API, internal dashboards, and internal automation service ports.
- Verification commands: profile ready check, Nginx config test, firewall status review, and local HTTP/HTTPS health checks where configured.
- Rollback/recovery expectations: document how to disable a site, revert an Nginx config, and keep SSH recovery available.
- Clean Ubuntu 24.04 VM smoke-test expectations: web baseline can expose only HTTP/HTTPS plus SSH and pass profile ready checks.
- Ubuntu 26.04 compatibility validation expectations: validate Nginx package behavior and service management before claiming compatibility.

## ai-stack

- Required preflight: `scripts/00-preflight-check.sh --profile ai-stack`.
- Expected installed components: Docker Engine, Docker Compose plugin, generated local secrets, PostgreSQL with selected Supabase-related components where implemented, Redis, pgvector, PgBouncer, n8n, monitoring path, backups, and ready checks.
- Required open ports: SSH plus Nginx/reverse proxy ports when public access is intentionally configured. SSH tunnel is acceptable for admin access.
- Ports that must remain closed: PostgreSQL, Redis, PgBouncer, implemented Supabase-related local ports, n8n, Prometheus, Grafana, and direct Compose-published service ports unless an advanced explicit public access mode is reviewed separately.
- Verification commands: profile ready check, `docker compose config`, `docker compose ps`, service health checks, and backup readiness checks.
- Rollback/recovery expectations: document how to stop the stack without deleting data, how to avoid `docker compose down -v` unless data removal is intentional, and how to restore from backup.
- Clean Ubuntu 24.04 VM smoke-test expectations: selected `ai-stack` services start from generated local secrets and pass ready checks without public direct Compose exposure. Full Supabase platform services are not part of the current implemented stack.
- Ubuntu 26.04 compatibility validation expectations: validate Docker, Compose, service images, health checks, and backup/restore behavior before claiming compatibility.

## Related Docs

- [Scripts Order](15-scripts-order.md)
- [Quality Checks](12-quality-checks.md)
- [Ready Rules](14-ready-rules.md)
- [Secrets](13-secrets.md)
- [Version Policy](version-policy.md)
