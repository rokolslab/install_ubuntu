# AGENTS.md

> Карта проекта для AI-агентов и разработчиков. Обновляйте файл при существенных изменениях структуры репозитория.

## Обзор проекта

`install_ubuntu` подготавливает Ubuntu/VPS серверы по профилям: `minimal`, `proxy`, `docker-host`, `web` и `ai-stack`. Проект покрывает базовый security hardening маленьких VPS и полный self-hosted AI automation stack: Docker, n8n, Supabase/PostgreSQL, Redis, pgvector, monitoring, backups и readiness checks.

## Технологический стек

- **Язык:** Bash
- **Платформа:** Ubuntu Server 22.04 LTS / 24.04 LTS
- **Контейнеризация:** Docker, Docker Compose
- **База данных:** PostgreSQL/Supabase
- **Сервисы:** Redis, n8n, PgBouncer, Nginx, Prometheus, Grafana

## Структура проекта

```text
.
├── scripts/              # Bash-скрипты установки, security hardening, backup и проверок
│   ├── lib/              # Короткие shared helpers для scripts
│   └── security/         # Малые functional security modules
├── docker-compose/       # Compose stack, env template, Supabase и monitoring config
├── docs/                 # Подробная документация по компонентам и эксплуатации
├── requirements/         # Системные требования и совместимость
├── templates/            # Примеры Nginx и firewall конфигураций
├── .ai-factory/          # AI Factory контекст, правила, архитектура и планы
├── README.md             # Главная landing page проекта
├── QUICKSTART.md         # Пошаговый быстрый старт
└── PLAN.md               # Roadmap и quality-gate tracker
```

## Ключевые точки входа

| Файл | Назначение |
|------|------------|
| `README.md` | Обзор проекта, сценарии использования и карта документации. |
| `QUICKSTART.md` | Короткие profile-aware пути установки от чистого сервера. |
| `scripts/00-preflight-check.sh` | Profile-aware проверка сервера и классификация пригодности. |
| `scripts/02-security-baseline.sh` | Основной orchestrator security baseline по профилю. |
| `scripts/02-secure-server.sh` | Deprecated compatibility wrapper для старого имени. |
| `scripts/security/*.sh` | Короткие functional modules: firewall, SSH hardening, fail2ban, swap, audit. |
| `scripts/98-verify-scripts.sh` | Локальная проверка Bash-скриптов. |
| `scripts/99-ready-checks.sh` | Profile-aware readiness checks после выбранного install flow. |
| `docker-compose/docker-compose.yml` | Основной Compose stack. |
| `docker-compose/env.example` | Шаблон обязательных переменных окружения и secrets. |

## Документация

| Документ | Путь | Описание |
|----------|------|----------|
| README | `README.md` | Главный обзор проекта. |
| Quick Start | `QUICKSTART.md` | Краткая инструкция установки. |
| VPS Profiles | `docs/profiles.md` | Профили minimal/proxy/docker-host/web/ai-stack. |
| Scripts Catalog | `docs/scripts-catalog.md` | Назначение каждого script и profile flows. |
| SSH Keys | `docs/ssh-keys.md` | Сценарии SSH-ключей для GitHub, VPS/root, deploy и backup доступа. |
| Architecture | `docs/architecture.md` | Runtime-компоненты и data flow. |
| Operations | `docs/architecture-operations.md` | Масштабирование, backup и performance notes. |
| Scripts Order | `docs/15-scripts-order.md` | Канонический порядок запуска скриптов. |
| System Requirements | `requirements/system-requirements.md` | Требования к серверу. |

## AI Context Files

| Файл | Назначение |
|------|------------|
| `AGENTS.md` | Быстрая карта проекта для AI-агентов. |
| `.ai-factory/config.yaml` | Настройки AI Factory для языка, путей, workflow и git. |
| `.ai-factory/DESCRIPTION.md` | Сводное описание проекта и обнаруженного стека. |
| `.ai-factory/rules/base.md` | Базовые правила и конвенции проекта. |
| `.ai-factory/ARCHITECTURE.md` | Архитектурные рекомендации AI Factory. |
| `.ai-factory/PLAN.md` | Текущий рабочий план AI Factory, если используется. |

## Правила для агентов

- Не объединяйте потенциально опасные shell-команды в одну строку, если безопаснее выполнить их по шагам.
- Неправильно: `git checkout main && git pull`.
- Правильно: сначала `git checkout main`, затем `git pull origin main`.
- Не запускайте scripts с `sudo` без понимания их назначения и соответствующей документации.
- Не выводите secrets из `docker-compose/.env` в ответы, логи или отчёты.
- Новые shell scripts должны быть короткими functional scripts: один script — одна понятная функция; orchestration допускается только в top-level wrapper.
- Для `proxy`/x-ui не открывайте service ports автоматически; используйте явный `--allow-port <port>` или документированное ручное правило.
