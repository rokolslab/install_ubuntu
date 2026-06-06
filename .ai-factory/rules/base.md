# Базовые правила проекта

> Автоматически определённые конвенции из текущего Bash/Docker репозитория. Обновляйте файл при изменении практик проекта.

## Именование

- Файлы shell scripts: числовой префикс порядка выполнения и kebab-case, например `00-preflight-check.sh`, `99-ready-checks.sh`.
- Документация: Markdown-файлы в kebab-case для тематических docs, например `01-server-security.md`, `15-scripts-order.md`.
- Bash переменные: `UPPER_SNAKE_CASE` для глобальных путей и конфигурации, `lower_snake_case` для локальных параметров функций.
- Bash функции: `lower_snake_case`, например `log_info`, `log_warn`, `log_error`.
- Compose service names: snake_case или kebab-case согласно фактическим service identifiers, например `supabase_db`, `n8n-worker`.

## Структура модулей

- `scripts/` содержит first-party Bash automation для установки, security hardening, backup и checks.
- `scripts/lib/` содержит короткие shared helpers; не превращайте его в сложный Bash framework.
- `scripts/security/` содержит короткие functional security modules, где один script отвечает за одну понятную функцию.
- `docker-compose/` содержит основной compose stack, overrides, env template и service config.
- `docs/` содержит эксплуатационную и компонентную документацию.
- `requirements/` содержит системные требования и compatibility constraints.
- `templates/` содержит примеры Nginx/firewall конфигураций.
- `.ai-factory/` содержит AI Factory контекст, планы, правила и архитектурные рекомендации.

## Bash-стиль

- Новые shell scripts должны начинаться с shebang `#!/bin/bash` и использовать `set -Eeuo pipefail`, если нет причины выбрать более мягкий режим.
- Для критичных scripts используйте `trap` с диагностикой строки и команды, как в `98-verify-scripts.sh` и `99-ready-checks.sh`.
- Пути вычисляйте относительно `SCRIPT_DIR`/`PROJECT_ROOT`, а не относительно текущей директории запуска.
- Значения переменных и путей всегда заключайте в кавычки.
- Не запускайте destructive или privileged операции без явных проверок и понятного сообщения пользователю.
- Не создавайте многостраничные shell scripts без необходимости; если функциональность разнородная, разделяйте её на короткие modules и thin top-level orchestrator.

## Обработка ошибок

- Для fatal-состояний используйте `log_error` и `exit 1`.
- Для необязательных зависимостей используйте `log_warn` и продолжайте только если это безопасно.
- Для команд, которые допустимо пропустить при сборе диагностики, явно используйте `|| true`.
- Readiness checks должны падать на обязательных сервисах и переменных, но предупреждать по optional monitoring сервисам.
- Profile-aware scripts должны отличать `minimal`, `proxy`, `docker-host`, `web` и `ai-stack`; `minimal`/`proxy` не должны требовать Docker, compose или `.env`.

## Логирование

- Используйте функции `log_info`, `log_warn`, `log_error` с цветными префиксами `[INFO]`, `[WARN]`, `[ERROR]`.
- Не выводите значения secrets из `docker-compose/.env`.
- В документации показывайте placeholder-переменные, а не реальные секреты.

## Проверки качества

- Для shell scripts запускайте `scripts/98-verify-scripts.sh`.
- Для compose изменений проверяйте `docker compose config` из `docker-compose/`.
- Для post-install verification используйте `scripts/99-ready-checks.sh --profile <profile>` на целевом сервере; `.env` требуется только для `ai-stack` checks.
- Не запускайте scripts с `sudo` без понимания их назначения и соответствующей документации.
- Для proxy/x-ui не открывайте service ports автоматически; используйте явный `--allow-port <port>` или документированное ручное правило.
