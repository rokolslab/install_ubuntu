# Project Roadmap

> Развить `install_ubuntu` от profile-aware Bash/Docker bootstrap repo к безопасной hybrid Bash + Ansible платформе для централизованного управления несколькими Ubuntu VPS без потери текущих safety guarantees.

## Milestones

- [x] **Profile-aware Bash baseline** — текущие `minimal`, `proxy`, `docker-host`, `web` и `ai-stack` flows оформлены через Bash entry points, docs, profile requirements и readiness checks.
- [x] **Security and governance baseline** — зафиксированы project rules, Ubuntu 24.04 primary baseline, Ubuntu 26.04 validation target, secrets policy, version policy и CI static gates.
- [x] **Ubuntu 24.04 smoke evidence** — получено sanitized evidence для `minimal`, forced installation-only `docker-host` checks и полного `ai-stack` runtime smoke на подходящем VPS.
- [ ] **Ansible architecture decision and docs** — зафиксировать hybrid staged migration: Ansible как fleet control layer, Bash как текущий source of truth, Docker Compose как runtime owner для `ai-stack`.
- [ ] **Read-only Ansible foundation** — добавить `ansible/` skeleton с `ansible.cfg`, example inventory, ignored real inventory model, `ping.yml`, `audit.yml` и документацией без mutating playbooks.
- [ ] **Native Ansible preflight parity** — реализовать Ansible preflight для OS/resources/profile suitability с parity к `scripts/00-preflight-check.sh` и понятным `--check` behavior.
- [ ] **Native Ansible readiness parity** — перенести read-only readiness checks для `minimal`, `proxy` и `docker-host`; `ai-stack` checks оставить отдельным более поздним этапом из-за secrets/compose runtime.
- [ ] **Native maintenance roles** — добавить low-risk Ansible maintenance для package/service state, unattended-upgrades и audit-friendly operations с `--check --diff`, `serial` и explicit `--limit` guidance.
- [ ] **Users and authorized keys role** — добавить безопасное управление admin/deploy/backup users and authorized keys как prerequisite для последующего SSH hardening, без unrestricted `NOPASSWD: ALL` default.
- [ ] **Native security modules migration** — по одному PR мигрировать fail2ban, sysctl и swap в native Ansible roles, сохраняя Bash scripts как compatibility/emergency tools до подтверждения evidence.
- [ ] **Native Docker install migration** — заменить `scripts/03-install-docker.sh` на Ansible Docker role только после parity, idempotency, check-mode expectations и clean Ubuntu 24.04 validation.
- [ ] **High-risk SSH and firewall migration** — мигрировать UFW/firewall и SSH hardening в Ansible только после dedicated lockout-prevention design, second-connection validation и rollback evidence.
- [ ] **Backup and Compose orchestration** — перенести backup scheduling и безопасную Docker Compose orchestration под Ansible, не меняя Docker Compose как source of truth для runtime stack.
- [x] **AI-stack runtime evidence** — полный `ai-stack` smoke test на подходящем Ubuntu 24.04 VPS пройден; readiness/release docs синхронизированы, включая backup/restore drill evidence.
- [ ] **Ubuntu 26.04 compatibility validation** — blocked до появления реальной Ubuntu 26.04 VPS/VM; отдельно валидировать Bash + Ansible flows до любых compatibility support claims.

## Completed

| Milestone | Date |
|-----------|------|
| Profile-aware Bash baseline | 2026-07-12 |
| Security and governance baseline | 2026-07-12 |
| Ubuntu 24.04 smoke evidence | 2026-07-15 |
| AI-stack runtime evidence | 2026-07-15 |

## Next Up

1. **Ansible architecture decision and docs** — создать focused docs page с source-of-truth matrix, inventory/SSH/become/secrets model и phased migration rules.
2. **Read-only Ansible foundation** — только после approval: добавить минимальное `ansible/` дерево без roles и без mutating playbooks.
3. **Ubuntu 26.04 compatibility validation** — начать только после появления реальной Ubuntu 26.04 VPS/VM; критерии: package availability, Docker repository flow, Compose config, profile preflight/ready checks and backup/restore drill.

## Guardrails

- Не переписывать все Bash scripts одним PR.
- Не держать Bash и Ansible как равноправные реализации одной операции дольше одного transition этапа.
- Не мигрировать firewall и SSH hardening в одном PR.
- Не делать `ai-stack` default path.
- Не отключать SSH host-key checking по умолчанию.
- Не добавлять Ansible Vault до появления конкретного secret-bearing Ansible use case.
- Не трекать real inventory, IP addresses, private keys, vault password files или generated `.env`.
- Для mutating Ansible playbooks требовать explicit `--limit`, conservative `serial` и documented rollback.
