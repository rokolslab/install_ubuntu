#!/bin/bash

# Compatibility wrapper for the historical security entry point.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/02-secure-server.sh --profile minimal|proxy|docker-host|web|ai-stack [--allow-port <port>]

Deprecated compatibility wrapper. Новый entry point:
  sudo bash scripts/02-security-baseline.sh --profile <profile>
USAGE
}

has_profile_arg() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      --profile|--profile=*) return 0 ;;
    esac
  done

  return 1
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    exit 0
  fi

  if ! has_profile_arg "$@"; then
    log_error "Профиль не указан. Старый script больше не выбирает небезопасный default."
    print_usage
    exit 1
  fi

  log_warn "scripts/02-secure-server.sh deprecated; используйте scripts/02-security-baseline.sh"
  log_info "Вызываю новый security baseline entry point"
  exec bash "$SCRIPT_DIR/02-security-baseline.sh" "$@"
}

main "$@"
