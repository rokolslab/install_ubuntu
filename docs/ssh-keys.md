[← Server Security](01-server-security.md) · [Back to README](../README.md)

# SSH-ключи для GitHub и Ubuntu/VPS

Этот документ описывает практичный стандарт SSH-ключей для рабочих машин, GitHub, VPS/root доступа, non-root admin доступа, deploy-пользователей и резервного доступа.

## Короткий обзор

- Генерируйте SSH-ключи на клиентской машине: ноутбук, desktop, mini PC, WSL environment или CI/deploy host.
- На GitHub и VPS копируйте только публичный ключ с суффиксом `.pub`.
- Приватный ключ без `.pub` остаётся только там, откуда вы подключаетесь.
- Для GitHub, root/admin и backup/rescue ключей используйте passphrase.
- Для deploy/automation ключей пустая passphrase допустима только после явного принятия риска и ограничения прав.
- Перед SSH hardening сначала проверьте non-root key access, второй SSH-сеанс и `sudo -v`.

Интерактивный helper проекта:

```bash
bash scripts/01-setup-ssh-keys.sh
```

Этот helper Bash-oriented: он лучше подходит для Linux/macOS, WSL и Git Bash. Для native Windows PowerShell используйте команды из раздела [Платформенные команды](#платформенные-команды).

## Быстрый выбор сценария

| Задача | Куда перейти | Ключевые проверки |
|--------|--------------|-------------------|
| Добавить SSH key в GitHub | [GitHub SSH key](#github-ssh-key) | `.pub` добавлен в нужный GitHub account, `git remote` использует правильный host/alias. |
| Подключиться к новому VPS как `root` для initial setup | [Bootstrap root key](#bootstrap-root-key) | Root-доступ временный; постоянный доступ должен перейти на non-root admin. |
| Настроить безопасный постоянный доступ к VPS | [Persistent admin key](#persistent-admin-key) | Вход как admin проверен во второй SSH-сессии, `sudo -v` работает. |
| Подготовить серверный deploy/automation доступ | [Deploy key](#deploy-key) | Минимальные права, отдельный пользователь, write access только при необходимости. |
| Подготовить аварийный доступ | [Backup/rescue key](#backuprescue-key) | Passphrase, отдельное хранение, периодическая проверка. |
| VPS переустановлен или сменился host key | [Ротация, reinstall и compromised keys](#ротация-reinstall-и-compromised-keys) | `REMOTE HOST IDENTIFICATION HAS CHANGED` проверен out-of-band до удаления записи. |
| Ошибка `Permission denied (publickey)` или wrong key | [Troubleshooting](#troubleshooting) | Проверить `ssh -vT`, `ssh-add -l`, `git remote -v`, `IdentityFile`, user и port. |

Рекомендуемый порядок для нового VPS:

1. Запустите `scripts/00-preflight-check.sh` по выбранному profile.
2. Создайте или выберите SSH key на клиентской машине.
3. Добавьте `.pub` на сервер или в панель провайдера.
4. Создайте non-root admin user и добавьте ему admin public key.
5. Проверьте вход как admin во второй SSH-сессии.
6. Проверьте `sudo -v`.
7. Только после этого запускайте `scripts/02-security-baseline.sh --profile <profile>` или `scripts/security/ssh-hardening.sh`.

## Базовая модель безопасности

У каждой SSH key pair есть два файла:

- Private key: файл без `.pub`, например `vps_vps-fi-01_admin_ubuntu_pc`.
- Public key: файл с `.pub`, например `vps_vps-fi-01_admin_ubuntu_pc.pub`.

Правила безопасности:

- Private key генерируется и хранится на клиентской машине.
- Public key `.pub` можно добавить в GitHub или на сервер в `~/.ssh/authorized_keys`.
- Команды просмотра и копирования должны читать `.pub`, например `cat key.pub` или `Get-Content key.pub`.
- Исключение: private key указывается локально в `ssh -i`, чтобы клиент подписал подключение.
- Не копируйте private key на VPS, в GitHub, чаты, тикеты, email, репозитории или документацию.
- Если private key попал наружу, считайте его скомпрометированным: удалите public key из GitHub/VPS и создайте новую пару.
- Комментарий ключа виден в GitHub и `authorized_keys`, поэтому не добавляйте туда secrets, private IP клиентов, tokens или приватные заметки.

Passphrase policy:

| Тип ключа | Passphrase | Почему |
|-----------|------------|--------|
| GitHub personal/admin | Рекомендуется | Ключ даёт доступ от имени GitHub account. |
| VPS root/admin | Рекомендуется | Ключ открывает privileged или sudo-capable доступ. |
| Deploy/automation | Допустима пустая только при явном принятии риска | Unattended jobs не могут вводить passphrase; компенсируйте минимальными правами и ротацией. |
| Backup/rescue | Обязательна практически всегда | Ключ хранится отдельно и используется для восстановления доступа. |

## Именование ключей и комментарии

Рекомендуемый формат для новых ключей:

```text
<purpose>_<target>_<role>_<device>
```

Составные части отвечают на четыре вопроса:

- `purpose`: для чего ключ используется, например `github`, `vps`, `deploy`, `backup`.
- `target`: к какому аккаунту, серверу или окружению относится ключ, например `rokolslab`, `vps-fi-01`, `prod-n8n`.
- `role`: какая роль или пользователь получает доступ, например `root`, `admin`, `deploy`, `rescue`.
- `device`: с какого устройства или host ключ используется, например `ubuntu-pc`, `thinkpad`, `mini-pc`, `offline-usb`.

Такое имя помогает быстро понять, какой ключ нужно удалить или заменить после потери ноутбука, смены VPS, ротации deploy-доступа или передачи проекта другому администратору.

Хорошие примеры:

```text
~/.ssh/github_rokolslab_admin_ubuntu_pc
~/.ssh/vps_vps-fi-01_root_ubuntu_pc
~/.ssh/vps_vps-fi-01_admin_ubuntu_pc
~/.ssh/deploy_prod-n8n_deploy_mini_pc
~/.ssh/backup_vps-fi-01_rescue_offline_usb
```

Плохие примеры:

```text
~/.ssh/id_rsa
~/.ssh/mykey
~/.ssh/server
~/.ssh/github
~/.ssh/new_key
```

Плохие имена не показывают назначение, сервер, роль или устройство. Их трудно безопасно ротировать и легко случайно использовать не там.

Практическое отличие helper script: `scripts/01-setup-ssh-keys.sh` генерирует короткое имя вида `purpose_account-or-server_device`. Если используете helper, включайте роль в значение account/server, например `vps-fi-01_admin`, чтобы итоговое имя оставалось понятным.

Формат комментария:

```text
email | purpose | account/server | role/user | device | date
```

Пример:

```text
admin@example.com | vps | vps-fi-01 | admin | ubuntu-pc | 2026-05-16
```

Текущий helper script использует компактный комментарий `email | purpose | account/server | device | date`. Это допустимо для helper flow, если назначение ключа понятно из имени файла.

## Платформенные команды

### Матрица платформ

| Клиент | Что использовать | Важные отличия |
|--------|------------------|----------------|
| Linux/macOS | OpenSSH в terminal | `~/.ssh`, `chmod`, `ssh-copy-id` обычно доступны. |
| Windows PowerShell | Windows OpenSSH | Путь `$env:USERPROFILE\.ssh`, права через ACL, `ssh-copy-id` обычно отсутствует. |
| Git Bash | OpenSSH из Git for Windows | `~/.ssh` обычно указывает на Windows home; удобно для Unix-like команд. |
| WSL | Linux OpenSSH внутри WSL | Ключи WSL и Windows OpenSSH могут лежать в разных home directories. |
| PuTTY/Pageant | PuTTYgen, `.ppk`, Pageant | Используйте для PuTTY/Plink workflows; не смешивайте `.ppk` и OpenSSH config без понимания формата. |

### Linux/macOS OpenSSH

Подготовьте каталог и config:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

Сгенерируйте ключ:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/github_rokolslab_admin_ubuntu_pc \
  -C "admin@example.com | github | RokolsLab | admin | ubuntu-pc | 2026-05-16"
```

Покажите только публичный ключ:

```bash
cat ~/.ssh/github_rokolslab_admin_ubuntu_pc.pub
```

Проверьте права:

```bash
chmod 600 ~/.ssh/github_rokolslab_admin_ubuntu_pc
chmod 644 ~/.ssh/github_rokolslab_admin_ubuntu_pc.pub
```

Добавьте ключ в agent:

```bash
ssh-add ~/.ssh/github_rokolslab_admin_ubuntu_pc
ssh-add -l
```

### Windows OpenSSH и PowerShell

Проверьте, что OpenSSH доступен:

```powershell
ssh -V
Get-Command ssh-keygen
```

Создайте каталог `.ssh` в профиле Windows:

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.ssh"
```

Сгенерируйте ключ:

```powershell
ssh-keygen -t ed25519 `
  -f "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop" `
  -C "admin@example.com | github | RokolsLab | admin | windows-laptop | 2026-05-16"
```

Покажите только публичный ключ:

```powershell
Get-Content "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop.pub"
```

Подключение с явным private key path:

```powershell
ssh -i "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop" git@github.com
```

Путь к Windows OpenSSH config:

```text
C:\Users\<User>\.ssh\config
```

В PowerShell этот же путь удобно открывать так:

```powershell
notepad "$env:USERPROFILE\.ssh\config"
```

### Windows ssh-agent

Проверьте и включите service:

```powershell
Get-Service ssh-agent
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

Добавьте ключ и проверьте identities:

```powershell
ssh-add "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop"
ssh-add -l
```

Если видите `UNPROTECTED PRIVATE KEY FILE`, это проблема permissions. В Windows `chmod` не является полной заменой ACL. Безопасная цель: private key должен быть доступен текущему пользователю и не должен быть доступен широким группам вроде `Everyone` или `Users`.

Минимальная проверка ACL:

```powershell
icacls "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop"
```

Если ACL слишком широкие, исправляйте их осторожно и проверяйте результат. Не применяйте массовые destructive ACL-команды ко всему профилю пользователя.

### Git Bash и WSL

Git Bash удобен, если инструкция использует Unix-like команды: `cat`, `chmod`, `ssh-add`, `ssh-keygen`. В Git Bash `~/.ssh` обычно мапится на Windows home, то есть на тот же каталог, что и `$env:USERPROFILE\.ssh`.

WSL ведёт себя как Linux environment. Его `~/.ssh` обычно находится внутри WSL-дистрибутива и не равен Windows OpenSSH каталогу. Если вы используете WSL для SSH, храните и настраивайте ключи внутри WSL. Если используете PowerShell, храните и настраивайте ключи в Windows profile.

Не смешивайте agent/config разных сред без причины: ключ, добавленный в Windows `ssh-agent`, не всегда виден внутри WSL, и наоборот.

### PuTTY и Pageant

PuTTY использует собственный формат private key `.ppk`. Для PuTTY/Plink workflows используйте PuTTYgen для создания или импорта ключей и Pageant для agent-like хранения ключей в сессии.

Практические правила:

- Для Git for Windows и PowerShell обычно проще использовать OpenSSH keys, а не PuTTY `.ppk`.
- Для PuTTY sessions используйте `.ppk` и Pageant.
- Не конвертируйте private key между форматами без passphrase и понятной причины.
- Не храните и OpenSSH private key, и `.ppk` копию в незащищённых местах.

## GitHub SSH key

GitHub SSH key привязан к GitHub account и используется для интерактивного доступа от имени этого account. Repository deploy key привязан к одному repository и подходит для automation; не используйте personal admin key как deploy key на сервере.

Добавьте именно `.pub` в GitHub: `Settings` → `SSH and GPG keys` → `New SSH key`.

Сгенерируйте ключ на клиентской машине:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/github_rokolslab_admin_ubuntu_pc \
  -C "admin@example.com | github | RokolsLab | admin | ubuntu-pc | 2026-05-16"
```

Покажите public key:

```bash
cat ~/.ssh/github_rokolslab_admin_ubuntu_pc.pub
```

Для одного GitHub-аккаунта:

```sshconfig
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_rokolslab_admin_ubuntu_pc
    IdentitiesOnly yes
```

Для нескольких GitHub-аккаунтов используйте aliases:

```sshconfig
Host github-rokolslab
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_rokolslab_admin_ubuntu_pc
    IdentitiesOnly yes

Host github-project-admin
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_project-admin_work_thinkpad
    IdentitiesOnly yes
```

Проверка:

```bash
ssh -T git@github.com
ssh -T git@github-rokolslab
```

Эти же команды работают в PowerShell, Git Bash и WSL, если соответствующий OpenSSH config находится в той среде, из которой вы запускаете `ssh`.

PowerShell проверка с явным ключом без config:

```powershell
ssh -T -i "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop" git@github.com
```

`Host github-rokolslab` — это локальный alias в SSH config. Он говорит SSH-клиенту: подключаться к `github.com`, использовать пользователя `git` и конкретный `IdentityFile`. Git remote должен ссылаться на alias, иначе Git может выбрать другой ключ.

Clone через alias:

```bash
git clone git@github-rokolslab:RokolsLab/install_ubuntu.git
```

Если repository уже cloned через другой host, обновите remote:

```bash
git remote set-url origin git@github-rokolslab:RokolsLab/install_ubuntu.git
```

Если `ssh -T` проходит, но `git clone` или `git pull` всё равно падает, сначала проверьте `git remote -v`: remote должен использовать тот же host или alias, который вы проверяли.

## VPS access keys

Серверный flow должен снижать риск lockout: сначала временный root-доступ от провайдера, затем non-root admin user с ключом, затем проверка второго SSH-сеанса и только после этого hardening. Подробный security flow описан в [Server Security](01-server-security.md) и [Security Hardening Details](01-server-security-hardening.md).

### Bootstrap root key

Root key нужен только для initial setup, если провайдер не добавил ваш public key при создании VPS или если root-доступ временно нужен для bootstrap.

Сгенерируйте root key на клиентской машине:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/vps_vps-fi-01_root_ubuntu_pc \
  -C "admin@example.com | vps | vps-fi-01 | root | ubuntu-pc | 2026-05-16"
```

Скопируйте публичный ключ на сервер с Linux/macOS/Git Bash:

```bash
ssh-copy-id -i ~/.ssh/vps_vps-fi-01_root_ubuntu_pc.pub -p 22 root@SERVER_IP
```

Проверьте вход до hardening:

```bash
ssh -i ~/.ssh/vps_vps-fi-01_root_ubuntu_pc -p 22 root@SERVER_IP
```

Пример root alias:

```sshconfig
Host vps-fi-01-root
    HostName SERVER_IP
    User root
    Port 22
    IdentityFile ~/.ssh/vps_vps-fi-01_root_ubuntu_pc
    IdentitiesOnly yes
```

После проверки root key создайте отдельного non-root admin пользователя, добавьте ему public key и проверьте вход до hardening. Не отключайте root/password login, если работает только root-доступ.

### Persistent admin key

Admin key — основной ежедневный доступ к VPS. Он должен принадлежать non-root пользователю с `sudo`, а не `root`.

Сгенерируйте admin key на клиентской машине:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc \
  -C "admin@example.com | vps | vps-fi-01 | admin | ubuntu-pc | 2026-05-16"
```

Минимальные server-side команды для создания admin user выполняйте в активной root-сессии:

```bash
adduser admin
usermod -aG sudo admin
install -d -m 700 -o admin -g admin /home/admin/.ssh
printf '%s\n' 'PASTE_PUBLIC_KEY_HERE' >> /home/admin/.ssh/authorized_keys
chown admin:admin /home/admin/.ssh/authorized_keys
chmod 600 /home/admin/.ssh/authorized_keys
```

Вставляйте только содержимое `~/.ssh/vps_vps-fi-01_admin_ubuntu_pc.pub`. Не вставляйте private key.

Проверка со второй клиентской сессии:

```bash
ssh -i ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc admin@SERVER_IP
sudo -v
```

Пример admin alias:

```sshconfig
Host vps-fi-01-admin
    HostName SERVER_IP
    User admin
    Port 22
    IdentityFile ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc
    IdentitiesOnly yes
```

### Safe pre-hardening flow

Рекомендуемый pre-hardening flow:

1. Подключитесь как `root` только для initial setup.
2. Создайте non-root admin user на сервере.
3. Добавьте admin public key `.pub` в `~admin/.ssh/authorized_keys`.
4. Откройте вторую SSH-сессию и проверьте вход как `admin`.
5. В новой сессии проверьте `sudo -v`.
6. Оставьте текущую root-сессию открытой до завершения hardening и проверки нового входа.
7. Запускайте `scripts/security/ssh-hardening.sh` или `scripts/02-security-baseline.sh --profile <profile>` только после успешной проверки non-root key access.

### Альтернативы ssh-copy-id для Windows

В native PowerShell `ssh-copy-id` обычно отсутствует. Безопасный fallback: вывести `.pub`, подключиться к серверу и добавить одну строку в `authorized_keys`.

Покажите public key в PowerShell:

```powershell
Get-Content "$env:USERPROFILE\.ssh\vps_vps-fi-01_admin_windows_laptop.pub"
```

На сервере добавляйте только public key:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
printf '%s\n' 'PASTE_PUBLIC_KEY_HERE' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Не используйте длинные remote one-liners для первого security-critical доступа, если не понимаете каждую команду. Пошаговое добавление проще проверить и безопаснее при ошибках ownership или permissions.

После добавления проверьте вход:

```powershell
ssh -i "$env:USERPROFILE\.ssh\vps_vps-fi-01_admin_windows_laptop" admin@SERVER_IP
```

Проверьте, что вы не добавили duplicate keys и что `authorized_keys` принадлежит нужному пользователю на сервере. Не вставляйте private key в `authorized_keys`.

## Deploy key

Deploy key используют для отдельного пользователя, например `deploy`, а не для `root` и не для human admin account.

Сгенерируйте ключ на deploy host или CI runner:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/deploy_prod-n8n_deploy_mini_pc \
  -C "ops@example.com | deploy | prod-n8n | deploy | mini-pc | 2026-05-16"
```

Policy:

- Deploy key должен принадлежать automation/deploy user с минимальными правами.
- Не используйте human admin key для CI, cron, backup jobs или server-to-GitHub access.
- Пустая passphrase допустима только там, где нет интерактивного ввода, например CI job или unattended deploy, и только при ограниченных правах пользователя.
- Для GitHub repository deploy key включайте write access только если automation действительно должна push-ить.
- При смене команды, сервера или CI runner удалите старый public key из GitHub/VPS и создайте новый.
- Если deploy private key скомпрометирован, сразу удалите соответствующий public key из `authorized_keys` и GitHub deploy keys.

## Backup/rescue key

Backup/rescue key нужен для восстановления доступа. Храните его отдельно, используйте passphrase и регулярно проверяйте, что он всё ещё работает.

Сгенерируйте ключ на доверенном устройстве или в безопасной offline-среде:

```bash
ssh-keygen -t ed25519 \
  -f ~/.ssh/backup_vps-fi-01_rescue_offline_usb \
  -C "admin@example.com | backup | vps-fi-01 | rescue | offline-usb | 2026-05-16"
```

Policy:

- Backup/rescue private key храните отдельно от ежедневной рабочей машины, например в password manager, encrypted offline storage или hardware-backed хранилище.
- Не добавляйте rescue key в повседневный `ssh-agent` без необходимости.
- Проверяйте rescue key после создания сервера, после hardening и после ротации пользователей.
- Документируйте только имя/назначение ключа и где добавлен его public key; private key material не записывайте в runbooks.
- При потере устройства удалите связанные public keys из всех GitHub accounts, deploy keys и server `authorized_keys`.

Если ключ больше не нужен или мог быть скомпрометирован, удалите его из `~/.ssh/authorized_keys` на сервере и из GitHub, если он там использовался.

## Ротация, reinstall и compromised keys

### Existing key

Существующий ключ можно использовать, если понятны его назначение, где он добавлен и есть ли passphrase. Проверьте права:

```bash
chmod 600 ~/.ssh/existing_private_key
chmod 644 ~/.ssh/existing_private_key.pub
```

Если назначение ключа неизвестно, безопаснее создать новый purpose-specific ключ.

### Compromised key

Если private key был скопирован наружу, попал в репозиторий, тикет, чат, backup без шифрования или на потерянное устройство:

1. Считайте ключ скомпрометированным.
2. Удалите соответствующий public key из GitHub account, repository deploy keys и всех server `authorized_keys`.
3. Создайте новую key pair с новым именем и комментарием.
4. Обновите `~/.ssh/config`, CI secrets или deploy host config.
5. Проверьте новый доступ и только потом удаляйте старые локальные references.

### VPS переустановлен или пересоздан

После переустановки VPS часто меняются server host key, user set, `authorized_keys` и иногда IP. Это не то же самое, что ваш client private key:

- Старый client private key — ваш локальный файл для подключения к старому серверу или старой роли.
- Новый client key — новая локальная пара, если вы решили ротировать доступ после пересоздания VPS.
- Server host key — ключ самого SSH-сервера; он хранится на клиенте в `known_hosts` для защиты от MITM.

Warning `REMOTE HOST IDENTIFICATION HAS CHANGED` нельзя игнорировать вслепую. Сначала подтвердите в панели провайдера или out-of-band канале, что VPS действительно переустановлен, пересоздан или получил новый host key. Если такой смены не было, остановитесь и расследуйте риск MITM.

Linux/macOS/Git Bash:

```bash
ssh-keygen -R SERVER_IP
ssh-keygen -R '[SERVER_IP]:PORT'
```

Windows PowerShell:

```powershell
ssh-keygen -R SERVER_IP
ssh-keygen -R '[SERVER_IP]:PORT'
notepad "$env:USERPROFILE\.ssh\known_hosts"
notepad "$env:USERPROFILE\.ssh\config"
```

Проверьте `~/.ssh/config` и замените старый key path:

```sshconfig
Host vps-fi-01-admin
    HostName SERVER_IP
    User admin
    Port 22
    IdentityFile ~/.ssh/old_key
    IdentitiesOnly yes
```

После ротации:

```sshconfig
Host vps-fi-01-admin
    HostName SERVER_IP
    User admin
    Port 22
    IdentityFile ~/.ssh/new_key
    IdentitiesOnly yes
```

Подключение с новым ключом:

```bash
ssh -i ~/.ssh/new_key user@SERVER_IP
```

Если вы создали новый client key после переустановки, заново добавьте новый `.pub` в `authorized_keys`. Удалите или закомментируйте старый `IdentityFile`, если он больше не используется. Не удаляйте весь `known_hosts` без необходимости: удаляйте только запись конкретного `SERVER_IP` или `[SERVER_IP]:PORT`.

## Перед SSH hardening

Перед запуском `scripts/security/ssh-hardening.sh` или `scripts/02-security-baseline.sh --profile <profile>` проверьте non-root key access:

```bash
ssh -i ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc admin@SERVER_IP
```

Проверьте `sudo`:

```bash
sudo -v
```

Держите текущую SSH-сессию открытой, пока не проверите новый вход во второй SSH-сессии. Скрипт делает backup `/etc/ssh/sshd_config`, запускает `sshd -t` и откатывает config при ошибке. Если non-root `authorized_keys` не найден, script не отключает root/password login и печатает warning.

Если SSH port изменён, сначала разрешите новый порт в firewall и только потом перезапускайте SSH. Для `proxy`/x-ui service ports не открывайте порты заранее; используйте явный `--allow-port <port>` или ручное документированное правило после того, как порт известен.

## Troubleshooting

### GitHub: `Permission denied (publickey)`

```bash
ssh -vT git@github.com
ssh-add -l
git remote -v
```

Если используется alias, remote должен ссылаться на alias:

```bash
git remote set-url origin git@github-rokolslab:RokolsLab/install_ubuntu.git
```

Проверьте, что remote использует `github-rokolslab`, если вы настраивали alias, и что public key добавлен в нужный GitHub account, а не как deploy key в другом repository.

### VPS: wrong key, user или port

Проверьте key path, user и port:

```bash
ssh -i ~/.ssh/vps_vps-fi-01_root_ubuntu_pc -p 22 root@SERVER_IP
ssh -i ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc -p 22 admin@SERVER_IP
```

Если сервер использует другой порт, обновите `Port` в `~/.ssh/config` и UFW rules на сервере.

### Agent has no identities

Linux/macOS/Git Bash:

```bash
ssh-add -l
ssh-add ~/.ssh/github_rokolslab_admin_ubuntu_pc
```

PowerShell:

```powershell
Get-Service ssh-agent
Start-Service ssh-agent
ssh-add "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop"
ssh-add -l
```

### Bad permissions или ACL

Linux/macOS/Git Bash:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc
chmod 644 ~/.ssh/vps_vps-fi-01_admin_ubuntu_pc.pub
```

Windows checks:

```powershell
ssh-add -l
icacls "$env:USERPROFILE\.ssh\github_rokolslab_admin_windows_laptop"
ssh -vvv -i "$env:USERPROFILE\.ssh\vps_vps-fi-01_admin_windows_laptop" admin@SERVER_IP
```

### Changed host key после VPS reinstall

Если видите `REMOTE HOST IDENTIFICATION HAS CHANGED`, сначала подтвердите reinstall/recreate у провайдера. Только после подтверждения удалите конкретную stale запись через `ssh-keygen -R SERVER_IP` или `ssh-keygen -R '[SERVER_IP]:PORT'`.

### Stale `IdentityFile` в SSH config

Если вы создали новый client key, но SSH продолжает выбирать старый, проверьте `IdentityFile` в `~/.ssh/config` или `$env:USERPROFILE\.ssh\config`. Для диагностики используйте verbose mode:

```bash
ssh -vvv vps-fi-01-admin
```

### UFW/fail2ban implications

Если SSH port изменён, проверьте firewall rule для нового порта до перезапуска SSH. Если было много неудачных попыток, проверьте fail2ban на сервере через активную сессию или rescue console.

## Что нельзя делать

- Не копируйте private keys в GitHub, чаты, тикеты, email или репозитории.
- Не добавляйте в GitHub файл без `.pub`.
- Не вставляйте private key в `authorized_keys`.
- Не коммитьте `~/.ssh`, private keys, `.env` и backup secrets.
- Не используйте один ключ для всех сценариев, если доступы можно разделить.
- Не оставляйте старые или скомпрометированные ключи в GitHub и `authorized_keys`.
- Не удаляйте blindly `known_hosts`, если не подтвердили причину смены host key.
- Не запускайте SSH hardening до проверки non-root key access во второй SSH-сессии и `sudo -v`.

## See Also

- [Server Security](01-server-security.md) — SSH, UFW и fail2ban baseline.
- [Security Hardening Details](01-server-security-hardening.md) — advanced SSH hardening notes.
- [Scripts Catalog](scripts-catalog.md) — где используется SSH key setup в profile flows.
- [Scripts Order](15-scripts-order.md) — канонический порядок запуска scripts.
