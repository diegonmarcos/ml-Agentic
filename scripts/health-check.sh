#!/bin/bash
# Multi-Agent RAG Orchestrator - Health Check Script
# TASK-043: Comprehensive system health check
#
# Usage:
#   ./scripts/health-check.sh
#
# Returns:
#   0: All services healthy
#   1: One or more services unhealthy

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check service health
check_service() {
    local service=$1
    local check_command=$2

    if eval "$check_command" &> /dev/null; then
        log_ok "$service is healthy"
        return 0
    else
        log_fail "$service is unhealthy"
        return 1
    fi
}

# Main health check
main() {
    echo "=== Multi-Agent RAG Orchestrator Health Check ==="
    echo ""

    local failed=0

    # Check Docker
    echo "Infrastructure:"
    check_service "Docker daemon" "docker info" || ((failed++))

    # Check services
    echo ""
    echo "Core Services:"
    check_service "Redis" "docker exec redis redis-cli ping | grep -q PONG" || ((failed++))
    check_service "PostgreSQL" "docker exec postgres pg_isready -U postgres | grep -q 'accepting connections'" || ((failed++))
    check_service "Qdrant" "curl -f -s http://localhost:6333/health" || ((failed++))

    echo ""
    echo "LLM Providers:"
    check_service "Ollama" "curl -f -s http://localhost:11434/api/tags" || log_warn "Ollama not available (optional)"
    check_service "Jan" "curl -f -s http://localhost:1337/health" || log_warn "Jan not available (optional)"

    echo ""
    echo "Application:"
    check_service "FastAPI" "curl -f -s http://localhost:8000/health" || ((failed++))

    echo ""
    echo "Monitoring:"
    check_service "Prometheus" "curl -f -s http://localhost:9090/-/healthy" || log_warn "Prometheus not available (optional)"
    check_service "Grafana" "curl -f -s http://localhost:3000/api/health" || log_warn "Grafana not available (optional)"

    echo ""
    echo "MCP Servers:"
    check_service "MCP Filesystem" "curl -f -s http://localhost:3001/health" || log_warn "MCP Filesystem not available (optional)"
    check_service "MCP Git" "curl -f -s http://localhost:3002/health" || log_warn "MCP Git not available (optional)"
    check_service "MCP Memory" "curl -f -s http://localhost:3003/health" || log_warn "MCP Memory not available (optional)"

    echo ""
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}=== All critical services healthy ===${NC}"
        return 0
    else
        echo -e "${RED}=== $failed critical service(s) unhealthy ===${NC}"
        return 1
    fi
}

main
