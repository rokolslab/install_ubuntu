#!/bin/bash

# Install package metadata updates and safe security baseline upgrades.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

require_root

log_info "Старт system updates"
apt update
apt upgrade -y
apt autoremove -y
log_info "System updates завершены"
