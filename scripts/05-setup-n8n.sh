#!/bin/bash

# Скрипт установки n8n (использует основной docker-compose.yml)
# Требует Docker, Docker Compose, PostgreSQL и Redis

set -euo pipefail

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

# Проверка Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker не установлен. Установите Docker сначала."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_error "Docker Compose не установлен. Установите Docker Compose сначала."
    exit 1
fi

log_info "Начинаем установку n8n..."

# Определяем путь к директории проекта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$PROJECT_ROOT/docker-compose"

# Проверяем наличие docker-compose.yml
if [ ! -f "$COMPOSE_DIR/docker-compose.yml" ]; then
    log_error "Файл docker-compose.yml не найден в $COMPOSE_DIR"
    exit 1
fi

cd "$COMPOSE_DIR"

# Проверяем наличие .env файла
if [ ! -f ".env" ]; then
    log_error "Файл .env не найден в $COMPOSE_DIR"
    log_error "Сначала создайте secrets через: sudo bash scripts/12-generate-secrets.sh --profile ai-stack"
    exit 1
fi

for required_secret in N8N_BASIC_AUTH_PASSWORD N8N_ENCRYPTION_KEY N8N_USER_MANAGEMENT_JWT_SECRET; do
    if ! grep -q "^${required_secret}=" .env 2>/dev/null; then
        log_error "Переменная $required_secret не найдена в .env"
        log_error "Обновите secrets через: sudo bash scripts/12-generate-secrets.sh --profile ai-stack"
        exit 1
    fi
done

# Проверяем, что Redis и Supabase запущены
if ! docker ps --format "{{.Names}}" | grep -q "^redis$"; then
    log_warn "Redis не запущен. Запускаем Redis..."
    docker compose up -d redis
    log_info "Ожидание готовности Redis..."
    sleep 5
fi

if ! docker ps --format "{{.Names}}" | grep -q "^supabase_db$"; then
    log_warn "Supabase PostgreSQL не запущен. Запускаем Supabase..."
    docker compose up -d supabase_db
    log_info "Ожидание готовности Supabase..."
    sleep 5
fi

if ! docker ps --format "{{.Names}}" | grep -q "^pgbouncer$"; then
    log_warn "PgBouncer не запущен. Запускаем PgBouncer..."
    docker compose up -d pgbouncer
    log_info "Ожидание готовности PgBouncer..."
    sleep 5
fi

# Запуск n8n и n8n-worker из основного docker-compose.yml
log_info "Запуск n8n и n8n-worker..."
docker compose up -d n8n n8n-worker

# Ждём запуска
log_info "Ожидание запуска n8n..."
sleep 10

# Проверка статуса
log_info "=== Статус контейнеров ==="
docker compose ps n8n n8n-worker

# Проверка логов
log_info "=== Логи n8n (последние 20 строк) ==="
docker compose logs --tail 20 n8n

log_info "=== Логи n8n-worker (последние 20 строк) ==="
docker compose logs --tail 20 n8n-worker

# Проверка здоровья
log_info "=== Проверка здоровья ==="
if docker compose ps n8n | grep -q "Up"; then
    log_info "n8n запущен успешно"
else
    log_error "Не удалось запустить n8n"
    exit 1
fi

if docker compose ps n8n-worker | grep -q "Up"; then
    log_info "n8n-worker запущен успешно"
else
    log_warn "n8n-worker не запущен (проверьте логи)"
fi

# Выводим информацию о подключении
log_info "=== Информация о подключении ==="
echo ""
log_info "n8n доступен по адресу: http://localhost:5678"
log_info "Логин: admin"
log_info "Пароль: см. в файле .env (N8N_BASIC_AUTH_PASSWORD)"
log_warn "Не выводите secrets в терминал; храните копию в password manager"
echo ""

log_info "Установка n8n завершена!"
