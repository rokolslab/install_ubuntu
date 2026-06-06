# Architecture: Layered Architecture

## Обзор

Для `install_ubuntu` выбрана простая Layered Architecture, адаптированная под infrastructure-as-code репозиторий. Здесь нет application runtime с controllers/services/repositories; вместо этого архитектурные слои задаются назначением артефактов: документация описывает contract, profile-aware scripts выполняют host automation, Docker Compose описывает runtime stack для `ai-stack`, templates дают reusable edge-конфигурации, а checks проверяют готовность выбранного профиля.

Выбор сделан потому, что проект должен оставаться понятным, проверяемым и безопасным для запуска на реальных Ubuntu/VPS серверах. Более формальные подходы вроде Explicit Architecture или Microservices были бы избыточны для Bash/Docker bootstrap repo.

## Обоснование решения

- **Тип проекта:** infrastructure starter kit для Ubuntu/VPS и self-hosted AI automation.
- **Tech stack:** Bash, Docker Compose, Markdown, Ubuntu Server.
- **Ключевой фактор:** безопасность и повторяемость важнее сложного domain modeling.
- **Размер и сложность:** небольшой/средний репозиторий с линейным install flow и отдельными operational компонентами.

## Структура слоёв

```text
install_ubuntu/
├── README.md                 # Landing page и карта документации
├── QUICKSTART.md             # Profile-aware пользовательские installation flows
├── PLAN.md                   # Roadmap и quality-gate tracker
├── AGENTS.md                 # Карта проекта для AI-агентов
├── requirements/             # System requirements и compatibility constraints
├── docs/                     # Подробная документация и operational contract
├── scripts/                  # Host automation, hardening, backup, checks
│   ├── lib/                  # Shared Bash helpers без framework
│   └── security/             # Короткие functional security modules
├── docker-compose/           # Runtime stack, env template, monitoring config
├── templates/                # Reusable Nginx/firewall examples
└── .ai-factory/              # AI Factory context, rules, plans, architecture
```

## Dependency Rules

- Разрешено: `README.md` и `QUICKSTART.md` ссылаются на подробные `docs/` страницы.
- Разрешено: `docs/` описывает поведение `scripts/`, `docker-compose/` и `templates/`.
- Разрешено: `scripts/` вычисляют пути через `SCRIPT_DIR`/`PROJECT_ROOT` и обращаются к `docker-compose/` только через явные файлы/команды.
- Разрешено: top-level scripts orchestrate короткие modules, если сами остаются thin entry points.
- Разрешено: readiness/verification scripts проверяют результат compose stack, но не должны скрыто менять production state сверх своей заявленной задачи.
- Запрещено: превращать functional security modules в многостраничные installers с несколькими несвязанными обязанностями.
- Запрещено: scripts зависят от текущей директории запуска вместо `PROJECT_ROOT`.
- Запрещено: документация рекомендует порядок команд, который расходится с `docs/15-scripts-order.md` и фактическими scripts.
- Запрещено: реальные secrets из `docker-compose/.env` попадают в docs, logs, AI responses или tracked files.
- Запрещено: внутренние сервисы открываются наружу без явного override/template и документации по рискам.

## Коммуникация между слоями

- Пользовательский flow начинается в `README.md` или `QUICKSTART.md`, затем уводит в тематические `docs/` страницы.
- `docs/15-scripts-order.md` является каноническим описанием порядка запуска scripts.
- `scripts/02-security-baseline.sh` вызывает короткие `scripts/security/*.sh` modules по выбранному профилю.
- `scripts/12-generate-secrets.sh` создаёт локальный `docker-compose/.env` только для `ai-stack`; compose stack потребляет только переменные окружения и не хранит secrets в YAML.
- `scripts/99-ready-checks.sh` валидирует результат выбранного профиля; compose config, сервисы и smoke checks обязательны только для `ai-stack`.
- `templates/` используются как примеры для edge-конфигурации и не должны автоматически применяться без явного действия пользователя.

## Ключевые принципы

1. **Documentation as contract:** инструкции, порядок запуска и safety notes должны отражать фактическое поведение scripts и compose.
2. **Secure by default:** обязательные secrets, локальные bind-address, firewall/hardening и явный public access path.
3. **Idempotent automation:** scripts должны безопасно переносить повторный запуск или явно объяснять, почему повторный запуск опасен.
4. **Verification first:** изменения scripts и compose должны сопровождаться проверками `bash -n`, ShellCheck при наличии и `docker compose config`.
5. **No hidden state leaks:** `.env`, пароли, tokens и generated secrets не выводятся в отчёты и не коммитятся.
6. **Profile separation:** `minimal`/`proxy` не должны тянуть Docker, compose или AI stack requirements; `ai-stack` остаётся явным тяжёлым профилем.

## Code Examples

### Корректное вычисление путей в Bash

```bash
#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$PROJECT_ROOT/docker-compose"
```

### Проверка обязательного локального файла без вывода secrets

```bash
ENV_FILE="$PROJECT_ROOT/docker-compose/.env"

if [ ! -f "$ENV_FILE" ]; then
  log_error "Файл .env не найден: $ENV_FILE"
  exit 1
fi
```

### Compose service с закрытым портом и обязательным secret

```yaml
services:
  redis:
    image: redis:7.4.7-alpine
    ports:
      - "127.0.0.1:6379:6379"
    command: redis-server --requirepass ${REDIS_PASSWORD:?REDIS_PASSWORD is required}
```

## Anti-Patterns

- Не добавлять one-command installer, который скрывает security-critical шаги от пользователя.
- Не смешивать minimal hardening, proxy firewall policy, Docker install и AI stack compose в один обязательный flow.
- Не объединять потенциально опасные команды в одну строку, если безопаснее выполнить их по шагам.
- Не открывать proxy/x-ui service ports автоматически без явного `--allow-port` или ручного документированного правила.
- Не использовать `latest` для production compose images.
- Не добавлять дефолтные production-пароли или реальные secrets в tracked files.
- Не открывать PostgreSQL, Redis, Supabase Studio, n8n или monitoring наружу без явного reverse proxy/firewall решения.
- Не делать scripts зависимыми от интерактивного shell state, текущей директории или неописанных внешних переменных.
- Не дублировать подробные инструкции в README, если они уже живут в `docs/`; README должен оставаться landing page.
