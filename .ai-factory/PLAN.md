# Implementation Plan: Унификация проекта под разные типы VPS

Branch: main
Created: 2026-06-06
Refined: 2026-06-06

## Settings

- Testing: yes — проверять Bash syntax, ShellCheck при наличии, `docker compose config` только для `ai-stack`.
- Logging: standard — короткие `[INFO]`, `[WARN]`, `[ERROR]`; без debug-простыней и без вывода secrets.
- Docs: yes — обновить quick paths, profiles, requirements и каталог scripts.
- Roadmap Linkage: none — linkage не выбирался пользователем.

## Plan Refinement Report

План доработан после проверки текущей структуры `scripts/` и документации.

Найденные проблемы:

- В исходном плане были конфликтующие имена `03-firewall-config.sh`, `04-ssh-hardening.sh`, `07-setup-swap.sh`, потому что эти номера уже заняты текущими top-level scripts.
- Не хватало явной карты “какой script что делает”, а пользователь должен понимать назначение каждого script до запуска.
- Не была описана backward compatibility стратегия для текущего `scripts/02-secure-server.sh`.
- `scripts/98-verify-scripts.sh` сейчас проверяет только `scripts/*.sh`; при добавлении подкаталогов его нужно обновить.
- Не хватало acceptance criteria для UX: preflight должен давать понятный вывод “подходит для ... / не подходит для ...”.

Принятые улучшения:

- Новые мелкие security-модули размещаются в `scripts/security/`, чтобы не ломать историческую нумерацию.
- Top-level scripts остаются понятными entry points.
- Добавлен Script Responsibility Matrix.
- Добавлены задачи для migration wrappers, UX вывода preflight и recursive verification.

## Goal

Сделать проект универсальным bootstrap/security набором для разных VPS, включая маленькие серверы `1 vCPU / 512MB-1GB RAM`, не ломая текущий AI automation stack.

Главный принцип: **короткие функциональные scripts + профили назначения сервера**.

Preflight должен не отбраковывать слабый сервер по требованиям AI stack, а классифицировать его:

```text
Сервер подходит для: minimal, proxy
С ограничениями: docker-host
Не подходит для: ai-stack
```

## Constraints

- Не превращать scripts в многостраничные простыни.
- Один функциональный script должен делать одну понятную функцию.
- Top-level wrapper может вызывать несколько коротких scripts, но сам не должен содержать всю реализацию.
- Общая логика допускается только в маленьких helpers, без сложного Bash framework.
- Безопасность должна быть общей базой, но опасные решения требуют явного условия или предупреждения.
- Текущий AI stack должен остаться доступен как отдельный профиль, а не как дефолт для всех серверов.
- Не переиспользовать уже занятые номера top-level scripts для новых задач.

## Target Profiles

| Profile | Назначение | Минимум | Что включает |
|---|---|---:|---|
| `minimal` | Базовая безопасность маленького VPS | 512MB RAM, 5GB disk | SSH, UFW, fail2ban, updates, audit |
| `proxy` | x-ui/3x-ui/VPN/proxy panel | 512MB-1GB RAM, 10GB disk | `minimal` + explicit service ports + optional swap |
| `docker-host` | Маленький Docker host | 1GB RAM, 10GB disk | `minimal` + Docker install/hardening |
| `web` | Небольшой web/app VPS | 1-2GB RAM, 15GB disk | `minimal` + 80/443 + optional Nginx/Caddy |
| `ai-stack` | Текущий n8n/Supabase/Redis stack | 4GB RAM, 50GB disk | Docker Compose stack, secrets, ready checks |

## Script Responsibility Matrix

Top-level entry points:

| Script | Назначение | Профили | Пользовательский смысл |
|---|---|---|---|
| `scripts/00-preflight-check.sh` | Анализ ресурсов, OS, ports, Docker readiness и классификация профилей | all | “Для чего подходит этот сервер?” |
| `scripts/01-setup-ssh-keys.sh` | Подготовка SSH keys на клиентской машине | all | “Как безопасно зайти на сервер?” |
| `scripts/02-security-baseline.sh` | Короткий orchestrator базовой безопасности | `minimal`, `proxy`, `docker-host`, `web`, `ai-stack` | “Привести безопасность сервера в порядок” |
| `scripts/02-secure-server.sh` | Compatibility wrapper для старого имени | all | “Старый путь, который объясняет новый” |
| `scripts/03-install-docker.sh` | Установка Docker/Compose | `docker-host`, `ai-stack` | “Подготовить сервер под контейнеры” |
| `scripts/04-setup-supabase.sh` | Supabase/PostgreSQL setup | `ai-stack` | “Компонент AI stack” |
| `scripts/05-setup-n8n.sh` | n8n setup | `ai-stack` | “Компонент AI automation” |
| `scripts/06-setup-redis.sh` | Redis setup | `ai-stack` | “Очередь/cache для AI stack” |
| `scripts/07-setup-vector-db.sh` | pgvector setup | `ai-stack` | “Vector DB для RAG” |
| `scripts/08-setup-nginx.sh` | Nginx setup | `web`, `ai-stack`, optional `proxy` | “Reverse proxy/HTTPS path” |
| `scripts/09-install-nvidia-drivers.sh` | NVIDIA drivers | optional | “GPU support, не для маленького VPS по умолчанию” |
| `scripts/10-backup-postgres.sh` | PostgreSQL backup | `ai-stack` | “Бэкап DB” |
| `scripts/11-setup-backup-cron.sh` | Backup cron | `ai-stack` | “Автоматизация DB backups” |
| `scripts/12-generate-secrets.sh` | `.env` secrets для compose stack | `ai-stack` | “Secrets для AI stack, не для minimal” |
| `scripts/98-verify-scripts.sh` | Локальная проверка first-party scripts | dev | “Проверить Bash scripts без sudo” |
| `scripts/99-ready-checks.sh` | Profile-aware readiness checks | all | “Проверить результат выбранного профиля” |

Short security modules under `scripts/security/`:

| Script | Делает | Не делает |
|---|---|---|
| `scripts/security/system-updates.sh` | `apt update`, safe upgrade policy, autoremove при необходимости | Не ставит Docker и не меняет SSH |
| `scripts/security/firewall.sh` | UFW default deny, SSH allow, profile/explicit ports | Не открывает `80/443` всем подряд |
| `scripts/security/ssh-hardening.sh` | backup sshd config, safe options, `sshd -t`, rollback | Не отключает доступ без проверки/подтверждения |
| `scripts/security/fail2ban.sh` | Установка и минимальная sshd jail config | Не перетирает сложную custom config без backup |
| `scripts/security/unattended-upgrades.sh` | Security auto-updates | Не делает full dist policy для всех случаев |
| `scripts/security/sysctl-hardening.sh` | Базовые network sysctl hardening settings | Не включает routing/VPN tuning |
| `scripts/security/swap.sh` | Idempotent swapfile для малых VPS | Не пересоздаёт существующий swap без явного флага |
| `scripts/security/audit.sh` | Краткий отчёт: ports, services, UFW, fail2ban, SSH | Не меняет систему |

## Profile Flows

Minimal VPS:

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

Proxy/x-ui VPS:

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile proxy --allow-port <ssh-or-service-port>
sudo bash scripts/99-ready-checks.sh --profile proxy
```

Docker host:

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile docker-host
sudo bash scripts/03-install-docker.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile docker-host
```

Web/app VPS:

```bash
sudo bash scripts/00-preflight-check.sh --profile web
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile web
sudo bash scripts/08-setup-nginx.sh
sudo bash scripts/99-ready-checks.sh --profile web
```

AI stack:

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile ai-stack
sudo bash scripts/03-install-docker.sh --profile ai-stack
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
sudo bash scripts/99-ready-checks.sh --profile ai-stack
```

## Design Decisions

- `00-preflight-check.sh` становится profile-aware и выдаёт рекомендации вместо жёсткого отказа при 1GB RAM.
- Текущий `02-secure-server.sh` не расширяется дальше; он становится compatibility wrapper или deprecated entry point.
- Новая реализация безопасности живёт в коротких modules `scripts/security/*.sh`.
- `02-security-baseline.sh` является orchestrator: вызывает нужные `scripts/security/*.sh` по профилю.
- `80/443` не открываются по умолчанию для всех; они зависят от профиля или явного `--allow-port`.
- `PermitRootLogin no` и `PasswordAuthentication no` применяются только если есть безопасный путь не потерять доступ.
- Swap нужен как отдельный короткий script для маленьких VPS.
- Docker и AI stack не являются частью minimal security baseline.

## Tasks

### Phase 1: Profiles, UX And Preflight

- [x] **Task 1: Добавить маленький общий helper без Bash framework**
  - Files: `scripts/lib/common.sh`.
  - Deliverable: создать helper с `log_info`, `log_warn`, `log_error`, `require_root`, `detect_os`, `detect_resources`, `parse_profile`, `print_profile_summary`.
  - Scope limit: файл должен оставаться коротким; не добавлять generic plugin system или сложный argument parser.
  - Logging requirements: `log_info` для выбранного профиля и обнаруженных ресурсов; `log_warn` для unknown profile; не логировать secrets.
  - Dependencies: none.

- [x] **Task 2: Переделать preflight в классификатор пригодности сервера**
  - Files: `scripts/00-preflight-check.sh`.
  - Deliverable: добавить `--profile minimal|proxy|docker-host|web|ai-stack`; без `--profile` выводить список подходящих/неподходящих профилей.
  - Behavior: `1GB RAM` не fatal; fatal только для реально невозможных условий вроде неподдерживаемой OS, отсутствия root для system checks, критически малого диска.
  - Output: краткая таблица `OK / WARN / NO` по профилям и рекомендации вроде “включить swap”, “не запускать ai-stack”.
  - Logging requirements: `log_info` для ресурсов, `log_warn` для ограничений, `log_error` только для fatal blockers.
  - Dependencies: Task 1.

- [x] **Task 3: Добавить каталог scripts для пользователя**
  - Files: `docs/scripts-catalog.md`, `docs/15-scripts-order.md`, `README.md`.
  - Deliverable: документ с таблицей “script / что делает / для каких профилей / когда запускать / что не делает”.
  - User requirement: после чтения пользователь должен понимать назначение каждого script без открытия кода.
  - Logging requirements: не применимо к docs; examples не должны содержать secrets.
  - Dependencies: Task 2.

- [x] **Task 4: Обновить requirements под профили**
  - Files: `requirements/system-requirements.md`, `docs/profiles.md`.
  - Deliverable: заменить единые требования `4GB/50GB` на таблицу профилей; зафиксировать, что `4GB/50GB` относится к `ai-stack`.
  - Logging requirements: не применимо к docs; документ должен описывать уровни `fatal/warn/info` из preflight.
  - Dependencies: Task 2.

### Phase 2: Short Security Modules

- [x] **Task 5: Создать security modules без конфликтов нумерации**
  - Files: `scripts/security/system-updates.sh`, `scripts/security/firewall.sh`, `scripts/security/ssh-hardening.sh`, `scripts/security/fail2ban.sh`, `scripts/security/unattended-upgrades.sh`, `scripts/security/sysctl-hardening.sh`, `scripts/security/audit.sh`.
  - Deliverable: вынести из текущего `scripts/02-secure-server.sh` функциональные блоки в короткие scripts под `scripts/security/`.
  - Scope limit: каждый module делает одну функцию; не добавлять multi-page scripts.
  - Logging requirements: каждый module логирует старт, ключевые изменения и итог; warnings для действий, которые могут повлиять на доступ по SSH.
  - Dependencies: Task 1.

- [x] **Task 6: Добавить `scripts/02-security-baseline.sh` как понятный orchestrator**
  - Files: `scripts/02-security-baseline.sh`.
  - Deliverable: короткий top-level script, который по `--profile` вызывает нужные `scripts/security/*.sh`.
  - Behavior: `minimal` не ставит Docker, Nginx, Supabase, Redis, n8n; `ai-stack` включает только security baseline, а не поднимает compose.
  - Logging requirements: `log_info` перед вызовом каждого module; `log_warn` для пропущенных optional modules; `log_error` если обязательный module падает.
  - Dependencies: Task 5.

- [x] **Task 7: Сделать firewall profile-aware и явным для proxy/x-ui**
  - Files: `scripts/security/firewall.sh`, `templates/firewall-rules.example`, `docs/profiles.md`, `docs/scripts-catalog.md`.
  - Deliverable: UFW default deny incoming; SSH порт всегда сохраняется; `80/443` открываются только для `web`/`ai-stack` или явного флага.
  - Proxy profile: не открывать x-ui порты автоматически; требовать `--allow-port <port>` или печатать команды для ручного открытия.
  - Logging requirements: `log_info` для открытых портов, `log_warn` если профиль требует ручного выбора портов, `log_error` если SSH port не определён.
  - Dependencies: Task 5.

- [x] **Task 8: Сделать SSH hardening безопасным от потери доступа**
  - Files: `scripts/security/ssh-hardening.sh`, `docs/01-server-security.md`, `docs/ssh-keys.md`.
  - Deliverable: backup `sshd_config`, `sshd -t`, restart rollback on failure; `PermitRootLogin no` и `PasswordAuthentication no` применять только после проверки/подтверждения key-based доступа.
  - Scope limit: не добавлять интерактивный wizard на сотни строк; если не хватает данных, печатать понятный warning и пропускать опасный шаг.
  - Logging requirements: `log_warn` перед отключением root/password login, `log_error` при невалидном sshd config, `log_info` при backup/rollback.
  - Dependencies: Task 5.

- [x] **Task 9: Добавить swap как отдельный optional module для маленьких VPS**
  - Files: `scripts/security/swap.sh`, `docs/profiles.md`, `docs/scripts-catalog.md`.
  - Deliverable: idempotent swapfile module для `minimal`, `proxy`, `docker-host` при малой RAM.
  - Behavior: если swap уже есть, только показать статус; не пересоздавать без явного флага.
  - Logging requirements: `log_info` для текущего swap status, `log_warn` если RAM мала и swap отсутствует, `log_error` если недостаточно диска.
  - Dependencies: Task 2, Task 5.

### Phase 3: Compatibility And Heavy Stack Separation

- [x] **Task 10: Сохранить старый `02-secure-server.sh` как compatibility wrapper**
  - Files: `scripts/02-secure-server.sh`, `docs/15-scripts-order.md`.
  - Deliverable: старый script должен ясно сообщать, что новый entry point — `scripts/02-security-baseline.sh`, и вызывать его с безопасным default profile или просить указать профиль.
  - Behavior: не оставлять старую многостраничную реализацию как основной путь.
  - Logging requirements: `log_warn` о deprecated wrapper, `log_info` о вызове нового script, `log_error` если профиль не указан и default небезопасен.
  - Dependencies: Task 6.

- [x] **Task 11: Отделить heavy stack шаги от minimal/security flow**
  - Files: `scripts/03-install-docker.sh`, `scripts/12-generate-secrets.sh`, `scripts/99-ready-checks.sh`, `docs/15-scripts-order.md`, `docs/scripts-catalog.md`.
  - Deliverable: явно отметить Docker, secrets, compose up и ready checks как `ai-stack` или `docker-host` steps, а не обязательные шаги minimal VPS.
  - Minimal change: не переписывать Docker installer полностью; добавить profile checks/warnings и документацию.
  - Logging requirements: `log_warn` если пользователь запускает AI stack steps на сервере, который preflight классифицирует как неподходящий.
  - Dependencies: Task 2, Task 4.

- [x] **Task 12: Сделать ready checks profile-aware**
  - Files: `scripts/99-ready-checks.sh`.
  - Deliverable: `--profile minimal|proxy|docker-host|web|ai-stack`; для `minimal` проверять SSH/UFW/fail2ban/updates/swap; для `ai-stack` оставить compose/service checks.
  - Scope limit: не делать огромный универсальный healthcheck; маленькие функции и `case "$PROFILE"`.
  - Logging requirements: `log_info` для пройденных проверок, `log_warn` для optional checks, `log_error` для обязательных failed checks профиля.
  - Dependencies: Task 6, Task 11.

### Phase 4: Documentation And Entry Points

- [x] **Task 13: Разделить Quick Start на понятные пути установки**
  - Files: `README.md`, `QUICKSTART.md`, `docs/15-scripts-order.md`, `docs/profiles.md`, `docs/scripts-catalog.md`.
  - Deliverable: добавить короткие сценарии: `Minimal VPS hardening`, `Proxy/x-ui VPS`, `Docker host`, `AI automation stack`.
  - User requirement: каждый сценарий должен показывать только нужные scripts и не тащить AI stack в minimal/proxy.
  - Scope limit: README остаётся landing page; подробности уходят в `docs/profiles.md` и `docs/scripts-catalog.md`.
  - Logging requirements: не применимо к docs; docs должны показывать ожидаемые предупреждения preflight.
  - Dependencies: Task 3, Task 4, Task 11, Task 12.

- [x] **Task 14: Обновить AI context после новой структуры**
  - Files: `AGENTS.md`, `.ai-factory/rules/base.md`, `.ai-factory/DESCRIPTION.md`, `.ai-factory/ARCHITECTURE.md`.
  - Deliverable: отразить profile-aware architecture, `scripts/security/`, compatibility wrapper и правило “короткий script = одна функция”.
  - Logging requirements: не применимо к docs; правила должны явно запрещать многостраничные scripts без необходимости.
  - Dependencies: Task 10, Task 13.

### Phase 5: Verification

- [x] **Task 15: Обновить verification под subdirectories**
  - Files: `scripts/98-verify-scripts.sh`.
  - Deliverable: проверять top-level `scripts/*.sh` и новые `scripts/security/*.sh` без запуска privileged setup logic.
  - Behavior: если `scripts/security/` ещё не существует, verification не должен падать.
  - Logging requirements: verification script логирует только статусы проверок, без secrets и без запуска destructive setup scripts.
  - Dependencies: Task 5.

- [x] **Task 16: Проверить Bash и документационную согласованность**
  - Files: all changed `scripts/**/*.sh`, `README.md`, `QUICKSTART.md`, `docs/15-scripts-order.md`, `docs/profiles.md`, `docs/scripts-catalog.md`, `requirements/system-requirements.md`.
  - Deliverable: `bash scripts/98-verify-scripts.sh` проходит; при наличии ShellCheck нет новых критичных предупреждений; docs не противоречат profile flows.
  - Add checks: убедиться, что старые команды либо работают через wrapper, либо явно заменены в docs.
  - Logging requirements: итоговая проверка должна выводить compact summary по профилям и scripts.
  - Dependencies: Task 1-15.

## Commit Plan

- **Commit 1** (after tasks 1-4): `feat: add profile-aware preflight and docs catalog`
- **Commit 2** (after tasks 5-9): `feat: split security baseline into focused modules`
- **Commit 3** (after tasks 10-12): `feat: separate compatibility and profile readiness flows`
- **Commit 4** (after tasks 13-16): `docs: document vps profiles and script responsibilities`

## Acceptance Criteria

- Пользователь видит, какой script что делает, до запуска privileged команд.
- `1 vCPU / 1GB RAM` классифицируется как подходящий минимум для `minimal`/`proxy`, но не для `ai-stack`.
- `minimal` flow не требует Docker, Supabase, Redis, n8n, monitoring или `.env`.
- `proxy` flow не открывает service ports автоматически без явного `--allow-port` или ручной команды.
- `ai-stack` сохраняет текущий тяжёлый сценарий, но больше не выглядит дефолтом для всех VPS.
- Старый `scripts/02-secure-server.sh` не исчезает без объяснения и не ломает существующие ссылки молча.
- Новые security modules не конфликтуют с исторической нумерацией top-level scripts.
- `scripts/98-verify-scripts.sh` проверяет новые subdirectory scripts.
- Документация `README.md`, `QUICKSTART.md`, `docs/15-scripts-order.md`, `docs/profiles.md` и `docs/scripts-catalog.md` согласована.

## Implementation Notes

- Предпочесть маленькие `case "$PROFILE"` блоки вместо абстрактной системы plugins.
- Не удалять старые scripts резко, если проще оставить thin wrapper с warning и вызовом новых scripts.
- Для destructive действий использовать подтверждение или безопасный пропуск с warning.
- Не запускать setup scripts с `sudo` во время разработки; проверять синтаксис локально.
- Не добавлять auto-install x-ui/3x-ui в рамках этой унификации; профиль `proxy` только готовит безопасную базу и firewall policy.
