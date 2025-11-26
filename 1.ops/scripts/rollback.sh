#!/bin/bash
# Multi-Agent RAG Orchestrator - Rollback Script
# TASK-043: Rollback to previous deployment
#
# Usage:
#   ./scripts/rollback.sh [backup_timestamp]
#
# Arguments:
#   backup_timestamp: Timestamp of backup to restore (e.g., 20250118_143000)
#
# Examples:
#   ./scripts/rollback.sh 20250118_143000
#   ./scripts/rollback.sh  # Uses latest backup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_TIMESTAMP="${1:-}"
BACKUPS_DIR="$PROJECT_ROOT/backups"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Find latest backup if not specified
find_backup() {
    if [ -z "$BACKUP_TIMESTAMP" ]; then
        log_info "Finding latest backup..."
        BACKUP_TIMESTAMP=$(ls -t "$BACKUPS_DIR" | head -n1)

        if [ -z "$BACKUP_TIMESTAMP" ]; then
            log_error "No backups found in $BACKUPS_DIR"
            exit 1
        fi

        log_info "Using latest backup: $BACKUP_TIMESTAMP"
    fi

    BACKUP_DIR="$BACKUPS_DIR/$BACKUP_TIMESTAMP"

    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "Backup not found: $BACKUP_DIR"
        exit 1
    fi
}

# Confirm rollback
confirm_rollback() {
    log_warn "=== ROLLBACK CONFIRMATION ==="
    log_warn "You are about to rollback to: $BACKUP_TIMESTAMP"
    log_warn "This will:"
    log_warn "  - Stop current services"
    log_warn "  - Restore Redis data"
    log_warn "  - Restore PostgreSQL data"
    log_warn "  - Restore Qdrant data"
    log_warn ""
    log_warn "Type 'YES' to confirm rollback: "
    read -r confirmation

    if [ "$confirmation" != "YES" ]; then
        log_info "Rollback cancelled"
        exit 0
    fi
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" down
    log_info "Services stopped ✓"
}

# Restore Redis
restore_redis() {
    log_info "Restoring Redis..."

    if [ -f "$BACKUP_DIR/redis_dump.rdb" ]; then
        # Start Redis
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d redis
        sleep 5

        # Restore dump
        docker cp "$BACKUP_DIR/redis_dump.rdb" redis:/data/dump.rdb
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" restart redis
        sleep 3

        # Verify
        if docker exec redis redis-cli ping | grep -q PONG; then
            log_info "Redis restored successfully ✓"
        else
            log_error "Redis restoration failed"
            return 1
        fi
    else
        log_warn "No Redis backup found, skipping..."
    fi
}

# Restore PostgreSQL
restore_postgres() {
    log_info "Restoring PostgreSQL..."

    if [ -f "$BACKUP_DIR/postgres_backup.sql" ]; then
        # Start PostgreSQL
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d postgres
        sleep 10

        # Restore dump
        docker exec -i postgres psql -U postgres < "$BACKUP_DIR/postgres_backup.sql"

        # Verify
        if docker exec postgres pg_isready -U postgres | grep -q "accepting connections"; then
            log_info "PostgreSQL restored successfully ✓"
        else
            log_error "PostgreSQL restoration failed"
            return 1
        fi
    else
        log_warn "No PostgreSQL backup found, skipping..."
    fi
}

# Restore Qdrant
restore_qdrant() {
    log_info "Restoring Qdrant..."

    if [ -f "$BACKUP_DIR/qdrant_backup.tar.gz" ]; then
        # Start Qdrant
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d qdrant
        sleep 5

        # Restore data
        docker cp "$BACKUP_DIR/qdrant_backup.tar.gz" qdrant:/tmp/qdrant_backup.tar.gz
        docker exec qdrant tar -xzf /tmp/qdrant_backup.tar.gz -C /
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" restart qdrant
        sleep 5

        # Verify
        if curl -f -s "http://localhost:6333/health" > /dev/null; then
            log_info "Qdrant restored successfully ✓"
        else
            log_error "Qdrant restoration failed"
            return 1
        fi
    else
        log_warn "No Qdrant backup found, skipping..."
    fi
}

# Start all services
start_services() {
    log_info "Starting all services..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d
    sleep 10
    log_info "Services started ✓"
}

# Verify rollback
verify_rollback() {
    log_info "Verifying rollback..."

    local failed=0

    # Check Redis
    if ! docker exec redis redis-cli ping | grep -q PONG; then
        log_error "Redis verification failed"
        ((failed++))
    fi

    # Check PostgreSQL
    if ! docker exec postgres pg_isready -U postgres | grep -q "accepting connections"; then
        log_error "PostgreSQL verification failed"
        ((failed++))
    fi

    # Check Qdrant
    if ! curl -f -s "http://localhost:6333/health" > /dev/null; then
        log_error "Qdrant verification failed"
        ((failed++))
    fi

    # Check FastAPI
    if ! curl -f -s "http://localhost:8000/health" > /dev/null; then
        log_error "FastAPI verification failed"
        ((failed++))
    fi

    if [ $failed -eq 0 ]; then
        log_info "Rollback verification passed ✓"
        return 0
    else
        log_error "Rollback verification failed ($failed checks failed)"
        return 1
    fi
}

# Main rollback flow
main() {
    log_info "=== Multi-Agent RAG Orchestrator Rollback ==="
    log_info ""

    # Find backup
    find_backup

    # Confirm rollback
    confirm_rollback

    # Stop services
    stop_services

    # Restore data
    restore_redis || log_warn "Redis restoration had issues"
    restore_postgres || log_warn "PostgreSQL restoration had issues"
    restore_qdrant || log_warn "Qdrant restoration had issues"

    # Start services
    start_services

    # Verify
    if verify_rollback; then
        log_info ""
        log_info "=== Rollback Completed Successfully ==="
        log_info "Restored from: $BACKUP_TIMESTAMP"
        log_info ""
        log_info "Next steps:"
        log_info "  1. Monitor application metrics in Grafana: http://localhost:3000"
        log_info "  2. Check application logs: docker-compose logs -f"
        log_info "  3. Investigate root cause of issues"
    else
        log_error ""
        log_error "=== Rollback Completed with Errors ==="
        log_error "Some services may not be fully functional"
        log_error "Check logs: docker-compose logs -f"
        exit 1
    fi
}

# Run main
main
