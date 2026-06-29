# Системные требования

Требования зависят от профиля сервера. `4GB RAM / 50GB disk` относится к полному `ai-stack`, а не к каждому маленькому VPS.

## Общая база

| Требование | Значение |
|---|---|
| ОС | Ubuntu Server 24.04 LTS primary baseline; Ubuntu 26.04 LTS compatibility/validation target |
| Архитектура | `x86_64` / `amd64` рекомендуется |
| Доступ | `sudo` или root для server-side setup scripts |
| Сеть | Стабильное интернет-соединение для apt/Docker downloads |
| Bash | 4.4+ |

## Требования по профилям

| Profile | Назначение | Минимум | Рекомендуется | Docker нужен |
|---|---|---:|---:|---|
| `minimal` | Базовая безопасность маленького VPS | 512MB RAM, 5GB disk | 1GB RAM, swap | нет |
| `proxy` | x-ui/3x-ui/VPN/proxy panel base | 512MB RAM, 10GB disk | 1GB RAM, swap | нет, если панель не требует Docker |
| `docker-host` | Маленький Docker host | 1GB RAM, 10GB disk | 2GB RAM, swap | да |
| `web` | Небольшой web/app VPS | 1GB RAM, 15GB disk | 2GB RAM, swap | optional |
| `ai-stack` | n8n/Supabase/Redis/pgvector stack | 4GB RAM, 50GB disk | 8GB+ RAM, 100GB+ SSD | да |

## Уровни preflight

`scripts/00-preflight-check.sh` классифицирует сервер по профилям:

| State | Смысл | Что делать |
|---|---|---|
| `OK` | Сервер подходит для профиля | Можно продолжать соответствующий flow |
| `WARN` | Профиль возможен с ограничениями | Прочитать рекомендацию: часто нужен swap, больше RAM или осторожность с нагрузкой |
| `NO` | Ресурсов недостаточно для профиля | Не запускать этот профиль на текущем сервере |

Fatal-состояния ограничены реальными blockers: неподдерживаемая ОС, отсутствие root/sudo для system checks, критически малый диск даже для `minimal`.

Перед изменениями выполните:

```bash
sudo bash scripts/00-preflight-check.sh
sudo bash scripts/00-preflight-check.sh --profile minimal
sudo bash scripts/00-preflight-check.sh --profile ai-stack
```

## Программное обеспечение

### Базовые компоненты

- `curl` или `wget` для загрузки и health checks.
- `git` опционально, если сервер сам клонирует репозиторий.
- `ufw`, `fail2ban`, `unattended-upgrades` устанавливаются security scripts при необходимости.

### После установки Docker

- Docker Engine 24.0+.
- Docker Compose 2.20+.

Docker нужен для `docker-host` и `ai-stack`. Он не является обязательным для `minimal` и `proxy`.

## Сетевые требования

| Сценарий | Порты |
|---|---|
| SSH | Текущий SSH port, обычно `22/tcp` |
| `minimal` | Только SSH и явно разрешённые admin ports |
| `proxy` | SSH + вручную выбранные service ports после установки панели |
| `web` | SSH + `80/tcp`, `443/tcp` при reverse proxy/HTTPS path |
| `ai-stack` | SSH + public reverse proxy ports; DB/cache/internal services должны оставаться закрытыми наружу |

Внутренние порты Supabase, PostgreSQL, Redis, PgBouncer, n8n, Prometheus и Grafana не должны открываться наружу без явной reverse proxy/firewall стратегии.

## Production рекомендации

1. Настройте monitoring и alerts для production workload.
2. Настройте backup до хранения важных данных.
3. Используйте HTTPS для публичных web endpoints.
4. Держите `.env` и generated secrets вне git и публичных логов.
5. Для `ai-stack` закладывайте запас RAM/CPU под Supabase, n8n workers и Redis queue mode.
