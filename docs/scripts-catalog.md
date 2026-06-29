[← README](../README.md) · [Scripts Order](15-scripts-order.md)

# Каталог scripts

Цель: перед запуском понять, какой script что делает, для каких профилей он нужен и чего он не делает.

## Top-Level Scripts

| Script | Что делает | Профили | Когда запускать | Что не делает |
|---|---|---|---|---|
| `scripts/00-preflight-check.sh` | Проверяет Ubuntu, ресурсы, базовые утилиты и классифицирует пригодность сервера | all | Самым первым шагом, до privileged изменений | Не устанавливает пакеты и не меняет систему |
| `scripts/01-setup-ssh-keys.sh` | Готовит SSH keys для GitHub, VPS/root, deploy и backup сценариев | all | На клиентской машине до SSH hardening | Не меняет firewall и не ставит server packages |
| `scripts/02-secure-server.sh` | Deprecated compatibility wrapper для старого имени | all | Только если старая инструкция ссылается на этот файл | Не выбирает default profile; требует `--profile` и вызывает `02-security-baseline.sh` |
| `scripts/02-security-baseline.sh` | Короткий orchestrator security baseline | `minimal`, `proxy`, `docker-host`, `web`, `ai-stack` | После preflight и SSH keys | Не устанавливает Docker, Nginx, Supabase, Redis или n8n |
| `scripts/security/swap.sh` | Optional idempotent swapfile для маленьких VPS | `minimal`, `proxy`, `docker-host` | Если preflight показывает малую RAM/no swap | Не пересоздаёт существующий swap без `--force-recreate` |
| `scripts/03-install-docker.sh` | Устанавливает Docker Engine и Docker Compose | `docker-host`, `ai-stack` | После security baseline, если профиль требует контейнеры | Не нужен для `minimal`/`proxy` по умолчанию и не поднимает compose stack |
| `scripts/04-setup-supabase.sh` | Готовит PostgreSQL (`supabase_db`) | `ai-stack` | Только в AI stack flow | Не поднимает full Supabase platform |
| `scripts/05-setup-n8n.sh` | Настраивает n8n main/worker | `ai-stack` | После DB/Redis prerequisites | Не ставит Docker и не генерирует secrets |
| `scripts/06-setup-redis.sh` | Настраивает Redis для очередей/cache | `ai-stack` | До n8n queue mode | Не открывает Redis наружу |
| `scripts/07-setup-vector-db.sh` | Готовит pgvector таблицы/индексы | `ai-stack` | После PostgreSQL | Не заменяет backup/restore процедуры |
| `scripts/08-setup-nginx.sh` | Настраивает Nginx/reverse proxy path | `web`, `ai-stack`, optional `proxy` | Когда нужен публичный HTTP/HTTPS entry point | Не должен открывать внутренние DB/cache порты |
| `scripts/09-install-nvidia-drivers.sh` | Устанавливает NVIDIA drivers | optional | Только для GPU hosts | Не нужен для обычного маленького VPS |
| `scripts/10-backup-postgres.sh` | Выполняет PostgreSQL backup | `ai-stack` | После запуска DB и настройки `.env` | Не настраивает cron сам по себе |
| `scripts/11-setup-backup-cron.sh` | Добавляет cron для PostgreSQL backups | `ai-stack` | После проверки ручного backup | Не проверяет бизнес-целостность данных |
| `scripts/12-generate-secrets.sh` | Генерирует `docker-compose/.env` из template | `ai-stack` | Перед compose up | Не нужен для `minimal`/`proxy`/`docker-host` и не выводит реальные secrets |
| `scripts/98-verify-scripts.sh` | Проверяет Bash syntax и ShellCheck при наличии | dev | Локально после изменения scripts | Не запускает privileged setup logic |
| `scripts/99-ready-checks.sh` | Profile-aware readiness checks после установки | all | После выбранного install flow | Для `minimal`/`proxy` не требует `.env` и compose |

## Profile Flows

### Minimal VPS Hardening

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

Ожидаемые предупреждения preflight: Docker и `.env` могут отсутствовать; это нормально для `minimal`.

Если RAM мала и swap отсутствует:

```bash
sudo bash scripts/security/swap.sh --size 1G
```

### Proxy/x-ui VPS

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile proxy --allow-port <service-port>
sudo bash scripts/99-ready-checks.sh --profile proxy
```

Service ports для x-ui/3x-ui/VPN не открываются автоматически. Если порт ещё неизвестен, запустите baseline без `--allow-port`, затем откройте порт вручную после установки панели.

### Docker Host

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile docker-host
sudo bash scripts/03-install-docker.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile docker-host
```

Если preflight показывает `WARN`, обычно нужен swap или больше RAM перед постоянными Docker workloads.

```bash
sudo bash scripts/security/swap.sh --size 1G
```

### Web/App VPS

```bash
sudo bash scripts/00-preflight-check.sh --profile web
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile web
sudo bash scripts/08-setup-nginx.sh
sudo bash scripts/99-ready-checks.sh --profile web
```

Порты `80/443` должны открываться только для web/reverse proxy сценария, а не как часть любого VPS hardening.

### AI Automation Stack

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile ai-stack
sudo bash scripts/03-install-docker.sh --profile ai-stack
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
cd docker-compose
docker compose --env-file .env up -d
sudo bash ../scripts/99-ready-checks.sh --profile ai-stack
```

`ai-stack` требует больше ресурсов. `4GB RAM / 50GB disk` относится именно к этому профилю, а не к minimal/proxy VPS.

Если используете component scripts вместо единого `docker compose up -d`, всё равно сначала запустите `scripts/12-generate-secrets.sh --profile ai-stack`, чтобы `.env` и `supabase/config.toml` были синхронизированы до запуска сервисов.

## Firewall Rules

`scripts/security/firewall.sh` сохраняет SSH port и применяет UFW default deny incoming. Порты `80/443` открываются только для `web`/`ai-stack` или через явный `--allow-port`.

Proxy/x-ui пример:

```bash
sudo bash scripts/security/firewall.sh --profile proxy --allow-port <service-port>
```

Если service port ещё неизвестен, не открывайте его заранее. Сначала установите panel, затем разрешите только фактический порт.

## See Also

- [Scripts Order](15-scripts-order.md) — канонический порядок запуска.
- [System Requirements](../requirements/system-requirements.md) — требования к серверу.
- [Server Security](01-server-security.md) — подробности hardening.
