# Описание проекта install_ubuntu

## Обзор

`install_ubuntu` — Bash/Docker инфраструктурный starter kit для подготовки Ubuntu/VPS серверов по профилям. Проект покрывает preflight-классификацию, SSH и server hardening, установку Docker, запуск n8n, Supabase/PostgreSQL, Redis, pgvector, PgBouncer, monitoring, backups и profile-aware readiness checks.

## Назначение

- Подготовить чистый Ubuntu Server 22.04 LTS или 24.04 LTS к выбранному сценарию: `minimal`, `proxy`, `docker-host`, `web` или `ai-stack`.
- Дать повторяемый порядок установки через документацию, shell scripts и Docker Compose.
- Снизить риск небезопасных production-дефолтов за счёт обязательных secrets, локальных bind-address для внутренних сервисов и readiness checks.
- Поддержать маленькие VPS, proxy/VPN base, Docker host, dedicated server, internal lab и client deployment sandbox.

## Обнаруженный стек

- **Язык:** Bash.
- **Платформа:** Ubuntu Server 22.04 LTS / 24.04 LTS.
- **Контейнеризация:** Docker Engine, Docker Compose.
- **База данных:** PostgreSQL/Supabase, pgvector, PgBouncer.
- **Очереди и cache:** Redis.
- **Automation:** n8n main/worker.
- **Reverse proxy:** Nginx templates и документация SSL path.
- **Monitoring:** Prometheus, Grafana, node exporter через compose override.
- **Документация:** Markdown в `README.md`, `QUICKSTART.md`, `docs/`, `requirements/`.

## Основные компоненты

- `scripts/00-preflight-check.sh` — profile-aware проверка Ubuntu, ресурсов, Docker readiness и пригодности сервера до изменений.
- `scripts/01-setup-ssh-keys.sh` — подготовка SSH-ключей для GitHub, VPS/root, deploy и backup сценариев.
- `scripts/02-security-baseline.sh` — основной orchestrator базовой безопасности по профилю.
- `scripts/02-secure-server.sh` — deprecated compatibility wrapper для старого имени.
- `scripts/security/*.sh` — короткие functional modules для system updates, firewall, SSH hardening, fail2ban, unattended upgrades, sysctl, swap и audit.
- `scripts/03-install-docker.sh` — установка Docker Engine и Docker Compose для `docker-host`/`ai-stack`.
- `scripts/10-backup-postgres.sh` и `scripts/11-setup-backup-cron.sh` — backup/cron automation для PostgreSQL.
- `scripts/12-generate-secrets.sh` — создание `docker-compose/.env` из `env.example` без дефолтных production-паролей для `ai-stack`.
- `scripts/98-verify-scripts.sh` — локальная Bash/ShellCheck проверка first-party scripts.
- `scripts/99-ready-checks.sh` — profile-aware post-install readiness checks; minimal/proxy не требуют compose или `.env`.
- `docker-compose/docker-compose.yml` — основной stack Redis, Supabase/PostgreSQL, PgBouncer, Supabase Studio, n8n и n8n worker.

## Архитектурные заметки

- Репозиторий является infrastructure-as-code набором, а не приложением с runtime-кодом.
- Для `ai-stack` основной runtime orchestration слой — Docker Compose; для `minimal`/`proxy` основным результатом является host security baseline без Docker/compose.
- Shell scripts отвечают за подготовку host OS, security baseline, secrets, backups и verification; короткие modules живут в `scripts/security/`, top-level scripts остаются entry points.
- Внутренние сервисы по умолчанию привязаны к `127.0.0.1`; публичный доступ должен идти через явный Nginx/SSL path или SSH tunnel.
- Секреты не должны храниться в репозитории; рабочий `docker-compose/.env` генерируется локально и не должен выводиться в ответы или логи.
- Документация является частью delivery: порядок запуска скриптов, security notes и operational checks должны оставаться синхронизированы с compose/scripts.

## Архитектура

Подробные архитектурные рекомендации находятся в `.ai-factory/ARCHITECTURE.md`.

**Pattern:** Layered Architecture.

## Нефункциональные требования

- **Безопасность:** secure-by-default, обязательные secrets, закрытые внутренние порты, SSH hardening, firewall и fail2ban.
- **Повторяемость:** идемпотентные Bash-скрипты и единый порядок установки.
- **Наблюдаемость:** healthchecks, logs rotation, Prometheus/Grafana notes и readiness checks.
- **Backup-first:** PostgreSQL backup automation и документация restore path.
- **Проверяемость:** `bash -n`, optional ShellCheck, `docker compose config`, service health и smoke checks.
