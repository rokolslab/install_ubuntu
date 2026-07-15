[← Monitoring](09-monitoring.md) · [Back to README](../README.md) · [Troubleshooting →](11-troubleshooting.md)

# Резервное копирование и восстановление

Это руководство описывает базовый процесс бэкапа PostgreSQL (Supabase) и восстановления.

## Предварительные требования
1. Запущен `supabase_db`.
2. Установлен `postgresql-client`.

## 1. Установка клиента PostgreSQL
```bash
sudo apt update
sudo apt install -y postgresql-client
```

## 2. Бэкап PostgreSQL (скрипт)
```bash
sudo bash scripts/10-backup-postgres.sh
```

По умолчанию бэкапы сохраняются в `/opt/backups`.

## 3. Автоматизация по расписанию (cron)
```bash
sudo bash scripts/11-setup-backup-cron.sh
```

Пример расписания:
- `0 2 * * *` — ежедневно в 02:00

Удаление cron:
```bash
sudo rm -f /etc/cron.d/install-ubuntu-backup
```

## 4. Бэкап PostgreSQL (вручную)
```bash
pg_dump -h localhost -p 54322 -U postgres -d postgres | gzip > /opt/backups/postgres_manual.sql.gz
```

## 5. Восстановление из бэкапа
```bash
gunzip -c /opt/backups/postgres_YYYYMMDD_HHMMSS.sql.gz | psql -h localhost -p 54322 -U postgres -d postgres
```

Используйте `psql` версии, совместимой с `pg_dump`, которым создан dump. Например, если backup сделан host `pg_dump` 16, восстанавливайте его host `psql` 16; более старый `psql` внутри контейнера PostgreSQL 15 может не понять новые meta-команды dump-файла, такие как `\restrict`.

## 6. Проверенный restore drill

Sanitized drill 2026-07-15 на Ubuntu 24.04 VPS для `ai-stack`:

1. Создан marker table в `postgres`.
2. `scripts/10-backup-postgres.sh` создал compressed SQL dump без вывода секрета.
3. Dump восстановлен в отдельную базу `restore_drill` через host `psql` той же версии, что и `pg_dump`.
4. Контрольный запрос вернул marker value `restore-drill-ok`.
5. Временная база и marker table удалены после проверки.

## 7. Рекомендации
1. Храните бэкапы на отдельном диске или сервере.
2. Проверяйте восстановление минимум раз в месяц.
3. Зафиксируйте RPO/RTO в документации проекта.

## Источники
- https://www.postgresql.org/docs/current/backup.html

## See Also

- [Supabase](03-supabase.md) — PostgreSQL service, который нужно бэкапить.
- [Secrets](13-secrets.md) — защита `.env` и backup credentials.
- [Quality Checks](12-quality-checks.md) — проверки после восстановления.
