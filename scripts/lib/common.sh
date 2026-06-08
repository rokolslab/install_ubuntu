#!/bin/bash

# Shared helpers for project scripts. Source this file; do not execute it directly.

if [ -n "${INSTALL_UBUNTU_COMMON_SH_LOADED:-}" ]; then
  return 0 2> /dev/null || exit 0
fi
INSTALL_UBUNTU_COMMON_SH_LOADED=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SUPPORTED_PROFILES="minimal proxy docker-host web ai-stack"

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

require_root() {
  if [ "${EUID}" -ne 0 ]; then
    log_error "Пожалуйста, запустите скрипт с правами root или через sudo"
    exit 1
  fi
}

apt_noninteractive() {
  DEBIAN_FRONTEND=noninteractive \
  NEEDRESTART_MODE=a \
  apt-get \
    -o Dpkg::Options::=--force-confdef \
    -o Dpkg::Options::=--force-confold \
    "$@"
}

detect_os() {
  OS_NAME="unknown"
  OS_VERSION="unknown"

  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_NAME="${ID:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"
  fi

  ARCH="$(uname -m)"
  log_info "Обнаружена ОС: ${OS_NAME} ${OS_VERSION}, архитектура: ${ARCH}"
}

detect_resources() {
  RAM_MB="$(free -m | awk '/Mem:/{print $2}')"
  DISK_GB="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
  CPU_COUNT="$(nproc)"
  SWAP_MB="$(free -m | awk '/Swap:/{print $2}')"

  log_info "Ресурсы: CPU=${CPU_COUNT}, RAM=${RAM_MB}MB, disk_free=${DISK_GB}GB, swap=${SWAP_MB}MB"
}

is_supported_profile() {
  local profile="$1"
  local supported_profile

  for supported_profile in $SUPPORTED_PROFILES; do
    if [ "$profile" = "$supported_profile" ]; then
      return 0
    fi
  done

  return 1
}

parse_profile() {
  PROFILE=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        if [ "$#" -lt 2 ]; then
          log_error "Опция --profile требует значение: $SUPPORTED_PROFILES"
          exit 1
        fi
        PROFILE="$2"
        shift 2
        ;;
      --profile=*)
        PROFILE="${1#--profile=}"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ -n "$PROFILE" ] && ! is_supported_profile "$PROFILE"; then
    log_warn "Неизвестный профиль: $PROFILE"
    log_error "Поддерживаемые профили: $SUPPORTED_PROFILES"
    exit 1
  fi

  if [ -n "$PROFILE" ]; then
    log_info "Выбран профиль: $PROFILE"
  else
    log_info "Профиль не указан; будет показана сводка по всем профилям"
  fi
}

print_profile_summary() {
  cat <<'SUMMARY'

Доступные профили:

Profile      Назначение
minimal      Базовая безопасность маленького VPS
proxy        VPS для x-ui/3x-ui/VPN/proxy panel без автооткрытия service ports
docker-host  Minimal security baseline + Docker host
web          Небольшой web/app VPS с 80/443 и reverse proxy path
ai-stack     Полный AI automation stack: Docker Compose, n8n, Supabase, Redis
SUMMARY
}
