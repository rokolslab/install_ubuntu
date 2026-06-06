#!/bin/bash

# Profile-aware preflight check before changing a VPS/server.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/docker-compose/.env"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/00-preflight-check.sh [--profile minimal|proxy|docker-host|web|ai-stack]

Без --profile скрипт показывает пригодность сервера для всех профилей.
USAGE
}

profile_requirements() {
  local profile="$1"

  case "$profile" in
    minimal) echo "512 5" ;;
    proxy) echo "512 10" ;;
    docker-host) echo "1024 10" ;;
    web) echo "1024 15" ;;
    ai-stack) echo "4096 50" ;;
    *) return 1 ;;
  esac
}

profile_description() {
  local profile="$1"

  case "$profile" in
    minimal) echo "базовая безопасность" ;;
    proxy) echo "proxy/x-ui без автооткрытия service ports" ;;
    docker-host) echo "Docker host" ;;
    web) echo "web/app VPS" ;;
    ai-stack) echo "n8n/Supabase/Redis stack" ;;
    *) echo "unknown" ;;
  esac
}

profile_status() {
  local profile="$1"
  local required_ram required_disk

  read -r required_ram required_disk < <(profile_requirements "$profile")

  if [ "$RAM_MB" -lt "$required_ram" ] || [ "$DISK_GB" -lt "$required_disk" ]; then
    echo "NO"
    return 0
  fi

  case "$profile" in
    docker-host)
      if [ "$RAM_MB" -lt 1536 ] || [ "$SWAP_MB" -eq 0 ]; then
        echo "WARN"
      else
        echo "OK"
      fi
      ;;
    web)
      if [ "$RAM_MB" -lt 2048 ] || [ "$SWAP_MB" -eq 0 ]; then
        echo "WARN"
      else
        echo "OK"
      fi
      ;;
    ai-stack)
      if [ "$CPU_COUNT" -lt 2 ] || [ "$SWAP_MB" -eq 0 ]; then
        echo "WARN"
      else
        echo "OK"
      fi
      ;;
    *)
      echo "OK"
      ;;
  esac
}

profile_recommendation() {
  local profile="$1"
  local status="$2"
  local required_ram required_disk

  read -r required_ram required_disk < <(profile_requirements "$profile")

  if [ "$status" = "NO" ]; then
    echo "нужно минимум ${required_ram}MB RAM и ${required_disk}GB disk; не запускайте этот профиль"
    return 0
  fi

  case "$profile" in
    proxy)
      echo "service ports открывайте явно через firewall --allow-port <port>"
      ;;
    docker-host)
      if [ "$status" = "WARN" ]; then
        echo "желательно включить swap перед Docker workloads"
      else
        echo "можно запускать Docker install"
      fi
      ;;
    web)
      if [ "$status" = "WARN" ]; then
        echo "для стабильности web/app включите swap или увеличьте RAM"
      else
        echo "можно открывать 80/443 через web profile"
      fi
      ;;
    ai-stack)
      if [ "$status" = "WARN" ]; then
        echo "ai-stack ресурсоёмкий; проверьте CPU/swap и нагрузку"
      else
        echo "ресурсы подходят для полного compose stack"
      fi
      ;;
    *)
      echo "можно запускать security baseline"
      ;;
  esac
}

print_profile_row() {
  local profile="$1"
  local status recommendation

  status="$(profile_status "$profile")"
  recommendation="$(profile_recommendation "$profile" "$status")"
  printf '%-12s %-5s %-42s %s\n' "$profile" "$status" "$(profile_description "$profile")" "$recommendation"
}

print_profile_matrix() {
  echo
  printf '%-12s %-5s %-42s %s\n' "Profile" "State" "Назначение" "Рекомендация"
  printf '%-12s %-5s %-42s %s\n' "-------" "-----" "----------" "------------"

  local profile
  for profile in $SUPPORTED_PROFILES; do
    print_profile_row "$profile"
  done
  echo
}

check_os_support() {
  if [ "$OS_NAME" != "ubuntu" ]; then
    log_error "ОС должна быть Ubuntu Server 22.04 LTS или 24.04 LTS (обнаружено: ${OS_NAME} ${OS_VERSION})"
    exit 1
  fi

  if [ "$OS_VERSION" != "24.04" ] && [ "$OS_VERSION" != "22.04" ]; then
    log_warn "Рекомендуется Ubuntu 22.04 LTS или 24.04 LTS (обнаружено: $OS_VERSION)"
  fi
}

check_critical_resources() {
  if [ "$DISK_GB" -lt 5 ]; then
    log_error "Критически мало места на диске: ${DISK_GB}GB свободно (минимум 5GB даже для minimal)"
    exit 1
  fi
}

check_tools() {
  if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    log_warn "curl/wget не установлен; часть health checks может быть ограничена"
  fi

  if ! command -v docker &> /dev/null; then
    log_warn "Docker не установлен; это нормально для minimal/proxy до Docker steps"
  elif ! docker compose version &> /dev/null; then
    log_warn "Docker Compose не установлен или недоступен"
  fi

  if [ -f "$ENV_FILE" ]; then
    log_info "Файл .env найден: $ENV_FILE"
  else
    log_warn "Файл .env не найден; он нужен только для ai-stack compose этапов"
  fi
}

print_hardware_summary() {
  log_info "Краткая сводка железа:"
  uname -r || true
  command -v dmidecode &> /dev/null && dmidecode -t system -t baseboard || true
  command -v lspci &> /dev/null && lspci -nnk || true
  command -v lsusb &> /dev/null && lsusb || true
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    print_profile_summary
    exit 0
  fi

  require_root
  parse_profile "$@"

  log_info "=== Profile-aware preflight проверка ==="
  detect_os
  detect_resources
  check_os_support
  check_critical_resources
  check_tools
  print_profile_matrix

  if [ -n "$PROFILE" ]; then
    local selected_status
    selected_status="$(profile_status "$PROFILE")"
    if [ "$selected_status" = "NO" ]; then
      log_warn "Сервер не подходит для профиля '$PROFILE': $(profile_recommendation "$PROFILE" "$selected_status")"
    elif [ "$selected_status" = "WARN" ]; then
      log_warn "Профиль '$PROFILE' возможен с ограничениями: $(profile_recommendation "$PROFILE" "$selected_status")"
    else
      log_info "Сервер подходит для профиля '$PROFILE'"
    fi
  fi

  print_hardware_summary
  log_info "Preflight проверка завершена"
}

main "$@"
