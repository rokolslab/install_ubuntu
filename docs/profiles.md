[← README](../README.md) · [Scripts Catalog](scripts-catalog.md)

# VPS Profiles

Профиль отвечает на вопрос: “для чего подходит этот сервер и какие scripts запускать?” Это позволяет использовать один репозиторий и для маленького hardening VPS, и для полного AI automation stack.

## Профили

| Profile | Назначение | Минимум | Типичные scripts |
|---|---|---:|---|
| `minimal` | Базовая безопасность маленького VPS | 512MB RAM, 5GB disk | preflight, SSH keys, security baseline |
| `proxy` | x-ui/3x-ui/VPN/proxy panel base | 512MB-1GB RAM, 10GB disk | minimal flow + явные service ports |
| `docker-host` | Маленький Docker host | 1GB RAM, 10GB disk | minimal flow + Docker install |
| `web` | Небольшой web/app VPS | 1GB RAM, 15GB disk | minimal flow + Nginx/reverse proxy |
| `ai-stack` | n8n, Redis, PostgreSQL/Supabase-related components, pgvector stack | 4GB RAM, 50GB disk | Docker, secrets, compose stack, ready checks |

## Optional Swap For Small VPS

Если preflight показывает `WARN` из-за малой RAM или отсутствия swap, используйте optional module:

```bash
sudo bash scripts/security/swap.sh --size 1G
```

Если swap уже есть, script только показывает статус и ничего не меняет. Пересоздание требует явного `--force-recreate`.

## Preflight States

`scripts/00-preflight-check.sh` выводит таблицу пригодности:

| State | Значение | Пример |
|---|---|---|
| `OK` | Сервер подходит для профиля | `minimal` на 1GB RAM VPS |
| `WARN` | Профиль возможен, но есть ограничение | `docker-host` на 1GB RAM без swap |
| `NO` | Не запускать профиль на этом сервере | `ai-stack` на 1GB RAM VPS |

Fatal errors используются только для blockers: не-Ubuntu OS, отсутствие root/sudo для проверок, критически мало диска даже для `minimal`.

## Minimal VPS

Используйте для базового server hardening без Docker и AI stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

Ожидаемые предупреждения: Docker и `.env` могут отсутствовать.

## Proxy/x-ui VPS

Используйте для подготовки безопасной базы под proxy/VPN panel. Репозиторий не устанавливает x-ui/3x-ui автоматически.

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile proxy --allow-port <service-port>
sudo bash scripts/99-ready-checks.sh --profile proxy
```

Не открывайте panel/service ports вслепую. Если порт ещё неизвестен, запустите baseline без `--allow-port`, установите панель, затем явно разрешите только нужный порт.

## Docker Host

Используйте, когда нужен небольшой сервер под контейнеры без полного AI stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile docker-host
sudo bash scripts/03-install-docker.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile docker-host
```

Если preflight показывает `WARN`, обычно включите swap или увеличьте RAM перед постоянными Docker workloads.

```bash
sudo bash scripts/security/swap.sh --size 1G
```

## Web/App VPS

Используйте для маленького web/app сервера с HTTP/HTTPS entry point.

```bash
sudo bash scripts/00-preflight-check.sh --profile web
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile web
sudo bash scripts/08-setup-nginx.sh
sudo bash scripts/99-ready-checks.sh --profile web
```

`80/443` относятся к web/reverse proxy сценарию. Firewall module открывает их для `web`/`ai-stack`, но не для `minimal`, `proxy` или `docker-host` без явного `--allow-port`.

## AI Stack

Используйте для полного self-hosted AI automation stack.

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

`ai-stack` включает тяжёлые сервисы: PostgreSQL with selected Supabase-related components, Redis, pgvector, PgBouncer, n8n, monitoring path. Не используйте его как default для маленького VPS.

## See Also

- [Scripts Catalog](scripts-catalog.md) — какой script что делает.
- [System Requirements](../requirements/system-requirements.md) — требования по профилям.
- [Quick Start](../QUICKSTART.md) — короткие installation flows.
