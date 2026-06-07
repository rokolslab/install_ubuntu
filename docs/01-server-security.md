[Back to README](../README.md) · [Security Hardening Details →](01-server-security-hardening.md)

# Безопасная настройка Ubuntu сервера

Базовый hardening перед развёртыванием Docker-инфраструктуры: обновления, firewall, SSH, fail2ban и автоматические security updates.

## Важные предупреждения

- Выполняйте hardening на чистом сервере или после резервной копии.
- Сначала проверьте SSH-доступ по ключу, затем меняйте SSH-настройки.
- Если работаете по SSH, держите вторую активную сессию до проверки нового доступа.
- Генерируйте ключи на клиентской машине; на сервер и в GitHub добавляйте только `.pub`.

## Pre-hardening checklist

- SSH-ключ создан или выбран на клиентской машине.
- Публичный ключ добавлен в `~/.ssh/authorized_keys` нужного пользователя на сервере.
- Вход по ключу проверен во второй SSH-сессии.
- Root/password hardening включается только после подтверждения ключевого доступа.
- Подробный guide по GitHub, VPS/root, deploy и backup ключам: [SSH Keys](ssh-keys.md).

## Быстрый путь

```bash
sudo bash scripts/02-security-baseline.sh --profile minimal
```

Новый baseline вызывает короткие security modules: updates, UFW, SSH hardening, fail2ban, unattended upgrades и sysctl hardening. Старый `scripts/02-secure-server.sh` сохраняется как deprecated compatibility wrapper и требует явный `--profile`.

## Что настраивается

| Блок | Назначение | Проверка |
|------|------------|----------|
| System updates | обновление пакетов и cleanup | `sudo apt update` |
| UFW | сохранить SSH, default deny incoming, открыть profile ports | `sudo ufw status verbose` |
| SSH | backup config, запрет пустых паролей, ограничение попыток, safe root/password policy | `sudo sshd -t` |
| fail2ban | защита SSH от brute force | `sudo fail2ban-client status sshd` |
| unattended upgrades | автоматические security updates | `systemctl status unattended-upgrades` |

## Ручной порядок

### 1. Обновите систему

```bash
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y
```

### 2. Включите UFW

```bash
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo ufw status verbose
```

`80/443` открывайте только для `web`/`ai-stack` или явного reverse proxy сценария.

### 3. Проверьте SSH hardening

Минимальные настройки:

```bash
sudo bash scripts/security/ssh-hardening.sh
```

`scripts/security/ssh-hardening.sh` делает timestamped backup `sshd_config`, проверяет `sshd -t` и выполняет rollback при ошибке. `PermitRootLogin no` и `PasswordAuthentication no` применяются только если есть подтверждённый non-root пользователь с `authorized_keys`; иначе script печатает warning и пропускает опасный шаг.

### 4. Установите fail2ban

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo fail2ban-client status
```

### 5. Включите security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
sudo systemctl enable unattended-upgrades
sudo systemctl start unattended-upgrades
```

## Проверка после hardening

```bash
sudo ufw status verbose
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication|maxauthtries|port"
sudo fail2ban-client status sshd
systemctl status unattended-upgrades --no-pager
```

## Advanced details

Расширенные настройки SSH-порта, `sysctl`, logwatch и дополнительные рекомендации вынесены в [Security Hardening Details](01-server-security-hardening.md). Подробные SSH-key сценарии описаны в [SSH Keys](ssh-keys.md).

## Источники

- [Ubuntu Security Documentation](https://ubuntu.com/security)
- [DigitalOcean Security Best Practices](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)

## See Also

- [Security Hardening Details](01-server-security-hardening.md) — расширенные настройки безопасности.
- [SSH Keys](ssh-keys.md) — генерация и настройка ключей для GitHub, VPS/root, deploy и backup доступа.
- [Docker Installation](02-docker-installation.md) — следующий этап после hardening.
- [Quality Checks](12-quality-checks.md) — проверка готовности после установки.
