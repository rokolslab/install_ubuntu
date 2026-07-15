# Ubuntu 24.04 Smoke Test Evidence

[Back to README](../README.md) | [Quality Checks](12-quality-checks.md) | [Ready Rules](14-ready-rules.md) | [Acceptance Criteria](acceptance-criteria.md)

## Purpose

This document records sanitized smoke-test evidence from clean Ubuntu 24.04 LTS VPS/VM runs. It is a release-readiness input, not a production guarantee.

Do not include passwords, private keys, token values, IP addresses, raw `.env` contents, or full firewall dumps with sensitive source addresses.

## Evidence Format

Each run should record:

- Date and UTC timestamp.
- VPS/VM provider or type, with host identity sanitized if needed.
- Ubuntu version, kernel, CPU, RAM, disk and swap summary.
- Git commit tested.
- Profile tested.
- Commands run and exit status.
- Pass, fail or not-run result.
- Sanitized observations and residual risks.

## Profile Matrix

| Profile | First smoke-test requirement | Current evidence status |
|---|---|---|
| `minimal` | Mandatory for first release-readiness evidence | Passed on 2026-07-12 with notes below. |
| `docker-host` | Mandatory, but only on a VPS/VM that meets profile requirements | Forced installation-only check passed on `fi-1` after operator override; preflight still classified VPS as `NO` due RAM/disk below requirement. |
| `ai-stack` | Resource-dependent | Full runtime smoke passed on a suitable sanitized Ubuntu 24.04 VPS on 2026-07-15; see run below. |

## Run 2026-07-15: Suitable VPS `ai-stack` Full Runtime Smoke

### Environment

- Timestamp: 2026-07-15T00:00Z to 2026-07-15T01:25Z.
- SSH target: sanitized `vps-ai-1`.
- Host identity: sanitized.
- OS: Ubuntu 24.04.4 LTS.
- Architecture: `x86_64`.
- CPU: 4 vCPU.
- RAM: about 5902 MiB.
- Disk: about 118 GiB available to the test filesystem.
- Swap: 2047 MiB after `scripts/security/swap.sh --size 2G --force-recreate`.
- Docker: `Docker version 29.6.1`.
- Docker Compose: `Docker Compose version v5.3.1`.
- Git commit tested: `a170999`, plus working-tree verification for the `supabase_studio` healthcheck override recorded in this document.
- Remote test path: `/home/ops/install_ubuntu-test`.

### Commands And Results

| Step | Command | Exit status | Result |
|---|---|---:|---|
| SSH/connectivity | `ssh -i <admin-key> -o IdentitiesOnly=yes ops@<host> 'hostname; id; uname -a'` | 0 | Passed. |
| Remote script verification | `bash scripts/98-verify-scripts.sh` | 0 | Passed on the VPS test copy. |
| Profile preflight matrix | `bash scripts/00-preflight-check.sh --profile <profile>` for `minimal`, `proxy`, `docker-host`, `web`, `ai-stack` | 0 | Passed; all listed profiles classified as `OK` after swap was enabled. |
| Safe readiness checks | `bash scripts/99-ready-checks.sh --profile minimal|proxy|docker-host|web` | 0 | Passed in the prepared VPS state. |
| Security baseline | `sudo env DEBIAN_FRONTEND=noninteractive bash scripts/02-security-baseline.sh --profile ai-stack` | 0 | Passed; SSH access remained available through explicit admin key. |
| Secrets generation | `bash scripts/12-generate-secrets.sh --profile ai-stack` | 0 | Passed; generated `.env` was not logged and had mode `600`. |
| Compose runtime | `docker compose --env-file .env up -d` | 0 | Passed after resolving unavailable image tags and portable init SQL issues. |
| Ready checks | `sudo bash scripts/99-ready-checks.sh --profile ai-stack` | 0 | Passed. |
| pgvector smoke | `SELECT vector_dims('[1,2,3]'::vector);` and schema checks | 0 | Passed; `vector` extension and expected tables were present. |
| Studio healthcheck regression | Docker health for `supabase_studio` before and after Compose override | 0 | Reproduced `unhealthy` due image `localhost` probe; passed after overriding healthcheck to `http://supabase_studio:3000/api/platform/profile`. |
| Backup script prerequisite | `sudo env BACKUP_DIR=<drill-dir> RETENTION_DAYS=0 bash scripts/10-backup-postgres.sh` before `postgresql-client` install | 1 | Expected prerequisite failure: `pg_dump` was absent. |
| Backup/restore drill | Same backup command after `postgresql-client` install, restore into separate `restore_drill` DB, marker-row query | 0 | Passed; marker query returned `restore-drill-ok`; restored public table count was `57`; temporary DB/table were removed. |

### Observations

- `ai-stack` preflight classified the VPS as suitable after 2 GiB swap was enabled.
- Security baseline enabled UFW with public `22`, `80` and `443` only for the selected profile; internal service ports remained bound to `127.0.0.1`.
- Effective SSH hardening was verified with `sshd -T`: password auth disabled, root login disabled, max auth tries set to `3`, empty passwords disabled.
- `fail2ban` and `unattended-upgrades` were active after baseline.
- Runtime readiness passed for PostgreSQL/Supabase, PgBouncer, Redis, n8n, Docker and profile-specific checks.
- The pgvector check passed without creating the default HNSW index during init; HNSW creation remains an operator action after CPU compatibility and workload sizing are known.
- `supabase_studio` was reachable through the host-local published port and became Docker `healthy` after overriding the inherited loopback healthcheck.
- Backup/restore evidence used a temporary marker table and separate restore database; both were removed after the drill.
- Restoring a dump produced by host `pg_dump` 16 required host `psql` 16 for restore. Container `psql` 15 rejected the dump's `\restrict` command, so documented restore commands should use a PostgreSQL client version compatible with the dump tool.

### Result

`ai-stack` Ubuntu 24.04 suitable VPS full runtime smoke test: passed.

### AI-Stack Residual Risks

- This was a single suitable VPS run, not a broad provider matrix.
- Ubuntu 26.04 compatibility remains unvalidated and must not be claimed until a real Ubuntu 26.04 environment passes the defined checks.
- The stack was left running after the smoke test for follow-up inspection.

## Run 2026-07-12: `fi-1` Minimal Profile

### Environment

- Timestamp: 2026-07-12T10:22Z to 2026-07-12T10:26Z.
- SSH target: `fi-1`.
- Host identity: sanitized.
- Virtualization: KVM/OpenStack VM.
- OS: Ubuntu 24.04.4 LTS.
- Kernel at start: `6.8.0-35-generic`.
- Architecture: `x86_64`.
- CPU: 1 vCPU.
- RAM: 961 MiB.
- Disk: preflight reported 7 GiB free on `/`.
- Swap: 0 MiB.
- Git commit tested: `4b5d8bf`.
- Remote test path: `/root/install_ubuntu-smoke-4b5d8bf`.

### Commands And Results

| Step | Command | Exit status | Result |
|---|---|---:|---|
| SSH/connectivity | `ssh fi-1 'hostnamectl; printf "USER=%s\\n" "$USER"; id -u; uname -a'` | 0 | Passed. |
| Resource snapshot | `ssh fi-1 'date -u +%Y-%m-%dT%H:%M:%SZ; nproc; free -h; df -h /; command -v docker || true; command -v git || true; command -v curl || true'` | 0 | Passed; Docker absent before install flow. |
| Prepare remote test directory | `ssh fi-1 'test -d /root && mkdir -p /root/install_ubuntu-smoke-4b5d8bf'` | 0 | Passed. |
| Deploy test tree | `git archive --format=tar HEAD | ssh fi-1 'tar -x -C /root/install_ubuntu-smoke-4b5d8bf'` | 0 | Passed. |
| Minimal preflight | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/00-preflight-check.sh --profile minimal'` | 0 | Passed; profile state `OK`. |
| Docker-host preflight | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/00-preflight-check.sh --profile docker-host'` | 0 | Not run beyond preflight; profile state `NO`. |
| Security baseline | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/02-security-baseline.sh --profile minimal'` | 0 | Passed. |
| SSH reconnect | `ssh fi-1 'printf "reconnect-ok\\n"; systemctl is-active ssh || systemctl is-active sshd'` | 0 | Passed; SSH service active. |
| Minimal ready checks | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/99-ready-checks.sh --profile minimal'` | 0 | Passed with RAM/swap warning. |

### Observations

- `minimal` preflight classified the VPS as suitable for minimal baseline.
- `docker-host`, `web` and `ai-stack` were classified as `NO` on this VPS because resources are below documented requirements.
- Security baseline completed system updates, UFW setup, SSH hardening, fail2ban, unattended-upgrades and sysctl hardening.
- SSH hardening did not disable root login or password authentication because non-root key access was not confirmed, preventing accidental lockout.
- UFW remained active with SSH on port 22 rate-limited; no HTTP, HTTPS, Docker, database, Redis, n8n, Prometheus or Grafana ports were opened by the minimal flow.
- `fail2ban` and `unattended-upgrades` were active during ready checks.
- Ready checks warned that RAM is below 1 GiB and swap is absent; this is a residual operational risk for small VPS stability.
- Package upgrade installed a newer kernel (`6.8.0-134-generic` expected by the system), but the running kernel stayed `6.8.0-35-generic`; reboot is recommended if this VPS is kept after testing.

### Result

`minimal` clean Ubuntu 24.04 VPS smoke test: passed.

## Run 2026-07-12: `fi-1` Docker-Host Forced Installation Check

### Environment

- Timestamp: 2026-07-12T10:36Z to 2026-07-12T10:39Z.
- SSH target: `fi-1`.
- Host identity: sanitized.
- OS: Ubuntu 24.04.4 LTS.
- CPU: 1 vCPU.
- RAM before Docker install: 961 MiB.
- Disk before Docker install: 6.1 GiB free on `/`.
- Swap: 0 MiB.
- Git commit tested: `4b5d8bf`.
- Remote test path: `/root/install_ubuntu-smoke-4b5d8bf`.

### Scope Note

This was a forced installation-only check requested after preflight classified the VPS as below `docker-host` requirements. It validates that the Docker installation script can complete on this clean Ubuntu 24.04 VPS, but it does not validate operational capacity for Docker workloads on this VPS size.

### Commands And Results

| Step | Command | Exit status | Result |
|---|---|---:|---|
| Pre-install state | `ssh fi-1 'date -u +%Y-%m-%dT%H:%M:%SZ; free -h; df -h /; command -v docker || true; systemctl is-active docker 2>/dev/null || true'` | 0 | Passed; Docker absent and service inactive. |
| Docker-host preflight | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/00-preflight-check.sh --profile docker-host'` | 0 | Profile state `NO`; operator requested forced install check anyway. |
| Docker install | `ssh fi-1 'DEBIAN_FRONTEND=noninteractive bash /root/install_ubuntu-smoke-4b5d8bf/scripts/03-install-docker.sh --profile docker-host'` | 0 | Passed. |
| Docker-host ready checks | `ssh fi-1 'bash /root/install_ubuntu-smoke-4b5d8bf/scripts/99-ready-checks.sh --profile docker-host'` | 0 | Passed with RAM/swap warning. |
| Docker versions and service | `ssh fi-1 'docker --version; docker compose version; systemctl is-active docker; docker ps --format "{{.Names}} {{.Status}}"; df -h /; free -h'` | 0 | Passed; Docker active. |
| Container smoke test | `ssh fi-1 'docker run --rm hello-world >/dev/null'` | 0 | Passed. |

### Observations

- Docker Engine installed successfully: `Docker version 29.6.1, build 8900f1d`.
- Docker Compose plugin installed successfully: `Docker Compose version v5.3.1`.
- Docker service was active after install and restart with `/etc/docker/daemon.json`.
- The script's built-in `hello-world` run succeeded, and a separate `docker run --rm hello-world` succeeded after install.
- Ready checks passed for `docker-host`, while still warning that RAM is below 1 GiB and swap is absent.
- Disk after Docker install was about 6.0 GiB free on `/`.
- Initial install output included a noisy `ERR` trap line while checking old Docker apt sources, then continued and completed with exit status 0. Follow-up fix verification on the same VPS reran `03-install-docker.sh --profile docker-host` successfully without that noisy `ERR` line.

### Result

`docker-host` clean Ubuntu 24.04 VPS forced installation-only smoke check: passed.

### Docker-Host Residual Risks

- The VPS remains below documented `docker-host` profile requirements. Treat this as install-script evidence, not workload-capacity evidence.
- This run did not deploy or operate real Docker workloads beyond `hello-world`.
- This run used root SSH access; Docker non-root group setup was not validated.

## Overall Residual Risks

- Ubuntu 24.04 evidence now covers `minimal`, a forced `docker-host` installation-only check on a below-requirements VPS, and full `ai-stack` runtime on a suitable VPS.
- The `docker-host` run remains install-script evidence only because that VPS was below documented resources.
- This evidence does not validate Ubuntu 26.04 compatibility.

## See Also

- [Quality Checks](12-quality-checks.md) — commands and clean VM evidence workflow.
- [Ready Rules](14-ready-rules.md) — readiness gates and stop conditions.
- [Acceptance Criteria](acceptance-criteria.md) — profile-level smoke-test expectations.
