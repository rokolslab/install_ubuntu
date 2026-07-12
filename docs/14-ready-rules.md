[← Secrets](13-secrets.md) · [Back to README](../README.md) · [Scripts Order →](15-scripts-order.md)

# Правила готовности (Ready)

Эти правила защищают от ошибок при развёртывании и эксплуатации.

## 1. Обязательные проверки (gate)
Перед любыми изменениями:
```bash
sudo bash scripts/00-preflight-check.sh --profile ai-stack
```

После каждого этапа:
```bash
sudo bash scripts/99-ready-checks.sh --profile ai-stack
```

## 2. Стоп‑условия
Нельзя продолжать, если:
- `docker compose config` возвращает ошибку
- `scripts/99-ready-checks.sh --profile <profile>` завершился с ошибкой
- сервисы `supabase_db`, `pgbouncer`, `redis`, `n8n` не запущены
- `scripts/00-preflight-check.sh --profile <profile>` классифицирует выбранный профиль как `NO`

## 3. Минимальный протокол
1. Preflight → OK
2. Изменения → OK
3. Ready‑checks → OK
4. Только после этого переход к следующему этапу

## 4. Рекомендации
1. Выполняйте изменения в отдельном окне/сеансе.
2. Фиксируйте шаги в журнале (команды, время, результат).
3. Храните актуальные бэкапы перед изменениями.

## 5. Release Evidence
Перед release readiness claims нужен clean Ubuntu 24.04 VM/VPS evidence для соответствующих профилей.

Текущий статус хранится в [Ubuntu 24.04 Smoke Test Evidence](16-ubuntu-24-04-smoke-test-evidence.md): `minimal` пройден 2026-07-12, `docker-host` installation-only check пройден после operator override на VPS ниже требований, `ai-stack` остаётся открытым до запуска на VM/VPS с подходящими ресурсами.

## Источники
- https://docs.docker.com/compose/reference/config/

## See Also

- [Quality Checks](12-quality-checks.md) — команды для ручной проверки.
- [Secrets](13-secrets.md) — обязательные секреты перед запуском.
- [Scripts Order](15-scripts-order.md) — когда запускать ready gate.
- [Ubuntu 24.04 Smoke Test Evidence](16-ubuntu-24-04-smoke-test-evidence.md) — clean VM/VPS evidence.
