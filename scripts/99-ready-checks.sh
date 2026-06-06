#!/bin/bash

# Profile-aware readiness checks after installation.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$PROJECT_ROOT/docker-compose"
ENV_FILE="$COMPOSE_DIR/.env"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

trap 'log_error "Ошибка на строке $LINENO: $BASH_COMMAND"' ERR

print_usage() {
  cat <<'USAGE'
Использование:
  sudo bash scripts/99-ready-checks.sh --profile minimal|proxy|docker-host|web|ai-stack

Без --profile используется ai-stack compatibility mode.
USAGE
}

get_env_value() {
  local key="$1"
  grep "^${key}=" "$ENV_FILE" | head -n1 | cut -d'=' -f2- | sed "s/^[\"']//;s/[\"']$//"
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

http_check() {
  local url="$1"

  if command -v curl &> /dev/null; then
    curl -f "$url" > /dev/null
  elif command -v wget &> /dev/null; then
    wget -q --spider "$url"
  else
    log_error "curl или wget не установлен (нужен для healthcheck)"
    return 1
  fi
}

check_service_active() {
  local service="$1"
  local required="${2:-required}"

  if systemctl is-active --quiet "$service"; then
    log_info "Service active: $service"
    return 0
  fi

  if [ "$required" = "optional" ]; then
    log_warn "Optional service не активен: $service"
    return 0
  fi

  log_error "Service не активен: $service"
  return 1
}

check_minimal() {
  log_info "Проверка minimal security baseline"

  if command -v sshd &> /dev/null; then
    sshd -t
    log_info "SSH config valid"
  else
    log_warn "sshd не найден"
  fi

  if command -v ufw &> /dev/null; then
    ufw status verbose | sed -n '1,8p'
  else
    log_error "ufw не установлен"
    return 1
  fi

  check_service_active fail2ban optional
  check_service_active unattended-upgrades optional

  detect_resources
  if [ "$RAM_MB" -lt 1024 ] && [ "$SWAP_MB" -eq 0 ]; then
    log_warn "RAM меньше 1GB и swap отсутствует; рассмотрите scripts/security/swap.sh"
  else
    log_info "RAM/swap baseline acceptable"
  fi
}

check_proxy() {
  check_minimal
  log_warn "Proxy service ports проверяются вручную: sudo ufw status verbose"
}

check_docker_host() {
  check_minimal

  if ! command -v docker &> /dev/null; then
    log_error "Docker не установлен"
    return 1
  fi

  docker --version
  docker compose version
  check_service_active docker required
}

check_web() {
  check_minimal

  if command -v nginx &> /dev/null; then
    nginx -t
    check_service_active nginx optional
  else
    log_warn "nginx не установлен; это нормально, если используется другой reverse proxy"
  fi

  log_info "Проверьте, что UFW разрешает 80/443 только если web endpoint нужен"
}

check_ai_stack() {
  log_info "Проверка ai-stack readiness"

  if [ ! -f "$ENV_FILE" ]; then
    log_error "Файл .env не найден: $ENV_FILE"
    return 1
  fi

  local required_vars=(
    "REDIS_PASSWORD"
    "SUPABASE_DB_PASSWORD"
    "N8N_BASIC_AUTH_PASSWORD"
    "N8N_ENCRYPTION_KEY"
    "N8N_USER_MANAGEMENT_JWT_SECRET"
    "GRAFANA_PASSWORD"
  )
  local var val

  for var in "${required_vars[@]}"; do
    val="$(get_env_value "$var" || true)"
    if is_placeholder "$val"; then
      log_error "Переменная $var не задана или содержит placeholder"
      return 1
    fi
  done
  log_info "Обязательные secrets присутствуют без вывода значений"

  cd "$COMPOSE_DIR"
  docker compose config > /dev/null
  log_info "docker compose config valid"

  local required_services=("supabase_db" "redis" "pgbouncer" "n8n" "n8n-worker")
  local svc
  for svc in "${required_services[@]}"; do
    if ! docker compose ps --services --filter "status=running" | grep -q "^${svc}$"; then
      log_error "Сервис не запущен: $svc"
      return 1
    fi
    log_info "Compose service running: $svc"
  done

  http_check http://localhost:5678/healthz

  local pgpassword redis_password
  pgpassword="$(get_env_value SUPABASE_DB_PASSWORD)"
  docker compose exec -T -e PGPASSWORD="$pgpassword" supabase_db psql -U postgres -d postgres -c 'SELECT 1;' > /dev/null
  docker compose exec -T -e PGPASSWORD="$pgpassword" supabase_db psql -h pgbouncer -p 6432 -U postgres -d postgres -c 'SELECT 1;' > /dev/null

  redis_password="$(get_env_value REDIS_PASSWORD)"
  docker compose exec -T -e REDISCLI_AUTH="$redis_password" redis redis-cli ping | grep -q PONG

  if docker compose ps --services --filter "status=running" | grep -q "^prometheus$"; then
    http_check http://localhost:9090/-/healthy || log_warn "Prometheus не отвечает"
  fi

  if docker compose ps --services --filter "status=running" | grep -q "^grafana$"; then
    http_check http://localhost:3000/api/health || log_warn "Grafana не отвечает"
  fi
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    exit 0
  fi

  require_root
  parse_profile "$@"

  if [ -z "$PROFILE" ]; then
    PROFILE="ai-stack"
    log_warn "Профиль не указан; использую ai-stack compatibility mode"
  fi

  log_info "=== Ready checks: $PROFILE ==="

  case "$PROFILE" in
    minimal) check_minimal ;;
    proxy) check_proxy ;;
    docker-host) check_docker_host ;;
    web) check_web ;;
    ai-stack) check_ai_stack ;;
  esac

  log_info "Ready checks пройдены для профиля: $PROFILE"
}

main "$@"
