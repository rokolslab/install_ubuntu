# План: комплексные проверки proxy VPS

Дата создания: 2026-06-08
Режим: fast
Ветка: текущая `main`
Целевой сервер: SSH alias `vps-test-ai-test`
Профиль: `proxy`

## Settings

- Testing: включены runtime checks на test VPS и локальные script checks.
- Logging: сохранять краткие проверочные заметки в финальном summary; не выводить private keys, tokens, `.env` или чувствительные значения.
- Docs: warn-only; обновлять docs только если проверки выявят расхождение команд/требований.
- Scope: проверять только VPS profile flows, security scripts, readiness checks и безопасные negative paths; не устанавливать Docker/AI stack и не запускать production workloads.
- Safety: основной flow read-only/idempotent; изменяющие проверки выполнять только в явно отмеченном opt-in phase.

## Цель

Проверить на реальном маленьком Ubuntu 24.04 VPS всё, что разумно проверить для профиля `proxy`: доступ, ресурсы, preflight, idempotency security baseline, readiness, negative guards, reboot persistence, apt/dpkg health и безопасное поведение scripts при неподходящих профилях. Отдельно зафиксировать opt-in проверки, которые меняют firewall или состояние сервера.

## Контекст

- VPS уже доступен по `ssh vps-test-ai-test` под пользователем `ai-test`.
- `sudo -n` работает без пароля.
- Сервер малый: около 1GB RAM, около 5GB free disk после baseline, swap около 500MB.
- Профиль `proxy` не должен требовать Docker, compose или `.env`.
- `proxy` service ports не открываются автоматически; они должны открываться только через явный `--allow-port <port>`.
- Уже найден и исправлен bug: security apt operations должны быть noninteractive, иначе `apt upgrade -y` может зависнуть на conffile/needrestart flow.

## Tasks

### Phase 1: Local And Remote Baseline Checks

1. [x] Проверить локальное состояние репозитория перед VPS тестами.
   - Files: none; commands only.
   - Commands: `git status -sb`, `git log --oneline -5`, `bash scripts/98-verify-scripts.sh`, `git diff --check`.
   - Expected behavior: local scripts pass syntax/ShellCheck where available; no secrets in diff; untracked `.opencode/` and `.ai-factory.json` remain untouched.
   - Logging/reporting: summary должен указать branch/ahead status и локальные checks без вывода private key paths beyond alias-level context.
   - Dependencies: none.

2. [x] Проверить SSH, sudo и базовую диагностику VPS.
   - Files: none; remote commands only.
   - Commands: `ssh vps-test-ai-test 'whoami && sudo -n whoami && uptime'`, OS/resources/disk/swap checks, `sudo -n apt-get check`, `sudo -n dpkg --audit`.
   - Expected behavior: `whoami=ai-test`, sudo returns `root`, package manager healthy, resources соответствуют proxy constraints.
   - Logging/reporting: фиксировать только агрегированные ресурсы и package health; не выводить IP в финальном summary без необходимости.
   - Dependencies: Task 1.

3. [x] Обновить clean test copy на VPS из tracked files.
   - Files: remote `/home/ai-test/install_ubuntu-test-*` copy only.
   - Commands: use `git ls-files -z | tar --null -T - -czf - | ssh ... tar -xzf - -C <remote-dir>`.
   - Expected behavior: на VPS попадают только tracked files; local untracked `.opencode/` и `.ai-factory.json` не копируются.
   - Logging/reporting: указать remote test directory, но не публиковать secrets.
   - Dependencies: Task 1.

### Phase 2: Read-Only And Non-Mutating Script Checks

4. [x] Запустить verifier на VPS copy.
   - Files: scripts only; no modifications expected.
   - Commands: `bash scripts/98-verify-scripts.sh` on VPS copy.
   - Expected behavior: `bash -n` passes for all first-party scripts; ShellCheck may be skipped if not installed on VPS.
   - Logging/reporting: distinguish pass from skipped ShellCheck warning.
   - Dependencies: Task 3.

5. [x] Проверить preflight classification для всех relevant profiles.
   - Files: `scripts/00-preflight-check.sh` behavior only.
   - Commands: `sudo -n bash scripts/00-preflight-check.sh`, `--profile minimal`, `--profile proxy`, `--profile docker-host`, `--profile web`, `--profile ai-stack`.
   - Expected behavior: `minimal` and `proxy` are OK/WARN as appropriate; heavier profiles are NO on this VPS; Docker/.env warnings are non-blocking for minimal/proxy.
   - Logging/reporting: summary должен отметить exact profile states and resource thresholds.
   - Dependencies: Task 4.

6. [x] Проверить safe negative guards for wrong profiles.
   - Files: scripts behavior only; no lasting state expected.
   - Commands: `sudo -n bash scripts/03-install-docker.sh --profile minimal`, `sudo -n bash scripts/12-generate-secrets.sh --profile proxy`, selected `--help` commands.
   - Expected behavior: scripts refuse unsupported profiles with clear error messages and do not install Docker or generate `.env`.
   - Logging/reporting: capture exit category and key error text, not full noisy logs unless needed.
   - Dependencies: Task 5.

7. [x] Запустить readiness checks for `minimal` and `proxy`.
   - Files: `scripts/99-ready-checks.sh` behavior only.
   - Commands: `sudo -n bash scripts/99-ready-checks.sh --profile minimal`, `sudo -n bash scripts/99-ready-checks.sh --profile proxy`.
   - Expected behavior: checks pass; UFW active, SSH config valid, fail2ban active, unattended-upgrades active, RAM/swap acceptable.
   - Logging/reporting: summary должен отметить warnings like manual proxy service ports.
   - Dependencies: Task 5.

8. [x] Запустить read-only security audit.
   - Files: `scripts/security/audit.sh` behavior only.
   - Commands: `sudo -n bash scripts/security/audit.sh`.
   - Expected behavior: only SSH is publicly listening/open via UFW unless opt-in firewall tests were run; effective SSH config shows hardened values.
   - Logging/reporting: summarize open ports, UFW default policy, fail2ban jail count, SSH effective config.
   - Dependencies: Task 7.

### Phase 3: Idempotency Checks That May Touch Config But Should Preserve Access

9. [x] Повторно запустить idempotent `proxy` security baseline.
   - Files: remote system config; no repo changes expected.
   - Commands: `sudo -n bash scripts/02-security-baseline.sh --profile proxy`.
   - Expected behavior: completes without interactive apt prompts, preserves SSH access, does not open proxy service ports automatically, leaves package manager healthy.
   - Logging/reporting: note apt noninteractive behavior, UFW preserved SSH, SSH hardening backup creation, fail2ban restart.
   - Dependencies: Task 8.

10. [x] Проверить отдельные security modules idempotently.
    - Files: remote system config; no repo changes expected.
    - Commands: `firewall.sh --profile proxy`, `ssh-hardening.sh`, `fail2ban.sh`, `unattended-upgrades.sh`, `sysctl-hardening.sh`.
    - Expected behavior: each module reruns cleanly, keeps SSH reachable, no Docker/compose dependency appears.
    - Logging/reporting: run one module at a time and verify SSH after SSH/firewall modules.
    - Dependencies: Task 9.

11. [x] Проверить deprecated compatibility wrapper.
    - Files: remote system config; no repo changes expected.
    - Commands: `sudo -n bash scripts/02-secure-server.sh --profile proxy`.
    - Expected behavior: wrapper routes to current security baseline or reports deprecation clearly; final state remains equivalent to `02-security-baseline.sh`.
    - Logging/reporting: note wrapper behavior and any deprecation warning.
    - Dependencies: Task 9.

12. [x] Проверить reboot persistence после idempotency checks.
    - Files: remote system state only.
    - Commands: check `/var/run/reboot-required`; if reboot required, ask user before reboot; after reboot verify SSH, UFW, fail2ban, unattended-upgrades, ready checks.
    - Expected behavior: after reboot, SSH key access works, password/root login stay disabled, UFW/fail2ban persist.
    - Logging/reporting: do not reboot without explicit confirmation; include downtime/SSH wait result if reboot happens.
    - Dependencies: Tasks 9-11.

### Phase 4: Opt-In Mutating Checks

13. [x] Opt-in: проверить explicit proxy service port allow/remove.
    - Files: remote firewall state only.
    - Commands: run `sudo -n bash scripts/security/firewall.sh --profile proxy --allow-port 12345/tcp`, verify UFW rule, then remove the test rule manually and verify it is gone.
    - Expected behavior: proxy opens only explicitly requested port; cleanup removes test port; SSH stays limited/open.
    - Logging/reporting: execute only after user confirms; summary must mention rule cleanup status.
    - Dependencies: Task 8.

14. [x] Opt-in: проверить swap module skip/create behavior.
    - Files: remote swap state only.
    - Commands: inspect current swap; run `scripts/security/swap.sh` only if user approves changing swap.
    - Expected behavior: existing swap is detected and not destructively recreated unless explicit force flag is used.
    - Logging/reporting: no force-recreate without explicit approval.
    - Dependencies: Task 2.

15. Opt-in: cleanup test access and remote test directory. (Skipped: access retained by user choice.)
    - Files: remote `/home/ai-test/install_ubuntu-test-*`, `/etc/sudoers.d/90-ai-test`, user `ai-test`.
    - Commands: remove only after user confirms tests are complete and no more access is needed.
    - Expected behavior: test artifacts/access removed safely; no production user/data touched.
    - Logging/reporting: provide exact cleanup commands before execution.
    - Dependencies: all selected test tasks.

## Acceptance Criteria

- Local `scripts/98-verify-scripts.sh` passes.
- VPS verifier passes or only warns that ShellCheck is absent.
- `00-preflight-check.sh --profile proxy` returns `OK` on this VPS with current relaxed disk minimum.
- `minimal` and `proxy` readiness checks pass.
- Heavier profiles are refused or classified `NO` without installing Docker/compose.
- Security baseline is idempotent and noninteractive.
- SSH remains reachable after firewall/SSH hardening and optional reboot.
- UFW opens SSH only by default for `proxy`; proxy service ports require explicit `--allow-port`.
- `fail2ban` and `unattended-upgrades` are active.
- Package manager health is clean: `apt-get check` passes and `dpkg --audit` has no actionable errors.
- No secrets/private keys/`.env` values are printed or copied into artifacts.

## Commit Plan

1. `test(vps): validate proxy profile checks`
   - Tasks 1-8.
2. `test(vps): verify proxy hardening idempotency`
   - Tasks 9-12.
3. `test(vps): document opt-in mutating checks`
   - Tasks 13-15 if executed or if docs/scripts need updates from findings.

## Next Step

Для выполнения безопасной части плана:

```text
/aif-implement
```

Перед opt-in задачами 13-15 требуется отдельное подтверждение пользователя.
