#!/bin/bash

# Apply conservative SSH hardening with config validation and rollback.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_DROPIN="/etc/ssh/sshd_config.d/00-install-ubuntu-hardening.conf"
SSHD_BACKUP=""

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/security/ssh-hardening.sh

Скрипт делает backup sshd_config, применяет безопасные SSH options, проверяет sshd -t и выполняет rollback при ошибке.
PermitRootLogin no и PasswordAuthentication no применяются только если подтверждён non-root key access.
USAGE
}

restart_ssh_service() {
  local service_name="ssh"

  if systemctl list-unit-files sshd.service &> /dev/null; then
    service_name="sshd"
  fi

  systemctl restart "$service_name"
}

set_sshd_option() {
  local key="$1"
  local value="$2"

  if grep -Eq "^[#[:space:]]*${key}[[:space:]]+" "$SSHD_CONFIG"; then
    sed -i -E "s|^[#[:space:]]*${key}[[:space:]]+.*|${key} ${value}|" "$SSHD_CONFIG"
  else
    printf '\n%s %s\n' "$key" "$value" >> "$SSHD_CONFIG"
  fi
}

write_hardening_dropin() {
  local include_password_lockdown="$1"

  mkdir -p "$(dirname "$SSHD_DROPIN")"
  {
    printf '# Managed by install_ubuntu ssh-hardening.sh\n'
    printf 'PermitEmptyPasswords no\n'
    printf 'MaxAuthTries 3\n'
    if [ "$include_password_lockdown" = "1" ]; then
      printf 'PermitRootLogin no\n'
      printf 'PasswordAuthentication no\n'
    fi
  } > "$SSHD_DROPIN"
}

has_non_root_key_access() {
  [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ] && [ -s "/home/${SUDO_USER}/.ssh/authorized_keys" ]
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    exit 0
  fi

  require_root
  log_info "Старт SSH hardening"

  SSHD_BACKUP="${SSHD_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$SSHD_CONFIG" "$SSHD_BACKUP"
  log_info "Backup SSH config: $SSHD_BACKUP"

  set_sshd_option "PermitEmptyPasswords" "no"
  set_sshd_option "MaxAuthTries" "3"

  if has_non_root_key_access; then
    log_warn "Обнаружен non-root key access для ${SUDO_USER}; отключаю root/password login"
    set_sshd_option "PermitRootLogin" "no"
    set_sshd_option "PasswordAuthentication" "no"
    write_hardening_dropin "1"
  else
    log_warn "Non-root key access не подтверждён; пропускаю PermitRootLogin no и PasswordAuthentication no, чтобы не потерять доступ"
    write_hardening_dropin "0"
  fi

  if sshd -t; then
    log_info "Конфигурация SSH проверена успешно"
    restart_ssh_service
    log_info "SSH service перезапущен"
  else
    log_error "SSH config невалиден; выполняю rollback"
    cp "$SSHD_BACKUP" "$SSHD_CONFIG"
    sshd -t || true
    exit 1
  fi

  log_info "SSH hardening завершён"
}

main "$@"
