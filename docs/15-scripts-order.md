[← Ready Rules](14-ready-rules.md) · [Back to README](../README.md)

# Последовательность и нумерация скриптов

Цель: единая логика запуска, без ошибок из‑за устаревших имён. Если нужно понять назначение каждого файла до запуска, используйте [каталог scripts](scripts-catalog.md).

## 1. Актуальные entry points

1. `scripts/00-preflight-check.sh --profile <profile>` — profile-aware preflight проверки (VPS)
2. `scripts/01-setup-ssh-keys.sh` — SSH-ключи для GitHub/VPS/deploy/backup сценариев (клиентская машина)
3. `scripts/02-security-baseline.sh --profile <profile>` — базовая безопасность сервера
4. `scripts/02-secure-server.sh --profile <profile>` — compatibility wrapper для старого имени
5. `scripts/03-install-docker.sh --profile docker-host|ai-stack` — установка Docker/Compose
6. `scripts/04-setup-supabase.sh` — Supabase (PostgreSQL)
7. `scripts/06-setup-redis.sh` — Redis
8. `scripts/07-setup-vector-db.sh` — pgvector таблицы/индексы
9. `scripts/05-setup-n8n.sh` — n8n (после Redis + DB)
10. `scripts/08-setup-nginx.sh` — Nginx (опционально)
11. `scripts/09-install-nvidia-drivers.sh` — NVIDIA (опционально)
12. `scripts/10-backup-postgres.sh` — бэкап БД
13. `scripts/11-setup-backup-cron.sh` — cron бэкапов
14. `scripts/12-generate-secrets.sh --profile ai-stack` — генерация секретов (.env + config.toml)
15. `scripts/99-ready-checks.sh --profile <profile>` — profile-aware ready‑проверки

## 2. Важно
- Нумерация **историческая**, но **порядок запуска** указан выше.
- `scripts/00-preflight-check.sh` больше не отбраковывает маленький VPS только потому, что он не подходит для `ai-stack`; используйте `--profile minimal|proxy|docker-host|web|ai-stack`.
- `scripts/02-secure-server.sh` оставлен только как compatibility wrapper. Новый основной entry point — `scripts/02-security-baseline.sh`.
- Устаревшие имена **удалены** — используйте только актуальные.

## 3. Canonical profile paths

### Minimal VPS hardening

```bash
sudo bash scripts/00-preflight-check.sh --profile minimal
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile minimal
sudo bash scripts/99-ready-checks.sh --profile minimal
```

### Proxy/x-ui VPS

```bash
sudo bash scripts/00-preflight-check.sh --profile proxy
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile proxy
sudo bash scripts/99-ready-checks.sh --profile proxy
```

Service ports для proxy/VPN панели не открываются автоматически. Когда порт известен, используйте:

```bash
sudo bash scripts/security/firewall.sh --profile proxy --allow-port <service-port>
```

### Docker host

```bash
sudo bash scripts/00-preflight-check.sh --profile docker-host
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile docker-host
sudo bash scripts/03-install-docker.sh --profile docker-host
sudo bash scripts/99-ready-checks.sh --profile docker-host
```

### Web/app VPS

```bash
sudo bash scripts/00-preflight-check.sh --profile web
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile web
sudo bash scripts/08-setup-nginx.sh
sudo bash scripts/99-ready-checks.sh --profile web
```

### AI automation stack

```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
bash scripts/01-setup-ssh-keys.sh
sudo bash scripts/02-security-baseline.sh --profile ai-stack
sudo bash scripts/03-install-docker.sh --profile ai-stack
sudo bash scripts/04-setup-supabase.sh
sudo bash scripts/06-setup-redis.sh
sudo bash scripts/07-setup-vector-db.sh
sudo bash scripts/05-setup-n8n.sh
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
sudo bash scripts/99-ready-checks.sh --profile ai-stack
```

`ai-stack` является тяжёлым профилем. Не используйте этот порядок как default для `minimal` или `proxy` VPS.

## See Also

- [Quick Start](../QUICKSTART.md) — короткий end-to-end walkthrough.
- [Scripts Catalog](scripts-catalog.md) — назначение scripts и profile flows.
- [Ready Rules](14-ready-rules.md) — критерии завершения установки.
- [Troubleshooting](11-troubleshooting.md) — диагностика при сбоях на этапах.
