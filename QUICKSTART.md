# Быстрый старт

Короткие пути от чистого Ubuntu/VPS сервера до нужного профиля: `minimal`, `proxy`, `docker-host`, `web` или `ai-stack`. Сначала выберите назначение сервера, затем запускайте только соответствующие scripts.

## Перед началом

| Профиль | Минимум | Для чего |
|---------|---------|----------|
| `minimal` | 512MB RAM, 5GB disk | базовая безопасность маленького VPS |
| `proxy` | 512MB-1GB RAM, 5GB disk minimum; 10GB+ recommended | база под x-ui/3x-ui/VPN/proxy panel |
| `docker-host` | 1GB RAM, 10GB disk | маленький Docker host |
| `web` | 1GB RAM, 15GB disk | web/app VPS с HTTP/HTTPS |
| `ai-stack` | 4GB RAM, 50GB disk | n8n, PostgreSQL/Supabase-related components, Redis, pgvector, monitoring |

Общее: Ubuntu 24.04 LTS как primary baseline, root/sudo доступ, рабочий SSH. Ubuntu 26.04 LTS — compatibility/validation target, не fully validated primary support. Для bare metal с новым железом сначала проверьте [драйверы и совместимость](docs/08-hardware-drivers.md).

## 1. Получите проект

```bash
git clone https://github.com/RokolsLab/install_ubuntu.git
cd install_ubuntu
```

Если проект копируется без git, важно сохранить структуру каталогов `scripts/`, `docker-compose/`, `docs/`, `templates/` и `requirements/`.

## 2. Подготовьте SSH-ключи

На клиентской машине, не на сервере:

```bash
bash scripts/01-setup-ssh-keys.sh
```

Перед hardening убедитесь, что доступ по ключу работает. Это снижает риск заблокировать SSH-доступ. Подробности: [SSH Keys](docs/ssh-keys.md).

## 3. Minimal VPS Hardening

Используйте для маленького VPS, где нужны SSH hardening, UFW, fail2ban, updates и audit без Docker/AI stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

Ожидаемые предупреждения preflight: Docker, compose и `.env` могут отсутствовать. Это нормально для `minimal`.

Если RAM мала и swap отсутствует:

```bash
sudo bash scripts/security/swap.sh --size 1G
```

## 4. Proxy/x-ui VPS

Используйте для подготовки безопасной базы под proxy/VPN panel. Репозиторий не устанавливает x-ui/3x-ui автоматически.

`5GB` свободного диска достаточно для security baseline. Для самой proxy/VPN panel, логов и обновлений лучше закладывать `10GB+`.

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
sudo bash scripts/02-security-baseline.sh --profile proxy
sudo bash scripts/99-ready-checks.sh --profile proxy
```

Service ports не открываются автоматически. Когда порт известен, разрешите только его:

```bash
sudo bash scripts/security/firewall.sh --profile proxy --allow-port <service-port>
```

Также можно передать порт сразу в baseline:

```bash
sudo bash scripts/02-security-baseline.sh --profile proxy --allow-port <service-port>
```

## 5. Docker Host

Используйте для небольшого сервера под контейнеры без полного AI stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
sudo bash scripts/02-security-baseline.sh --profile docker-host
sudo bash scripts/03-install-docker.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile docker-host
```

Проверьте установку Docker:

```bash
docker --version
docker compose version
```

Если preflight показывает `WARN`, обычно включите swap или увеличьте RAM перед постоянными Docker workloads.

## 6. Web/App VPS

Используйте для маленького web/app сервера с публичным HTTP/HTTPS entry point.

```bash
sudo bash scripts/00-preflight-check.sh --profile web
sudo bash scripts/02-security-baseline.sh --profile web
sudo bash scripts/08-setup-nginx.sh
sudo bash scripts/99-ready-checks.sh --profile web
```

`80/443` относятся к web/reverse proxy сценарию. Не открывайте внутренние DB/cache/service ports публично без явной необходимости.

## 7. AI Automation Stack

Используйте для Docker Compose stack: n8n, PostgreSQL with selected Supabase-related components, Redis, pgvector, PgBouncer, monitoring и backups.

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
sudo bash scripts/02-security-baseline.sh --profile ai-stack
sudo bash scripts/03-install-docker.sh --profile ai-stack
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
cd docker-compose
docker compose --env-file .env up -d
docker compose ps
sudo bash ../scripts/99-ready-checks.sh --profile ai-stack
```

По умолчанию PostgreSQL, Redis, Supabase Studio и n8n привязаны к `127.0.0.1`. Для внешнего доступа используйте SSH tunnel или [Nginx](docs/07-nginx.md).

Критичные переменные в `docker-compose/.env`:

| Переменная | Назначение |
|------------|------------|
| `REDIS_PASSWORD` | пароль Redis |
| `SUPABASE_DB_PASSWORD` | пароль PostgreSQL (`supabase_db`) |
| `N8N_BASIC_AUTH_PASSWORD` | пароль n8n |
| `N8N_ENCRYPTION_KEY` | ключ шифрования n8n |
| `N8N_USER_MANAGEMENT_JWT_SECRET` | JWT secret n8n |
| `GRAFANA_PASSWORD` | пароль Grafana |

Подробности: [Secrets](docs/13-secrets.md).

## Полезные команды для AI stack

```bash
cd docker-compose

# Логи всех сервисов
docker compose logs -f

# Логи одного сервиса
docker compose logs -f n8n

# Перезапуск сервиса
docker compose restart n8n

# Остановка стека без удаления данных
docker compose down

# Остановка с удалением volumes: удалит данные
docker compose down -v
```

## Следующие шаги

| Задача | Команда или ссылка |
|--------|--------------------|
| Понять назначение scripts | [Scripts Catalog](docs/scripts-catalog.md) |
| Сверить порядок запуска | [Scripts Order](docs/15-scripts-order.md) |
| Требования по профилям | [System Requirements](requirements/system-requirements.md) |
| pgvector/RAG setup | [pgvector](docs/06-vector-db.md) |
| n8n credentials | [n8n](docs/04-n8n.md) |
| Monitoring | [Monitoring](docs/09-monitoring.md) |
| PostgreSQL backup | `sudo bash scripts/10-backup-postgres.sh` |
| Backup schedule | `sudo bash scripts/11-setup-backup-cron.sh` |
| Public HTTPS access | [Nginx](docs/07-nginx.md) |
| Troubleshooting | [Troubleshooting](docs/11-troubleshooting.md) |
