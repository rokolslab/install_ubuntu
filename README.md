# install_ubuntu

> Secure Ubuntu/VPS bootstrap with profile-aware paths: minimal hardening, proxy/VPN base, Docker host, web server, or full AI automation stack.

`install_ubuntu` is a practical infrastructure starter kit for Ubuntu/VPS servers. It can prepare a tiny VPS for safe baseline hardening or a larger server for AI automation workloads: Telegram bots, LLM workflows, RAG systems, internal automation, and self-hosted services.

This repository fits the RokolsLab stack: **Linux/VPS · Docker · Python/LLM infrastructure · Telegram bots · RAG · automation workflows**. It is not a blind one-command installer. Choose a profile first, then run only the scripts needed for that server.

## Why It Exists

Most self-hosted projects need the same foundation before product work starts:

- hardened SSH access, firewall, fail2ban and security updates;
- Docker and Docker Compose installed correctly when containers are needed;
- PostgreSQL with selected Supabase-related components, Redis and pgvector for AI workflows and RAG on larger hosts;
- n8n main/worker setup for automation pipelines on the `ai-stack` profile;
- Nginx, SSL, monitoring, backups and readiness checks when the selected profile needs them.

This repo turns that foundation into documented steps, scripts and compose files.

## What You Get

| Area | Included |
|------|----------|
| Server baseline | Ubuntu hardening, SSH keys, UFW, fail2ban, unattended upgrades |
| Container runtime | Docker Engine, Docker Compose, daemon configuration |
| AI automation stack | n8n, Redis, PostgreSQL with selected Supabase-related components, pgvector, PgBouncer for `ai-stack` |
| Production support | Nginx reverse proxy, SSL path, monitoring, backups, ready checks |
| Safety | Secret generation, closed local ports, healthchecks, version-pinned compose |
| Documentation | Step-by-step guides for VPS and local server installation |

## Profile Flows

| Profile | Use when | Minimum path |
|---------|----------|--------------|
| `minimal` | Small VPS hardening only | preflight, SSH keys, security baseline, ready checks |
| `proxy` | Base for x-ui/3x-ui/VPN/proxy panel | minimal path + explicit service ports |
| `docker-host` | Small container host | minimal path + Docker install |
| `web` | Small web/app server | minimal path + HTTP/HTTPS reverse proxy |
| `ai-stack` | n8n, Redis, PostgreSQL/Supabase-related components, pgvector stack | Docker, secrets, compose stack, service ready checks |

`4GB RAM / 50GB disk` belongs to `ai-stack`, not to every VPS. A `1 vCPU / 1GB RAM` server can still be valid for `minimal` or `proxy` with warnings.

## Quick Start

Minimal VPS hardening:

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

Full AI automation stack:

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile ai-stack
sudo bash scripts/03-install-docker.sh --profile ai-stack
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
cd docker-compose
docker compose --env-file .env up -d
sudo bash ../scripts/99-ready-checks.sh --profile ai-stack
```

For the full installation path, use [QUICKSTART.md](QUICKSTART.md). To understand what each script does before running it, see [Scripts Catalog](docs/scripts-catalog.md). For GitHub, VPS/root, deploy and backup key scenarios, see [SSH Keys](docs/ssh-keys.md).

## Real Use Cases

- Prepare a VPS for AI assistants and Telegram bots.
- Run n8n workflows with Redis queue mode and PostgreSQL storage.
- Build a self-hosted RAG base with PostgreSQL, selected Supabase-related components and pgvector.
- Standardize repeatable infrastructure setup for client AI automation projects.
- Keep deployment knowledge in scripts and docs instead of one-off terminal history.

## Repository Map

| Path | Purpose |
|------|---------|
| [scripts/](scripts/) | Installation, security, backup and readiness scripts |
| [docker-compose/](docker-compose/) | Main compose stack and service configuration |
| [docs/](docs/) | Detailed component guides and operating notes |
| [requirements/](requirements/) | System requirements and compatibility notes |
| [templates/](templates/) | Reusable Nginx and firewall templates |
| [QUICKSTART.md](QUICKSTART.md) | Copy-paste installation walkthrough |

## Documentation

| Guide | Description |
|-------|-------------|
| [Quick Start](QUICKSTART.md) | End-to-end installation path |
| [Project Requirements](docs/project-requirements.md) | Scope, baseline and change-control rules |
| [Version Policy](docs/version-policy.md) | Ubuntu packages, Docker and Compose image version rules |
| [Acceptance Criteria](docs/acceptance-criteria.md) | Profile-level readiness expectations |
| [System Requirements](requirements/system-requirements.md) | CPU, RAM, disk and OS requirements |
| [VPS Profiles](docs/profiles.md) | Minimal, proxy, docker-host, web and ai-stack profiles |
| [Server Security](docs/01-server-security.md) | SSH, UFW, fail2ban and hardening |
| [SSH Keys](docs/ssh-keys.md) | Key naming, GitHub/VPS/deploy scenarios and permissions |
| [Scripts Catalog](docs/scripts-catalog.md) | What each script does, when to run it and what it does not do |
| [Security Hardening Details](docs/01-server-security-hardening.md) | Advanced SSH, sysctl and audit notes |
| [Docker Installation](docs/02-docker-installation.md) | Docker Engine and Compose setup |
| [Infrastructure Setup](docs/03-infrastructure-setup.md) | Stack overview and deployment order |
| [Architecture](docs/architecture.md) | Runtime components and data flow |
| [Architecture Operations](docs/architecture-operations.md) | Scaling, backups and performance notes |
| [Supabase scope](docs/03-supabase.md) | PostgreSQL with Supabase-related Meta/Studio components |
| [n8n](docs/04-n8n.md) | n8n main/worker deployment |
| [Redis](docs/05-redis.md) | Redis setup for queues and caching |
| [pgvector](docs/06-vector-db.md) | Vector search setup for RAG |
| [Nginx](docs/07-nginx.md) | Reverse proxy and SSL path |
| [Nginx Operations](docs/07-nginx-operations.md) | Advanced proxy and troubleshooting |
| [Hardware Drivers](docs/08-hardware-drivers.md) | GPU, NIC and bare-metal compatibility |
| [Monitoring](docs/09-monitoring.md) | Prometheus and Grafana notes |
| [Backups](docs/10-backup-restore.md) | PostgreSQL backup and restore |
| [Troubleshooting](docs/11-troubleshooting.md) | Common failure modes and fixes |
| [Quality Checks](docs/12-quality-checks.md) | Validation and readiness checks |
| [Ubuntu 24.04 Smoke Test Evidence](docs/16-ubuntu-24-04-smoke-test-evidence.md) | Sanitized clean VM/VPS smoke-test results |
| [Secrets](docs/13-secrets.md) | Passwords, `.env` and rotation |
| [Ready Rules](docs/14-ready-rules.md) | Installation readiness gates |
| [Scripts Order](docs/15-scripts-order.md) | Canonical script execution sequence |
| [Project Plan](PLAN.md) | Roadmap and remaining quality gates |

## When To Use This Repo

Use it when you need a practical base for AI automation infrastructure on Ubuntu: small VPS, dedicated server, internal lab, or client deployment sandbox.

Do not use it as a blind one-command installer. Read the relevant guide before each stage, especially before security hardening and public reverse proxy setup.

## Safety Notes

- Run scripts with `sudo` only after reading the matching documentation.
- Change or generate all secrets before exposing services.
- Keep databases and internal tools bound to localhost unless public access is intentional.
- Configure backups before using the stack for production data.

## Related Profile

Built in the same practical direction as [RokolsLab](https://github.com/RokolsLab): AI automation, LLM workflows, Telegram bots and self-hosted Linux/VPS infrastructure for real working tasks.

## License

This project is provided "as is" for educational and commercial use.
