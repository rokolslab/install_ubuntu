# План: Clean Ubuntu 24.04 VM smoke-test evidence

Дата создания: 2026-07-03
Режим: fast
Ветка: текущая `main`

## Settings

- Testing: yes — включить локальные static gates и documented smoke-test evidence checks.
- Logging: standard — для каждого VM-прогона фиксировать команды, timestamp, профиль, результат и краткий вывод без secrets.
- Docs: yes — mandatory docs checkpoint после сбора evidence.
- Scope: только clean Ubuntu 24.04 VM smoke-test evidence и связанные статусные updates; не менять install logic без отдельного approved plan.

## Цель

Снять главный release blocker: получить и задокументировать проверяемые результаты smoke-test на чистой Ubuntu 24.04 LTS VM для поддерживаемых profile flows. План не должен создавать иллюзию release readiness, если часть профилей не прогнана или прогнана с ограничениями.

## Контекст

- `PLAN.md` помечает `Clean Ubuntu 24.04 VM smoke-test evidence` как planned blocker.
- `docs/acceptance-criteria.md` задаёт profile-level критерии для `minimal`, `proxy`, `docker-host`, `web`, `ai-stack`.
- `docs/12-quality-checks.md` содержит общий checklist, но не хранит конкретные evidence snapshots.
- `docs/14-ready-rules.md` задаёт ready gates, но сейчас ориентирован в первую очередь на `ai-stack` examples.
- Нельзя запускать privileged/install scripts в этой agent-сессии без отдельного явного runtime approval и подходящей VM.

## Tasks

### Phase 1: Evidence Design

1. [x] Зафиксировать формат evidence-документа для Ubuntu 24.04 VM smoke tests.
   - Files: создать `docs/16-ubuntu-24-04-smoke-test-evidence.md`, при необходимости обновить `README.md` и `AGENTS.md` documentation map.
   - Deliverable: шаблон с полями: date, VM provider/type, Ubuntu version, kernel, resources, git commit, profile, commands run, pass/fail result, redacted notes, residual risks.
   - Expected behavior: evidence можно проверить без доступа к secrets и без raw `.env` dumps.
   - Logging/reporting: фиксировать только команды, exit status и sanitized observations; не выводить passwords, tokens, private keys, contents of `docker-compose/.env`.
   - Dependencies: нет.

2. [x] Определить mandatory и optional profile matrix для первого smoke-test PR.
   - Files: `docs/16-ubuntu-24-04-smoke-test-evidence.md`, `docs/12-quality-checks.md`, `docs/14-ready-rules.md`.
   - Deliverable: явно разделить обязательные для первого PR профили (`minimal`, `docker-host`) и resource-dependent профиль (`ai-stack`), если VM подходит по требованиям.
   - Expected behavior: если `ai-stack` не прогнан из-за ресурсов или отсутствия VM, документ фиксирует blocker/skip reason и не меняет release readiness на completed.
   - Logging/reporting: записывать причину skip как факт, без домыслов и без production claims.
   - Dependencies: Task 1.

### Phase 2: Clean VM Execution Evidence

3. [x] Собрать clean VM evidence для `minimal` profile.
   - Files: `docs/16-ubuntu-24-04-smoke-test-evidence.md`.
   - Deliverable: выполнить на чистой Ubuntu 24.04 LTS VM documented flow: preflight, SSH key setup path note, security baseline, ready checks; зафиксировать результат.
   - Expected behavior: `minimal` flow не требует Docker, compose или `.env`; ready checks проходят либо failure документирован с причиной и follow-up.
   - Logging/reporting: сохранить sanitized command transcript summary, timestamps, profile name, exit status; не включать IP, private keys, generated secrets или полный firewall dump с чувствительными адресами.
   - Dependencies: Tasks 1-2.

4. [x] Собрать clean VM evidence для `docker-host` profile.
   - Files: `docs/16-ubuntu-24-04-smoke-test-evidence.md`.
   - Deliverable: выполнить на чистой Ubuntu 24.04 LTS VM documented flow: preflight, security baseline, Docker install, ready checks, `docker --version`, `docker compose version`.
   - Current status 2026-07-12: forced installation-only check passed on `fi-1` after operator override; preflight still classified profile as `NO` because RAM/disk are below requirements.
   - Expected behavior: Docker Engine и Compose plugin устанавливаются через documented path; ready checks проходят либо failure документирован с причиной и follow-up.
   - Logging/reporting: фиксировать versions и exit status; не запускать unrelated workloads; не публиковать Docker API наружу.
   - Dependencies: Tasks 1-2.

5. [x] Собрать или явно отложить clean VM evidence для `ai-stack` profile.
   - Files: `docs/16-ubuntu-24-04-smoke-test-evidence.md`, возможно `PLAN.md`.
   - Deliverable: если VM соответствует `ai-stack` requirements, выполнить documented flow с generated local secrets, compose config/up, ready checks и service smoke checks. Если VM не соответствует, зафиксировать `not run` с ресурсной причиной и оставить blocker открытым.
   - Current status 2026-07-12: not run on `fi-1`; VPS is below `ai-stack` requirements.
   - Expected behavior: `ai-stack` не получает completed/release-ready статус без фактического успешного прогона; public direct Compose exposure не используется.
   - Logging/reporting: не выводить `.env`; фиксировать только sanitized service status, health summary и failures.
   - Dependencies: Tasks 1-2, ideally after Task 4.

### Phase 3: Docs And Status Sync

6. [x] Синхронизировать quality docs и acceptance criteria по фактам smoke-test.
   - Files: `docs/12-quality-checks.md`, `docs/14-ready-rules.md`, `docs/acceptance-criteria.md`, `docs/16-ubuntu-24-04-smoke-test-evidence.md`, возможно `README.md`/`AGENTS.md` links.
   - Deliverable: docs ссылаются на evidence document; ready rules ясно разделяют local static checks, profile ready checks и clean VM evidence.
   - Expected behavior: beginner-facing docs остаются понятными; README не превращается в длинный manual.
   - Logging/reporting: summary перечисляет только изменённые docs и подтверждённые profile results.
   - Dependencies: Tasks 3-5.

7. [x] Обновить `PLAN.md` только по подтверждённым результатам.
   - Files: `PLAN.md`.
   - Deliverable: изменить статус `Clean Ubuntu 24.04 VM smoke-test evidence` и related sections только для реально пройденных профилей; оставить blockers для непройденных или failed профилей.
   - Expected behavior: нет overclaim release readiness; статус отражает evidence, а не намерения.
   - Logging/reporting: в итоговом summary указать, какие статусы изменены и на какой evidence они ссылаются.
   - Dependencies: Tasks 3-6.

### Phase 4: Verification

8. [x] Запустить локальные quality gates после docs/status updates.
   - Files: changed docs and plan files.
   - Deliverable: `git diff --check`, `scripts/98-verify-scripts.sh`, `docker compose --env-file env.example -f docker-compose.yml -f docker-compose.monitoring.yml config`, targeted guards for `latest`, public override references and tracked secret-like files.
   - Expected behavior: static gates проходят; если gate падает, task остаётся incomplete до исправления.
   - Logging/reporting: фиксировать команды и pass/fail без secrets; полный compose output не должен раскрывать real `.env`.
   - Dependencies: Tasks 6-7.

## Acceptance Criteria

- Есть `docs/16-ubuntu-24-04-smoke-test-evidence.md` с sanitized evidence format и фактическими результатами или explicit blockers.
- `minimal` clean Ubuntu 24.04 VM result зафиксирован как pass/fail с командами и exit status.
- `docker-host` clean Ubuntu 24.04 VM result зафиксирован как pass/fail либо explicit not-run blocker с командами и exit status.
- `ai-stack` либо успешно прогнан на подходящей VM, либо явно оставлен blocker с причиной; completed status не ставится без успешного прогона.
- `docs/12-quality-checks.md`, `docs/14-ready-rules.md` и `docs/acceptance-criteria.md` не противоречат evidence.
- `PLAN.md` обновлён только по подтверждённым фактам.
- Secrets, private keys и generated `.env` contents не попали в docs, logs или git.
- Static gates после изменений проходят.

## Commit Plan

1. `docs: add ubuntu 24.04 smoke test evidence`
   - Tasks 1-5.
2. `docs: sync smoke test readiness status`
   - Tasks 6-8.

## Next Step

Нужна VM/VPS большего размера для оставшегося `docker-host` evidence. Минимум: 1024MB RAM и 10GB disk free; практически лучше 2GB RAM и 15GB+ disk.

## Verification Status

- Status: partially complete on 2026-07-12.
- Passed evidence: `minimal` clean Ubuntu 24.04 VPS smoke test.
- Remaining blocker: `ai-stack` was not run on `fi-1` because preflight classified the host as below requirements. `docker-host` passed only as a forced installation-only check and does not validate workload capacity.
- Local checks: `git diff --check`, `scripts/98-verify-scripts.sh`, Docker Compose base config, Docker Compose monitoring config, latest-image guard, removed public override guard and tracked secret-file guard passed.
- Note: `rg` is not installed locally, so targeted guards were run with `grep` matching the CI workflow.
