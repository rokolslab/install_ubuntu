[← Troubleshooting](11-troubleshooting.md) · [Back to README](../README.md) · [Secrets →](13-secrets.md)

# Контроль качества и проверка установки

Этот чек‑лист помогает проверить корректность scripts, выбранного profile flow и, для `ai-stack`, Docker Compose инфраструктуры.

## 0. Profile-aware ready check

Всегда проверяйте тот же профиль, который устанавливали:

```bash
sudo bash scripts/99-ready-checks.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile proxy
sudo bash scripts/99-ready-checks.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile web
sudo bash scripts/99-ready-checks.sh --profile ai-stack
```

Для `minimal` и `proxy` ready check не требует Docker, Compose или `docker-compose/.env`. Для `proxy` service ports дополнительно проверяются вручную через `sudo ufw status verbose`.

## 1. Проверка конфигурации Docker Compose (`ai-stack`)

Эта проверка обязательна только для `ai-stack`:

```bash
cd docker-compose
docker compose config
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

Smoke‑тесты ниже относятся к `ai-stack`, где сервисы запущены через Docker Compose.

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

## 5. Проверка на чистой VM
1. Разверните чистую VM Ubuntu 24.04 LTS.
2. Пройдите все шаги из `QUICKSTART.md`.
3. Повторите Smoke‑тесты.

## Источники
- https://github.com/koalaman/shellcheck
- https://docs.docker.com/compose/reference/config/

## See Also

- [Ready Rules](14-ready-rules.md) — gate-критерии перед production.
- [Troubleshooting](11-troubleshooting.md) — что смотреть при падении проверок.
- [Scripts Order](15-scripts-order.md) — где запускать ready checks в install flow.
