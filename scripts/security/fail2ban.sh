#!/bin/bash

# Install and configure a minimal fail2ban sshd jail.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

require_root

log_info "Старт fail2ban setup"
apt_noninteractive install -y fail2ban

if [ -f /etc/fail2ban/jail.local ]; then
  cp /etc/fail2ban/jail.local "/etc/fail2ban/jail.local.backup.$(date +%Y%m%d_%H%M%S)"
  log_info "Создан backup текущего jail.local"
fi

cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

systemctl enable fail2ban
systemctl restart fail2ban

if systemctl is-active --quiet fail2ban; then
  log_info "fail2ban установлен и запущен"
else
  log_error "fail2ban не запустился. Проверьте: journalctl -u fail2ban"
  systemctl status fail2ban --no-pager || true
  exit 1
fi
