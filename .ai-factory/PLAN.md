# Implementation Plan: VPS safe prep and profile tests

Branch: current `main`
Created: 2026-07-15

## Original Request

приведения VPS к состоянию для тестирования на непротестированных ролях, проведение необхлдимых тестов

## Settings

- Testing: yes
- Logging: verbose
- Docs: no
- Scope: Safe prep only. Разрешено включить swap 2G при отсутствии, доставить репозиторий в тестовую директорию и выполнить проверки. Не запускать `02-security-baseline.sh`, firewall/SSH hardening, `docker compose up`, secrets generation или другие mutating runtime flows без отдельного подтверждения.

## Roadmap Linkage

Milestone: "AI-stack runtime evidence"
Rationale: Подготовка VPS и profile checks уточняют готовность хоста для оставшихся resource-dependent тестов без заявления полного runtime evidence.

## Tasks

### Phase 1: Safe Access And Staging

- [x] Task 1: Проверить SSH-доступ строго через `<admin-key>`.
  - Deliverable: подтверждённый доступ к тестовому VPS с `IdentitiesOnly=yes`.
  - Expected behavior: команда завершается с exit code `0`, пользователь `ops`, hostname получен.
  - Files: no repository changes beyond QA artifacts.
  - Logging requirements: фиксировать command shape, exit status, user/hostname; не логировать private key material.

- [x] Task 2: Доставить текущий репозиторий на VPS в изолированную test-директорию.
  - Deliverable: remote test directory содержит рабочую копию без `.git`, `.ai-factory/qa` run artifacts и без secrets.
  - Expected behavior: scripts запускаются с корректным `PROJECT_ROOT`; tracked secret-like files не копируются.
  - Files: remote test directory only.
  - Logging requirements: фиксировать список top-level paths и размер/статус копирования; не выводить `.env`, ключи или tokens.
  - Dependencies: Task 1.

### Phase 2: VPS Preparation

- [x] Task 3: Включить swap 2G, если swap отсутствует.
  - Deliverable: active `/swapfile` с persist entry в `/etc/fstab`, если swap был `0MB`.
  - Expected behavior: повторный запуск idempotent; если swap уже есть, script ничего не меняет.
  - Files: remote `/swapfile`, `/etc/fstab` managed by `scripts/security/swap.sh`.
  - Logging requirements: фиксировать `swapon --show`, total swap before/after и exit status; не логировать unrelated system data.
  - Dependencies: Task 2.

### Phase 3: Profile Tests

- [x] Task 4: Запустить remote preflight matrix и profile-specific preflight checks.
  - Deliverable: результаты `scripts/00-preflight-check.sh` для общей matrix и профилей `minimal`, `proxy`, `docker-host`, `web`, `ai-stack`.
  - Expected behavior: после swap VPS получает `OK` для всех ресурсных профилей, если thresholds satisfied.
  - Files: no remote config changes expected.
  - Logging requirements: фиксировать profile state rows, OS/resources summary и warnings; не выводить hardware dumps больше нужного summary.
  - Dependencies: Task 3.

- [x] Task 5: Выполнить non-mutating readiness checks для уже установленного состояния.
  - Deliverable: результаты `scripts/99-ready-checks.sh --profile minimal|proxy|docker-host|web`, без `ai-stack` runtime readiness, потому что compose stack не запускается в safe prep scope.
  - Expected behavior: `minimal/proxy/web` могут выявить отсутствие `ufw`/baseline как expected blocker до security baseline; `docker-host` должен подтвердить Docker service через sudo-capable context или дать конкретный blocker.
  - Files: no remote config changes expected.
  - Logging requirements: фиксировать pass/fail per profile, первые error lines и interpretations; не менять firewall/SSH services.
  - Dependencies: Task 4.

- [x] Task 6: Выполнить local и remote Bash verification.
  - Deliverable: `bash scripts/98-verify-scripts.sh` локально и на remote test copy.
  - Expected behavior: syntax/ShellCheck checks проходят или дают actionable failure.
  - Files: no config changes expected.
  - Logging requirements: фиксировать command, exit status и summary count; не включать full irrelevant logs.
  - Dependencies: Task 2.

### Phase 4: QA Evidence

- [x] Task 7: Сохранить AIF QA evidence по выполненным тестам.
  - Deliverable: обновлённые QA artifacts под `.ai-factory/qa/` с result matrix, blockers и рекомендациями.
  - Expected behavior: результаты отделяют resource suitability от full runtime evidence; failed readiness до baseline не трактуется как product defect.
  - Files: `.ai-factory/qa/**`.
  - Logging requirements: сохранять sanitized evidence, command names, exit codes, profile states; не сохранять secrets/private keys.
  - Dependencies: Tasks 4-6.

## Acceptance Criteria

- SSH подтверждён строго через explicit admin key.
- VPS содержит тестовую копию репозитория в isolated test directory.
- Swap активен или документирован как уже существующий.
- Preflight matrix выполнена после подготовки и классифицирует профили по фактическому состоянию.
- Readiness checks выполнены только для безопасных профилей без запуска security baseline и compose runtime.
- Local/remote script verification выполнены.
- AIF QA evidence сохранён без secrets.

## Next Step

Execute the safe prep plan now, then report passed/failed/blocked checks and what remains for full `ai-stack` smoke.

## Full Smoke Addendum

User approval received after safe prep: run security baseline and full `ai-stack` runtime smoke on the prepared VPS.

### Phase 5: Authorized Security And Runtime Smoke

- [x] Task 8: Run `02-security-baseline.sh --profile ai-stack` on remote test copy.
  - Deliverable: UFW active with SSH/80/443, fail2ban active, unattended-upgrades active, sysctl baseline applied.
  - Expected behavior: SSH access remains available through explicit admin key after hardening.
  - Files: remote `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config.d/00-install-ubuntu-hardening.conf`, UFW/fail2ban/unattended-upgrades/sysctl state.
  - Logging requirements: record service states and effective SSH options; do not log keys or secrets.

- [x] Task 9: Fix blockers discovered by runtime smoke in tracked project files and remote test copy.
  - Deliverable: update unavailable Compose image tags and portable Supabase init SQL; fix SSH hardening cloud-init override behavior.
  - Expected behavior: all referenced images resolve, pgvector init succeeds on VPS CPU, effective `PasswordAuthentication no` is enforced.
  - Files: `docker-compose/docker-compose.yml`, `docker-compose/supabase/init.sql`, `scripts/security/ssh-hardening.sh`.
  - Logging requirements: record image names/tags and sanitized SQL outcomes only.

- [x] Task 10: Run `ai-stack` runtime smoke.
  - Deliverable: generated `.env`, `docker compose up -d`, `99-ready-checks.sh --profile ai-stack`, pgvector/table checks and exposure check.
  - Expected behavior: required services run and ready checks pass; internal service ports bind to `127.0.0.1`.
  - Files: remote `docker-compose/.env`, Docker containers and volumes on VPS.
  - Logging requirements: never print `.env` values; record only service names, states, exit codes and sanitized query results.

### Phase 6: High-Priority Follow-Ups

- [x] Task 11: Fix `supabase_studio` Docker healthcheck.
  - Deliverable: Compose override for Studio healthcheck and verified `healthy` container state on the VPS.
  - Expected behavior: healthcheck uses a URL reachable from inside the container and still checks the application endpoint.
  - Files: `docker-compose/docker-compose.yml`, `.ai-factory/patches/2026-07-15-01.19.md`.
  - Regression check: before fix, Docker health was `unhealthy` while host-local HTTP passed; after fix and service recreate, Docker health became `healthy`.

- [x] Task 12: Run backup/restore drill without exposing secrets.
  - Deliverable: backup created by `scripts/10-backup-postgres.sh`, restored into separate `restore_drill` database, marker-row SQL verified, temporary DB/table removed.
  - Expected behavior: backup and restore complete with exit code `0`; no `.env` values are printed.
  - Files: remote backup drill artifacts only; docs updated with sanitized evidence.
  - Finding: host `pg_dump` 16 dump should be restored by compatible host `psql` 16, not older container `psql` 15.

- [x] Task 13: Sync docs and roadmap/status.
  - Deliverable: `PLAN.md`, `.ai-factory/ROADMAP.md`, `docs/10-backup-restore.md`, `docs/12-quality-checks.md`, `docs/14-ready-rules.md`, `docs/16-ubuntu-24-04-smoke-test-evidence.md` updated.
  - Expected behavior: docs claim only verified Ubuntu 24.04 results and mark Ubuntu 26.04 compatibility as blocked until a real 26.04 environment exists.
