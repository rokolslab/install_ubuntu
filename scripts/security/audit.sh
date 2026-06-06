#!/bin/bash

# Print a compact security status report without changing the system.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

log_info "Security audit summary"

echo
log_info "Open listening ports"
ss -tulpn || true

echo
log_info "UFW status"
if command -v ufw &> /dev/null; then
  ufw status verbose || true
else
  log_warn "ufw не установлен"
fi

echo
log_info "fail2ban status"
if systemctl is-active --quiet fail2ban; then
  fail2ban-client status || true
else
  log_warn "fail2ban не активен"
fi

echo
log_info "unattended-upgrades status"
systemctl status unattended-upgrades --no-pager | sed -n '1,5p' || true

echo
log_info "SSH effective config"
sshd -T 2> /dev/null | grep -E "^(permitrootlogin|passwordauthentication|port|maxauthtries)" || true
