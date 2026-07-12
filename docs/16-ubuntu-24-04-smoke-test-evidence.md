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
| `ai-stack` | Resource-dependent | Not run on `fi-1`; VPS is below `ai-stack` requirements. |

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

### Residual Risks

- The VPS remains below documented `docker-host` profile requirements. Treat this as install-script evidence, not workload-capacity evidence.
- This run did not deploy or operate real Docker workloads beyond `hello-world`.
- This run used root SSH access; Docker non-root group setup was not validated.

### Residual Risks

- `ai-stack` release-readiness evidence is still missing and needs a VPS/VM with at least 4 GiB RAM and 50 GiB disk available.
- This run used root SSH access; disabling root/password login requires a separate validated non-root key-access setup.
- This run did not validate Ubuntu 26.04 compatibility.
