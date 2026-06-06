#!/bin/bash

# Orchestrate baseline security modules for a selected VPS profile.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECURITY_DIR="$SCRIPT_DIR/security"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

ALLOW_ARGS=()

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/02-security-baseline.sh --profile minimal|proxy|docker-host|web|ai-stack [--allow-port <port>]

Этот script применяет только security baseline. Он не устанавливает Docker, Nginx, Supabase, Redis или n8n.
USAGE
}

parse_args() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    exit 0
  fi

  parse_profile "$@"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --allow-port)
        if [ "$#" -lt 2 ]; then
          log_error "Опция --allow-port требует номер порта"
          exit 1
        fi
        ALLOW_ARGS+=("--allow-port" "$2")
        shift 2
        ;;
      --allow-port=*)
        ALLOW_ARGS+=("--allow-port" "${1#--allow-port=}")
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ -z "$PROFILE" ]; then
    log_error "Укажите --profile: $SUPPORTED_PROFILES"
    exit 1
  fi
}

run_module() {
  local module="$1"
  shift || true

  log_info "Запуск security module: $module"
  bash "$SECURITY_DIR/$module" "$@"
  log_info "Module completed: $module"
}

main() {
  parse_args "$@"
  require_root

  log_info "=== Security baseline: $PROFILE ==="
  log_warn "Проверьте SSH-доступ в отдельной сессии перед hardening, чтобы не потерять доступ"

  run_module "system-updates.sh"
  run_module "firewall.sh" --profile "$PROFILE" "${ALLOW_ARGS[@]}"
  run_module "ssh-hardening.sh"
  run_module "fail2ban.sh"
  run_module "unattended-upgrades.sh"
  run_module "sysctl-hardening.sh"

  case "$PROFILE" in
    minimal|proxy|docker-host|web|ai-stack)
      log_info "Security baseline применён для профиля $PROFILE"
      ;;
  esac

  log_warn "Optional audit можно запустить отдельно: sudo bash scripts/security/audit.sh"
  log_info "Security baseline завершён"
}

main "$@"
