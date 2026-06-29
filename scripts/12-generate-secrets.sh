#!/bin/bash

# Скрипт генерации секретов для локального docker-compose/.env

set -Eeuo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для логирования
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

# Определяем путь к директории проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$PROJECT_ROOT/docker-compose"
ENV_EXAMPLE="$COMPOSE_DIR/env.example"
ENV_FILE="$COMPOSE_DIR/.env"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/12-generate-secrets.sh [--profile ai-stack]

Этот script генерирует secrets только для docker-compose ai-stack.
USAGE
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  print_usage
  exit 0
fi

parse_profile "$@"
case "${PROFILE:-}" in
  ai-stack)
    log_info "Secrets generation для профиля ai-stack"
    ;;
  "")
    log_warn "Профиль не указан; этот script нужен только для ai-stack"
    ;;
  *)
    log_error "Профиль '$PROFILE' не использует docker-compose secrets; не запускайте этот script для minimal/proxy/docker-host/web"
    exit 1
    ;;
esac

if [ "$EUID" -ne 0 ]; then
  log_info "Secrets будут созданы от имени текущего пользователя"
fi

generate_password() {
  if command -v openssl &> /dev/null; then
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-32
  else
    local password
    password="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)" || true
    printf '%s\n' "$password"
  fi
}

is_placeholder() {
  local value="$1"
  if [ -z "$value" ]; then
    return 0
  fi
  if echo "$value" | grep -qiE "your-secure|change-me|example|password-here"; then
    return 0
  fi
  return 1
}

get_env_value() {
  local key="$1"
  grep "^${key}=" "$ENV_FILE" 2>/dev/null | head -n1 | cut -d'=' -f2- | sed "s/^[\"']//;s/[\"']$//"
}

set_env_value() {
  local key="$1"
  local value="$2"
  local escaped_value
  escaped_value="$(printf '%s' "$value" | sed 's/[&/\\]/\\&/g')"
  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s/^${key}=.*/${key}=${escaped_value}/" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

secure_env_file() {
  if [ "$EUID" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    if id "$SUDO_USER" > /dev/null 2>&1; then
      local target_group
      target_group="$(id -gn "$SUDO_USER")"
      chown "$SUDO_USER:$target_group" "$ENV_FILE"
      log_info "Владелец .env: $SUDO_USER:$target_group"
    else
      log_warn "SUDO_USER=$SUDO_USER не найден; .env останется владельцем root"
    fi
  elif [ "$EUID" -eq 0 ]; then
    log_warn "Скрипт запущен напрямую от root; .env останется root-owned и будет доступен только root"
    log_warn "Запускайте последующие docker compose команды в контексте, который может прочитать .env"
  fi

  chmod 600 "$ENV_FILE"
}

if [ ! -f "$ENV_EXAMPLE" ]; then
  log_error "Файл env.example не найден: $ENV_EXAMPLE"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  log_info "Создаём .env из env.example"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

if [ ! -t 0 ]; then
  ROTATE="${ROTATE_SECRETS:-N}"
else
  read -rp "Пересоздать все секреты (rotation)? (y/N): " ROTATE
fi
ROTATE="${ROTATE:-N}"

SECRETS=(
  "REDIS_PASSWORD"
  "SUPABASE_DB_PASSWORD"
  "N8N_BASIC_AUTH_PASSWORD"
  "N8N_ENCRYPTION_KEY"
  "N8N_USER_MANAGEMENT_JWT_SECRET"
  "GRAFANA_PASSWORD"
)

for key in "${SECRETS[@]}"; do
  current="$(get_env_value "$key")"
  if [[ "$ROTATE" =~ ^[Yy]$ ]]; then
    new_val="$(generate_password)"
    set_env_value "$key" "$new_val"
    log_info "Обновлён $key"
    continue
  fi
  if is_placeholder "$current"; then
    new_val="$(generate_password)"
    set_env_value "$key" "$new_val"
    log_info "Сгенерирован $key"
  else
    log_info "Сохранён существующий $key"
  fi
done
secure_env_file

log_info "Генерация секретов завершена"
log_info "Файл: $ENV_FILE"
log_info "Права доступа .env: 600"
log_warn "Не записывайте сгенерированные secrets в tracked config files; храните копию в password manager"
