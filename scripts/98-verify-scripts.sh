#!/bin/bash

# Безопасная локальная проверка first-party shell scripts.

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

shopt -s nullglob
SCRIPT_FILES=(
  "$SCRIPT_DIR"/*.sh
  "$SCRIPT_DIR"/lib/*.sh
  "$SCRIPT_DIR"/security/*.sh
)

if [ "${#SCRIPT_FILES[@]}" -eq 0 ]; then
  log_warn "Shell scripts не найдены"
  exit 0
fi

log_info "Проверка синтаксиса Bash для ${#SCRIPT_FILES[@]} first-party scripts"
bash -n "${SCRIPT_FILES[@]}"

if command -v shellcheck &> /dev/null; then
  log_info "Запуск ShellCheck для ${#SCRIPT_FILES[@]} first-party scripts"
  shellcheck -x --severity=warning "${SCRIPT_FILES[@]}"
else
  log_warn "ShellCheck не установлен; пропускаю статический анализ"
  log_warn "Установите: sudo apt install -y shellcheck"
fi

log_info "Проверки shell scripts завершены"
