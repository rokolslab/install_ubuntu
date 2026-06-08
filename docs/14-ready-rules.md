[← Secrets](13-secrets.md) · [Back to README](../README.md) · [Scripts Order →](15-scripts-order.md)

# Правила готовности (Ready)

Эти правила защищают от ошибок при развёртывании и эксплуатации.

## 1. Обязательные проверки (gate)

Перед любыми изменениями выберите профиль и запускайте preflight именно для него:

```bash
sudo bash scripts/00-preflight-check.sh --profile <profile>
```

После выбранного install flow:

```bash
sudo bash scripts/99-ready-checks.sh --profile <profile>
```

Поддерживаемые профили: `minimal`, `proxy`, `docker-host`, `web`, `ai-stack`.

## 2. Стоп‑условия
Нельзя продолжать, если:
- `scripts/99-ready-checks.sh --profile <profile>` завершился с ошибкой
- для `docker-host` не установлен Docker или не активен service `docker`
- для `ai-stack` отсутствует `docker-compose/.env`, `docker compose config` возвращает ошибку или обязательные сервисы `supabase_db`, `pgbouncer`, `redis`, `n8n`, `n8n-worker` не запущены

Для `minimal` и `proxy` `.env` и Docker Compose не являются gate. `proxy` service ports проверяются вручную через `sudo ufw status verbose` и открываются только явно.

## 3. Минимальный протокол
1. Preflight для выбранного профиля → OK/WARN без blockers.
2. Запуск только scripts из выбранного profile flow → OK.
3. Ready‑checks для того же профиля → OK.
4. Только после этого переход к следующему этапу.

## 4. Рекомендации
1. Выполняйте изменения в отдельном окне/сеансе.
2. Фиксируйте шаги в журнале (команды, время, результат).
3. Храните актуальные бэкапы перед изменениями.

## Источники
- https://docs.docker.com/compose/reference/config/

## See Also

- [Quality Checks](12-quality-checks.md) — команды для ручной проверки.
- [Secrets](13-secrets.md) — обязательные секреты перед запуском.
- [Scripts Order](15-scripts-order.md) — когда запускать ready gate.
