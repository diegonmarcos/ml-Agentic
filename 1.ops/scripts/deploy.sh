#!/bin/bash
# Multi-Agent RAG Orchestrator - Deployment Script
# TASK-043: Production deployment automation
#
# Usage:
#   ./scripts/deploy.sh [environment] [strategy]
#
# Arguments:
#   environment: dev, staging, production (default: dev)
#   strategy: rolling, blue-green, canary (default: rolling)
#
# Examples:
#   ./scripts/deploy.sh dev rolling
#   ./scripts/deploy.sh production blue-green

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${1:-dev}"
STRATEGY="${2:-rolling}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$PROJECT_ROOT/backups/$TIMESTAMP"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_deps=()

    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_error "Please install missing dependencies and try again."
        exit 1
    fi

    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi

    log_info "Prerequisites check passed ✓"
}

# Create backup
create_backup() {
    log_info "Creating backup..."

    mkdir -p "$BACKUP_DIR"

    # Backup Redis data
    if docker ps | grep -q redis; then
        log_info "Backing up Redis..."
        docker exec redis redis-cli SAVE
        docker cp redis:/data/dump.rdb "$BACKUP_DIR/redis_dump.rdb" 2>/dev/null || true
    fi

    # Backup PostgreSQL data
    if docker ps | grep -q postgres; then
        log_info "Backing up PostgreSQL..."
        docker exec postgres pg_dumpall -U postgres > "$BACKUP_DIR/postgres_backup.sql" 2>/dev/null || true
    fi

    # Backup Qdrant data
    if docker ps | grep -q qdrant; then
        log_info "Backing up Qdrant..."
        docker exec qdrant tar -czf /tmp/qdrant_backup.tar.gz /qdrant/storage 2>/dev/null || true
        docker cp qdrant:/tmp/qdrant_backup.tar.gz "$BACKUP_DIR/qdrant_backup.tar.gz" 2>/dev/null || true
    fi

    log_info "Backup created at: $BACKUP_DIR ✓"
}

# Health check
health_check() {
    local service=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    log_info "Performing health check for $service..."

    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            log_info "$service is healthy ✓"
            return 0
        fi

        log_warn "$service not ready yet (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    log_error "$service health check failed after $max_attempts attempts"
    return 1
}

# Deploy with rolling strategy
deploy_rolling() {
    log_info "Starting rolling deployment..."

    # Pull latest images
    log_info "Pulling latest images..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" pull

    # Restart services one by one
    services=("redis" "postgres" "qdrant" "ollama" "jan" "fastapi" "grafana" "prometheus")

    for service in "${services[@]}"; do
        log_info "Restarting $service..."
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d --no-deps --build "$service"

        # Wait for service to be healthy
        sleep 5

        # Service-specific health checks
        case $service in
            "redis")
                docker exec redis redis-cli ping | grep -q PONG || { log_error "$service failed"; exit 1; }
                ;;
            "postgres")
                docker exec postgres pg_isready -U postgres || { log_error "$service failed"; exit 1; }
                ;;
            "fastapi")
                health_check "fastapi" "http://localhost:8000/health" || { log_error "$service failed"; exit 1; }
                ;;
            "grafana")
                health_check "grafana" "http://localhost:3000/api/health" || { log_warn "$service may have issues"; }
                ;;
        esac

        log_info "$service restarted successfully ✓"
    done

    log_info "Rolling deployment completed ✓"
}

# Deploy with blue-green strategy
deploy_blue_green() {
    log_info "Starting blue-green deployment..."

    # Check which environment is currently active
    if docker ps | grep -q "fastapi-blue"; then
        CURRENT="blue"
        TARGET="green"
    else
        CURRENT="green"
        TARGET="blue"
    fi

    log_info "Current environment: $CURRENT"
    log_info "Target environment: $TARGET"

    # Start target environment
    log_info "Starting $TARGET environment..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.$TARGET.yml" up -d

    # Wait for target to be healthy
    sleep 10
    health_check "fastapi-$TARGET" "http://localhost:8001/health" || {
        log_error "$TARGET environment failed health check"
        log_info "Rolling back..."
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.$TARGET.yml" down
        exit 1
    }

    # Switch traffic to target (update nginx/load balancer config here)
    log_info "Switching traffic to $TARGET environment..."

    # Stop old environment
    log_info "Stopping $CURRENT environment..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.$CURRENT.yml" down

    log_info "Blue-green deployment completed ✓"
    log_info "Active environment: $TARGET"
}

# Deploy with canary strategy
deploy_canary() {
    log_info "Starting canary deployment..."

    # Deploy canary (10% traffic)
    log_info "Deploying canary instance..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.canary.yml" up -d

    # Wait for canary to be healthy
    sleep 10
    health_check "fastapi-canary" "http://localhost:8002/health" || {
        log_error "Canary deployment failed health check"
        log_info "Rolling back..."
        docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.canary.yml" down
        exit 1
    }

    log_info "Canary deployed successfully ✓"
    log_info "Monitor canary metrics for 5 minutes before proceeding..."

    # In production, you would:
    # 1. Monitor canary metrics (error rate, latency)
    # 2. Compare with production baseline
    # 3. Gradually increase traffic (10% -> 25% -> 50% -> 100%)
    # 4. Or rollback if issues detected

    log_warn "Manual approval required to continue canary rollout"
    log_warn "Press Enter to proceed with full rollout, or Ctrl+C to abort"
    read -r

    # Full rollout
    log_info "Proceeding with full rollout..."
    deploy_rolling

    # Remove canary
    log_info "Removing canary instance..."
    docker-compose -f "$PROJECT_ROOT/docker-compose.yml" -f "$PROJECT_ROOT/docker-compose.canary.yml" down

    log_info "Canary deployment completed ✓"
}

# Run smoke tests
run_smoke_tests() {
    log_info "Running smoke tests..."

    # Test FastAPI health endpoint
    if ! curl -f -s "http://localhost:8000/health" > /dev/null; then
        log_error "FastAPI health check failed"
        return 1
    fi

    # Test Redis connection
    if ! docker exec redis redis-cli ping | grep -q PONG; then
        log_error "Redis connection failed"
        return 1
    fi

    # Test PostgreSQL connection
    if ! docker exec postgres pg_isready -U postgres | grep -q "accepting connections"; then
        log_error "PostgreSQL connection failed"
        return 1
    fi

    # Test Qdrant connection
    if ! curl -f -s "http://localhost:6333/health" > /dev/null; then
        log_error "Qdrant connection failed"
        return 1
    fi

    log_info "Smoke tests passed ✓"
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up old backups..."

    # Keep only last 10 backups
    cd "$PROJECT_ROOT/backups" || return
    ls -t | tail -n +11 | xargs -r rm -rf

    log_info "Cleanup completed ✓"
}

# Main deployment flow
main() {
    log_info "=== Multi-Agent RAG Orchestrator Deployment ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Strategy: $STRATEGY"
    log_info ""

    # Check prerequisites
    check_prerequisites

    # Create backup
    create_backup

    # Deploy based on strategy
    case $STRATEGY in
        rolling)
            deploy_rolling
            ;;
        blue-green)
            deploy_blue_green
            ;;
        canary)
            deploy_canary
            ;;
        *)
            log_error "Unknown deployment strategy: $STRATEGY"
            log_error "Valid strategies: rolling, blue-green, canary"
            exit 1
            ;;
    esac

    # Run smoke tests
    run_smoke_tests || {
        log_error "Smoke tests failed!"
        log_warn "Consider rolling back using: ./scripts/rollback.sh $TIMESTAMP"
        exit 1
    }

    # Cleanup old backups
    cleanup_old_backups

    log_info ""
    log_info "=== Deployment Completed Successfully ==="
    log_info "Environment: $ENVIRONMENT"
    log_info "Strategy: $STRATEGY"
    log_info "Backup: $BACKUP_DIR"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Monitor application metrics in Grafana: http://localhost:3000"
    log_info "  2. Check application logs: docker-compose logs -f fastapi"
    log_info "  3. If issues occur, rollback with: ./scripts/rollback.sh $TIMESTAMP"
}

# Run main
main
