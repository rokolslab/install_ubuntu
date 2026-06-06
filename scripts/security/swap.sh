#!/bin/bash

# Optional idempotent swapfile helper for small VPS profiles.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SWAP_FILE="/swapfile"
SWAP_SIZE="1G"
FORCE_RECREATE="0"

# shellcheck source=../lib/common.sh
. "$PROJECT_ROOT/scripts/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/security/swap.sh [--size 1G] [--force-recreate]

Если swap уже есть, script только показывает статус и ничего не пересоздаёт.
USAGE
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --size)
        if [ "$#" -lt 2 ]; then
          log_error "Опция --size требует значение, например 1G"
          exit 1
        fi
        SWAP_SIZE="$2"
        shift 2
        ;;
      --size=*)
        SWAP_SIZE="${1#--size=}"
        shift
        ;;
      --force-recreate)
        FORCE_RECREATE="1"
        shift
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        log_warn "Неизвестный аргумент swap module: $1"
        shift
        ;;
    esac
  done
}

swap_is_active() {
  swapon --show=NAME --noheadings | grep -Fxq "$SWAP_FILE"
}

any_swap_exists() {
  [ "$(free -m | awk '/Swap:/{print $2}')" -gt 0 ]
}

ensure_disk_space() {
  local available_gb

  available_gb="$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')"
  if [ "$available_gb" -lt 2 ]; then
    log_error "Недостаточно диска для swapfile: ${available_gb}GB свободно"
    exit 1
  fi
}

create_swap() {
  log_info "Создаю swapfile $SWAP_FILE размером $SWAP_SIZE"
  fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=1024 status=progress
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE"
  swapon "$SWAP_FILE"

  if ! grep -Eq "^[^#[:space:]]+[[:space:]]+none[[:space:]]+swap" /etc/fstab; then
    printf '%s none swap sw 0 0\n' "$SWAP_FILE" >> /etc/fstab
    log_info "Swap добавлен в /etc/fstab"
  else
    log_info "Swap entry уже есть в /etc/fstab"
  fi
}

main() {
  parse_args "$@"
  require_root

  log_info "Текущий swap status:"
  swapon --show || true

  if any_swap_exists && [ "$FORCE_RECREATE" != "1" ]; then
    log_info "Swap уже существует; ничего не меняю"
    exit 0
  fi

  if [ -e "$SWAP_FILE" ] && ! swap_is_active && [ "$FORCE_RECREATE" != "1" ]; then
    log_warn "$SWAP_FILE существует, но не активен; не пересоздаю без --force-recreate"
    exit 0
  fi

  if [ "$FORCE_RECREATE" = "1" ] && [ -e "$SWAP_FILE" ]; then
    log_warn "Пересоздаю $SWAP_FILE по явному --force-recreate"
    swapoff "$SWAP_FILE" 2> /dev/null || true
    rm -f "$SWAP_FILE"
  fi

  ensure_disk_space
  create_swap
  swapon --show
  log_info "Swap setup завершён"
}

main "$@"
