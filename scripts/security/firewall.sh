#!/bin/bash

# Configure UFW defaults and profile-aware public ports.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

ALLOW_PORTS=()

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/security/firewall.sh --profile minimal|proxy|docker-host|web|ai-stack [--allow-port <port>]

По умолчанию открывается только SSH. Порты 80/443 открываются только для web/ai-stack.
Для proxy/x-ui указывайте service ports явно через --allow-port <port>.
USAGE
}

detect_ssh_port() {
  local port

  port="$(sshd -T 2> /dev/null | awk '$1 == "port" {print $2; exit}' || true)"
  if [ -z "$port" ]; then
    port="$(awk 'tolower($1) == "port" {print $2; exit}' /etc/ssh/sshd_config 2> /dev/null || true)"
  fi

  SSH_PORT="${port:-22}"
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
        ALLOW_PORTS+=("$2")
        shift 2
        ;;
      --allow-port=*)
        ALLOW_PORTS+=("${1#--allow-port=}")
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
}

allow_port() {
  local port="$1"
  local comment="$2"

  if ! [[ "$port" =~ ^[0-9]+(/tcp)?$ ]]; then
    log_error "Некорректный порт: $port"
    exit 1
  fi

  ufw allow "$port" comment "$comment"
  log_info "Открыт порт: $port ($comment)"
}

main() {
  parse_args "$@"
  require_root
  detect_ssh_port

  if [ -z "$SSH_PORT" ]; then
    log_error "Не удалось определить SSH port"
    exit 1
  fi

  log_info "Старт firewall hardening"
  if ! command -v ufw &> /dev/null; then
    apt_noninteractive install -y ufw
  fi

  ufw default deny incoming
  ufw default allow outgoing
  ufw allow "${SSH_PORT}/tcp" comment 'SSH'
  ufw limit "${SSH_PORT}/tcp" comment 'SSH Rate Limit'
  log_info "SSH port сохранён в UFW: ${SSH_PORT}/tcp"

  case "${PROFILE:-}" in
    web|ai-stack)
      allow_port "80/tcp" "HTTP"
      allow_port "443/tcp" "HTTPS"
      ;;
    proxy)
      log_warn "Профиль proxy не открывает service ports автоматически; используйте --allow-port <port>"
      ;;
    "")
      log_warn "Профиль не указан; открываю только SSH"
      ;;
  esac

  local port
  for port in "${ALLOW_PORTS[@]}"; do
    allow_port "$port" "Explicit allow"
  done

  ufw --force enable
  ufw status verbose
  log_info "Firewall hardening завершён"
}

main "$@"
