[← Troubleshooting](11-troubleshooting.md) · [Back to README](../README.md) · [Secrets →](13-secrets.md)

# Контроль качества и проверка установки

Этот чек‑лист помогает проверить корректность конфигурации и работоспособность инфраструктуры.

## 1. Проверка конфигурации Docker Compose
```bash
cd docker-compose
docker compose config
```

## 1.1 Автоматический ready‑чек
```bash
sudo bash scripts/99-ready-checks.sh --profile ai-stack
```

## 2. Проверка скриптов (shellcheck)
```bash
bash scripts/98-verify-scripts.sh
```

Скрипт запускает Bash syntax checks для first-party scripts и, если установлен ShellCheck, статический анализ.

Установить ShellCheck вручную:

```bash
sudo apt install -y shellcheck
shellcheck scripts/*.sh
```

## 3. Smoke‑тесты сервисов

### 3.1 n8n
```bash
curl -f http://localhost:5678/healthz
```

### 3.2 PostgreSQL (Supabase)
```bash
psql -h localhost -p 54322 -U postgres -d postgres -c "SELECT 1;"
```

### 3.3 PgBouncer
```bash
psql -h localhost -p 6432 -U postgres -d postgres -c "SELECT 1;"
```

### 3.4 Redis
```bash
redis-cli -h 127.0.0.1 -p 6379 -a YOUR_REDIS_PASSWORD ping
```

## 4. Проверка мониторинга
```bash
curl -f http://localhost:9090/-/healthy
curl -f http://localhost:3000/api/health
```

## 5. Backup/restore drill

Для `ai-stack` после первого успешного запуска проверьте не только создание backup, но и восстановление в отдельную тестовую базу.

Минимальный критерий:

1. `scripts/10-backup-postgres.sh` создаёт `postgres_*.sql.gz` без вывода пароля.
2. Dump восстанавливается в отдельную базу, например `restore_drill`.
3. Контрольный SQL-запрос по восстановленным данным проходит.
4. Временная база и marker data удалены после проверки.

Используйте `psql` версии, совместимой с `pg_dump`, которым был создан dump. Например, dump от host `pg_dump` 16 следует восстанавливать host `psql` 16, а не более старым `psql` внутри контейнера PostgreSQL 15.

## 6. Проверка на чистой VM
1. Разверните чистую VM Ubuntu 24.04 LTS.
2. Запустите preflight для выбранного профиля.
3. Продолжайте install flow только если preflight не классифицирует профиль как `NO`.
4. Пройдите шаги из `QUICKSTART.md` для выбранного профиля.
5. Запустите matching ready checks для того же профиля.
6. Зафиксируйте sanitized результат в [Ubuntu 24.04 Smoke Test Evidence](16-ubuntu-24-04-smoke-test-evidence.md).

Текущий evidence checkpoint: `minimal` прошёл на clean Ubuntu 24.04 VPS 2026-07-12; `docker-host` installation-only check прошёл на VPS ниже требований после operator override; полный `ai-stack` runtime smoke прошёл на подходящем Ubuntu 24.04 VPS 2026-07-15. Ubuntu 26.04 compatibility остаётся отдельным непроверенным target.

## Источники
- https://github.com/koalaman/shellcheck
- https://docs.docker.com/compose/reference/config/

## See Also

- [Ready Rules](14-ready-rules.md) — gate-критерии перед production.
- [Troubleshooting](11-troubleshooting.md) — что смотреть при падении проверок.
- [Scripts Order](15-scripts-order.md) — где запускать ready checks в install flow.
- [Ubuntu 24.04 Smoke Test Evidence](16-ubuntu-24-04-smoke-test-evidence.md) — результаты clean VM/VPS smoke tests.
