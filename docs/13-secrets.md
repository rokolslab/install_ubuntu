[← Quality Checks](12-quality-checks.md) · [Back to README](../README.md) · [Ready Rules →](14-ready-rules.md)

# Управление секретами

Это руководство описывает базовые практики хранения секретов для production.

## 1. Защищённый `.env` (базовый вариант)
```bash
cd docker-compose
cp env.example .env
nano .env
chmod 600 .env
```

`docker-compose/.env` является локальным runtime-файлом и игнорируется git. Не добавляйте его в commit.

Рекомендации:
- Не коммитьте `.env` или другие generated secret files в git.
- Храните резервную копию секретов в password manager.
- Не записывайте сгенерированные secrets в tracked config files, включая `docker-compose/supabase/config.toml`.

## 2. Генерация секретов
```bash
openssl rand -base64 24 | tr -d "=+/" | cut -c1-32
```

Или используйте скрипт:
```bash
sudo bash scripts/12-generate-secrets.sh --profile ai-stack
```

`scripts/12-generate-secrets.sh` — канонический генератор secrets для compose stack. Скрипт создаёт или обновляет только локальный `docker-compose/.env`, выставляет права `600` и не пишет реальные secrets в tracked config files.

Скрипт предназначен только для `ai-stack`. Для `minimal`, `proxy`, `docker-host` и `web` файл `docker-compose/.env` не требуется.

## 3. Ротация секретов
1. Сгенерируйте новые значения.
2. Обновите `.env`.
3. Перезапустите сервисы:
   ```bash
   docker compose up -d
   ```

## 4. Docker secrets (опционально)
Docker secrets удобны в Swarm и при использовании сервисов,
которые поддерживают переменные вида `*_FILE`.

В этом проекте основной путь — защищённый `.env`.

## Источники
- https://docs.docker.com/engine/swarm/secrets/
- https://docs.docker.com/compose/environment-variables/

## See Also

- [Quality Checks](12-quality-checks.md) — проверка обязательных переменных.
- [Ready Rules](14-ready-rules.md) — блокирующие условия готовности.
- [Backups](10-backup-restore.md) — защита backup credentials.
