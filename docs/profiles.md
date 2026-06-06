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
| `ai-stack` | n8n/Supabase/Redis/pgvector stack | 4GB RAM, 50GB disk | Docker, secrets, compose stack, ready checks |

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
sudo bash scripts/02-secure-server.sh
```

Ожидаемые предупреждения: Docker и `.env` могут отсутствовать.

## Proxy/x-ui VPS

Используйте для подготовки безопасной базы под proxy/VPN panel. Репозиторий не устанавливает x-ui/3x-ui автоматически.

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-secure-server.sh
```

Не открывайте panel/service ports вслепую. После установки панели явно разрешите только нужные порты.

## Docker Host

Используйте, когда нужен небольшой сервер под контейнеры без полного AI stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-secure-server.sh
sudo bash scripts/03-install-docker.sh
```

Если preflight показывает `WARN`, обычно включите swap или увеличьте RAM перед постоянными Docker workloads.

## Web/App VPS

Используйте для маленького web/app сервера с HTTP/HTTPS entry point.

```bash
sudo bash scripts/00-preflight-check.sh --profile web
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-secure-server.sh
sudo bash scripts/08-setup-nginx.sh
```

`80/443` относятся к web/reverse proxy сценарию. Они не должны открываться как часть любого hardening.

## AI Stack

Используйте для полного self-hosted AI automation stack.

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-secure-server.sh
sudo bash scripts/03-install-docker.sh
sudo bash scripts/12-generate-secrets.sh
cd docker-compose
docker compose --env-file .env up -d
sudo bash ../scripts/99-ready-checks.sh
```

`ai-stack` включает тяжёлые сервисы: Supabase/PostgreSQL, Redis, pgvector, PgBouncer, n8n, monitoring path. Не используйте его как default для маленького VPS.

## See Also

- [Scripts Catalog](scripts-catalog.md) — какой script что делает.
- [System Requirements](../requirements/system-requirements.md) — требования по профилям.
- [Quick Start](../QUICKSTART.md) — короткие installation flows.
