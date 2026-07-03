# План: аудит и усиление `docs/ssh-keys.md`

Дата создания: 2026-06-07
Режим: fast
Ветка: текущая `main`

## Settings

- Testing: docs checks включены.
- Logging: не требуется runtime logging; для каждой задачи фиксировать проверочные заметки в итоговом diff/commit summary без вывода secrets.
- Docs: mandatory docs checkpoint после реализации.
- Scope: только документация по SSH-ключам и связанные cross-links, без изменения поведения scripts.

## Цель

Провести аудит и углубить `docs/ssh-keys.md`, чтобы документ был безопасным и понятным для пользователей Linux/macOS, Windows PowerShell/OpenSSH, Git Bash/WSL и PuTTY/Pageant. Документ должен снижать риск потери SSH-доступа перед hardening, объяснять различия между GitHub keys, VPS/root/admin keys, deploy keys и backup/rescue keys, показывать Windows-совместимые команды там, где текущие Unix-команды неприменимы, и покрывать сценарий переустановленного VPS со старыми SSH references на клиенте.

## Контекст аудита

- Текущий документ в основном Unix-oriented: `~/.ssh`, `chmod`, `cat`, `ssh-copy-id`, Bash snippets.
- Windows-specific guidance отсутствует: PowerShell paths, Windows OpenSSH, `ssh-agent` service, ACL permissions, Git Bash caveats, PuTTY/Pageant.
- Важная связь с hardening недообъяснена: `scripts/security/ssh-hardening.sh` безопасно отключает root/password login только при проверенном non-root key access.
- `scripts/01-setup-ssh-keys.sh` Bash-oriented; это нужно явно указать для Windows-клиентов.
- Пользователю нужно явно объяснить смысл составных частей имени ключа: `purpose`, `account-or-server`, `user/role`, `device`.
- Частый operational case: VPS переустановлен, host key изменился, в `known_hosts`/SSH config остались старые записи, а пользователь создал новый client key.

## Tasks

### Phase 1: Audit Structure And Safety Gaps

1. [x] Зафиксировать целевую структуру `docs/ssh-keys.md` перед правкой.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: обновлённый порядок разделов: overview, platform matrix, naming/comment standards, Linux/macOS, Windows OpenSSH/PowerShell, Git Bash/WSL, PuTTY/Pageant, GitHub, VPS/root/admin, deploy, backup/rescue, reinstall/recovery scenarios, pre-hardening checklist, troubleshooting, forbidden actions.
   - Expected behavior: документ остаётся self-contained и не превращает README в manual.
   - Logging/reporting: в итоговом summary отметить, какие разделы были переставлены или добавлены; secrets не выводить.
   - Dependencies: нет.

2. [x] Углубить объяснение составных частей имени SSH-ключа.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: добавить понятное пояснение формата имени, например `<purpose>_<target>_<role-or-user>_<device>` или текущего короткого `<purpose>_<account-or-server>_<device>`, с расшифровкой `purpose`, `account-or-server/target`, `role/user`, `device`; показать хорошие и плохие примеры.
   - Expected behavior: пользователь понимает, что имя ключа отвечает на вопросы “для чего?”, “куда/к какому аккаунту?”, “какая роль?”, “с какого устройства?”, и может безопасно найти ключи для ротации после потери устройства или смены VPS.
   - Logging/reporting: в summary отметить добавленную naming rationale; не использовать реальные email, IP или private key material.
   - Dependencies: Task 1.

3. [x] Усилить safety model для private/public keys.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: добавить объяснение, где генерируется private key, куда копируется только `.pub`, как отличать private/public key, почему нельзя хранить private key на VPS/GitHub/в репозитории.
   - Expected behavior: пользователь понимает, что команды чтения/копирования должны использовать только `.pub`, кроме локального использования private key в `ssh -i`.
   - Logging/reporting: в summary отметить добавленные safety warnings; реальные ключи или fingerprint values не приводить.
   - Dependencies: Task 1.

### Phase 2: Add Windows Client Coverage

4. [x] Добавить раздел Windows OpenSSH и PowerShell.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: команды для `ssh-keygen`, просмотра `.pub` через `Get-Content`, подключения через `ssh -i`, путь `$env:USERPROFILE\.ssh`, config path `C:\Users\<User>\.ssh\config`.
   - Expected behavior: Windows-пользователь может выполнить базовый GitHub/VPS flow без Git Bash и без Unix-only команд.
   - Logging/reporting: в summary перечислить Windows commands, которые были добавлены; не выводить private key contents.
   - Dependencies: Task 1.

5. [x] Добавить Windows `ssh-agent` и permissions/ACL guidance.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: команды `Get-Service ssh-agent`, `Set-Service ssh-agent -StartupType Automatic`, `Start-Service ssh-agent`, `ssh-add`, `ssh-add -l`; предупреждение про `UNPROTECTED PRIVATE KEY FILE` и ограничение доступа к private key текущим пользователем.
   - Expected behavior: документ объясняет, почему Unix `chmod` не равен Windows ACL и что делать при ошибках permissions.
   - Logging/reporting: в summary отметить, что ACL guidance добавлен как безопасная рекомендация без агрессивных destructive команд.
   - Dependencies: Task 4.

6. [x] Добавить альтернативы `ssh-copy-id` для Windows.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: объяснить, что `ssh-copy-id` обычно отсутствует в native PowerShell; дать безопасный вариант ручного добавления `.pub` в `authorized_keys` и PowerShell pipeline/SSH fallback, если подходит.
   - Expected behavior: Windows-пользователь может добавить публичный ключ на VPS без установки дополнительных Unix tools.
   - Logging/reporting: в summary отметить выбранный способ и предупреждение о duplicate keys/ownership.
   - Dependencies: Task 4.

7. [x] Добавить Git Bash, WSL и PuTTY/Pageant notes.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: коротко описать, когда использовать Git Bash/WSL, что `~/.ssh` в Git Bash мапится на Windows home, что PuTTY использует `.ppk`, PuTTYgen/Pageant применимы для PuTTY/Plink workflows, а Git for Windows обычно проще с OpenSSH keys.
   - Expected behavior: документ помогает выбрать инструмент, не смешивая incompatible key formats.
   - Logging/reporting: в summary отметить ограничения Git Bash/WSL/PuTTY; не рекомендовать конвертацию private key без passphrase.
   - Dependencies: Task 4.

### Phase 3: Strengthen Server, GitHub And Recovery Flows

8. [x] Углубить GitHub key and alias flow для разных платформ.
   - Files: `docs/ssh-keys.md`.
   - Deliverable: сохранить canonical `RokolsLab` examples, добавить проверку `ssh -T git@github.com` / alias из PowerShell и Git Bash, объяснить `Host github-rokolslab` и `git remote set-url`.
   - Expected behavior: пользователь понимает разницу между GitHub account SSH key и repository deploy key.
   - Logging/reporting: в summary отметить alias/remote examples; не использовать реальные email/token values.
   - Dependencies: Tasks 4, 7.

9. [x] Добавить полноценный VPS/root/admin pre-hardening flow.
   - Files: `docs/ssh-keys.md`, возможно cross-link на `docs/01-server-security.md` и `docs/01-server-security-hardening.md`.
   - Deliverable: пошагово описать root key, создание non-root admin/deploy user, добавление public key, проверку второго SSH-сеанса, проверку `sudo`, сохранение текущей сессии открытой перед hardening.
   - Expected behavior: пользователь не запускает SSH hardening, пока не проверил non-root key access и recovery path.
   - Logging/reporting: в summary отметить added lockout-prevention checklist; не включать реальные server IP.
   - Dependencies: Task 3.

10. [x] Добавить сценарий “VPS переустановлен или пересоздан”.
    - Files: `docs/ssh-keys.md`.
    - Deliverable: объяснить разницу между старым client private key, новым client key и server host key; описать, что после переустановки VPS часто нужно удалить старый host key из `known_hosts`, обновить SSH config aliases при смене IP/user/key path, заново добавить новый `.pub` в `authorized_keys`, и удалить/закомментировать ссылки на старый private key.
    - Expected behavior: пользователь понимает, что warning `REMOTE HOST IDENTIFICATION HAS CHANGED` нельзя игнорировать вслепую; сначала надо подтвердить, что VPS действительно переустановлен/пересоздан, затем очистить старую запись и проверить новый fingerprint.
    - Linux/macOS/Git Bash commands: включить `ssh-keygen -R SERVER_IP`, `ssh-keygen -R '[SERVER_IP]:PORT'`, проверку/редактирование `~/.ssh/config`, пример замены `IdentityFile ~/.ssh/old_key` на новый key path, подключение `ssh -i ~/.ssh/new_key user@SERVER_IP`.
    - Windows PowerShell commands: включить `ssh-keygen -R SERVER_IP`, `ssh-keygen -R '[SERVER_IP]:PORT'`, путь `$env:USERPROFILE\.ssh\known_hosts`, редактирование `$env:USERPROFILE\.ssh\config`, подключение `ssh -i "$env:USERPROFILE\.ssh\new_key" user@SERVER_IP`.
    - Logging/reporting: в summary отметить добавленный reinstall recovery flow; не включать реальные IP, fingerprints или private key contents.
    - Dependencies: Tasks 4, 6, 9.

11. [x] Уточнить deploy и backup/rescue key policy.
    - Files: `docs/ssh-keys.md`.
    - Deliverable: описать ограничения deploy keys, когда допустима empty passphrase, где хранить backup/rescue key, как ротировать и удалять скомпрометированные keys из GitHub/VPS.
    - Expected behavior: пользователь отделяет human admin access от automation/deploy access.
    - Logging/reporting: в summary отметить policy changes; не добавлять реальные secrets or credentials.
    - Dependencies: Task 3.

### Phase 4: Troubleshooting And Verification

12. [x] Расширить troubleshooting для Windows/Linux/macOS.
    - Files: `docs/ssh-keys.md`.
    - Deliverable: добавить симптомы и проверки: `Permission denied (publickey)`, wrong key selected, bad permissions/ACL, agent has no identities, GitHub alias mismatch, changed SSH port, UFW/fail2ban implications, stale `known_hosts` after VPS reinstall, stale `IdentityFile` in SSH config.
    - Expected behavior: пользователь получает route-to-fix без небезопасных советов вроде копирования private key на сервер или бездумного удаления host key без проверки причины.
    - Logging/reporting: в summary перечислить troubleshooting categories; не предлагать выводить private key.
    - Dependencies: Tasks 5, 6, 9, 10.

13. [x] Проверить cross-links и согласованность с project scripts.
    - Files: `docs/ssh-keys.md`, `docs/01-server-security.md`, `docs/01-server-security-hardening.md`, `docs/scripts-catalog.md` если понадобятся ссылки.
    - Deliverable: ссылки на relevant docs/scripts работают; документ честно говорит, что `scripts/01-setup-ssh-keys.sh` Bash-oriented и лучше подходит для Linux/macOS/WSL/Git Bash, не native PowerShell.
    - Expected behavior: документация не обещает Windows support в Bash script, если его нет в коде.
    - Logging/reporting: в summary отметить changed/added cross-links; никаких secrets.
    - Dependencies: Tasks 4-12.

14. [x] Провести mandatory docs checkpoint.
    - Files: `docs/ssh-keys.md` и любые затронутые docs.
    - Deliverable: финальная проверка readability, technical accuracy, internal links, canonical `RokolsLab` references, отсутствие secrets, отсутствие устаревших команд.
    - Expected behavior: `git diff --check` проходит; targeted grep не находит старые owner spellings или private-key anti-patterns.
    - Logging/reporting: в финальном ответе дать компактную таблицу проверок и residual risks.
    - Dependencies: Tasks 1-13.

## Acceptance Criteria

- `docs/ssh-keys.md` содержит отдельные Windows OpenSSH/PowerShell instructions.
- Документ объясняет Git Bash/WSL/PuTTY/Pageant tradeoffs без смешивания key formats.
- Есть безопасные альтернативы `ssh-copy-id` для Windows.
- Есть объяснение составных частей имени ключа и практическая причина каждой части.
- Есть сценарий “VPS переустановлен/пересоздан”: очистка stale `known_hosts`, обновление SSH config/`IdentityFile`, добавление нового `.pub` на сервер, команды для Linux/macOS/Git Bash и Windows PowerShell.
- Есть pre-hardening checklist с non-root key access, второй SSH-сессией и `sudo` verification.
- GitHub aliases и repository URLs используют canonical `RokolsLab` / `github-rokolslab`.
- Документ не выводит и не просит вставлять private key contents.
- Документ предупреждает не игнорировать `REMOTE HOST IDENTIFICATION HAS CHANGED` без подтверждения переустановки/смены host key.
- После реализации проходит `git diff --check` и targeted grep по stale owner spellings.

## Commit Plan

1. `docs(ssh): explain key naming and Windows setup`
   - Tasks 1-7.
2. `docs(ssh): strengthen vps recovery and hardening flows`
   - Tasks 8-14.

## Verification Status

- Status: ✅ Verified complete on 2026-07-03.
- Evidence: `docs/ssh-keys.md` contains the planned platform matrix, key naming rationale, private/public key safety model, Windows OpenSSH/PowerShell commands, Windows `ssh-agent`/ACL guidance, Git Bash/WSL/PuTTY/Pageant notes, GitHub alias flow, VPS pre-hardening checklist, deploy and backup/rescue policy, reinstall recovery flow and troubleshooting sections.
- Checks: `git diff --check` passed; `scripts/98-verify-scripts.sh` passed; targeted verification found no requirement in this plan left unchecked.
- Residual risk: this was a documentation-only plan; live SSH behavior still depends on user environment and target VPS state.

## Next Step

План выполнен и подтверждён. Следующий естественный шаг — архивировать план через `/aif-archive`, если он больше не нужен как активный fast plan.
