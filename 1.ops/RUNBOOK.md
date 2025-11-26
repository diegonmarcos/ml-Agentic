# Multi-Agent RAG Orchestrator - Operations Runbook

**Version**: 4.2.0
**Last Updated**: 2025-11-18

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Deployment](#deployment)
3. [Monitoring](#monitoring)
4. [Common Operations](#common-operations)
5. [Troubleshooting](#troubleshooting)
6. [Incident Response](#incident-response)
7. [Maintenance](#maintenance)
8. [Disaster Recovery](#disaster-recovery)

---

## System Overview

### Architecture Components

The system consists of 11 services:

**Core Services:**
- **FastAPI** (port 8000) - Main API server
- **Redis** (port 6379) - Caching, rate limiting, metrics
- **PostgreSQL** (port 5432) - Persistent storage with TimescaleDB
- **Qdrant** (port 6333) - Vector database for RAG

**LLM Providers:**
- **Ollama** (port 11434) - Local LLM (Tier 0)
- **Jan** (port 1337) - Privacy-mode LLM (Tier 0)
- Cloud providers (Fireworks, Together, Anthropic, OpenAI)

**MCP Servers:**
- **MCP Filesystem** (port 3001) - File operations
- **MCP Git** (port 3002) - Git operations
- **MCP Memory** (port 3003) - Memory operations

**Monitoring:**
- **Prometheus** (port 9090) - Metrics collection
- **Grafana** (port 3000) - Dashboards

### System Requirements

- **CPU**: 8+ cores recommended
- **Memory**: 16GB+ RAM
- **Disk**: 100GB+ SSD
- **Network**: 1Gbps recommended

---

## Deployment

### Initial Deployment

```bash
# Clone repository
git clone https://github.com/your-org/ml-Agentic.git
cd ml-Agentic

# Deploy with rolling strategy (default)
./scripts/deploy.sh production rolling

# Monitor deployment
./scripts/health-check.sh
```

### Deployment Strategies

**Rolling Deployment** (Zero downtime):
```bash
./scripts/deploy.sh production rolling
```
- Updates services one by one
- Each service is health-checked before proceeding
- Safe for minor updates

**Blue-Green Deployment** (Full environment switch):
```bash
./scripts/deploy.sh production blue-green
```
- Deploys complete new environment
- Switches traffic after validation
- Easy rollback
- Use for major updates

**Canary Deployment** (Gradual rollout):
```bash
./scripts/deploy.sh production canary
```
- Deploys to 10% of traffic first
- Monitor metrics for 5 minutes
- Manual approval before full rollout
- Use for risky changes

### Rollback

```bash
# Rollback to specific backup
./scripts/rollback.sh 20250118_143000

# Rollback to latest backup
./scripts/rollback.sh
```

---

## Monitoring

### Health Checks

**Quick Health Check:**
```bash
curl http://localhost:8000/health
```

**Component-Specific Checks:**
```bash
# Redis
docker exec redis redis-cli ping

# PostgreSQL
docker exec postgres pg_isready -U postgres

# Qdrant
curl http://localhost:6333/health

# Ollama
curl http://localhost:11434/api/tags

# FastAPI
curl http://localhost:8000/health/ready
```

**Kubernetes Probes:**
```bash
# Liveness (is the app alive?)
curl http://localhost:8000/health/live

# Readiness (is the app ready for traffic?)
curl http://localhost:8000/health/ready

# Startup (has the app started successfully?)
curl http://localhost:8000/health/startup
```

### Metrics & Dashboards

**Grafana Dashboard**: http://localhost:3000
- LLMOps Dashboard: Provider metrics, costs, latency
- System Dashboard: CPU, memory, disk usage

**Prometheus**: http://localhost:9090
- Query metrics directly
- View targets and alerts

**Key Metrics to Monitor:**
- Request rate (requests/second)
- Error rate (%)
- Latency (P50, P95, P99)
- LLM cost ($/hour, $/day)
- Redis memory usage
- PostgreSQL connections
- Disk usage

### Logs

**View Service Logs:**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f fastapi

# Last 100 lines
docker-compose logs --tail=100 fastapi

# Filter by keyword
docker-compose logs fastapi | grep ERROR
```

**Log Locations:**
- FastAPI: stdout (Docker logs)
- PostgreSQL: `/var/lib/postgresql/data/log/`
- Redis: stdout
- Qdrant: `/qdrant/storage/logs/`

---

## Common Operations

### Scaling Services

**Scale FastAPI Workers:**
```yaml
# docker-compose.yml
services:
  fastapi:
    deploy:
      replicas: 4  # Increase replicas
```

```bash
docker-compose up -d --scale fastapi=4
```

**Scale PostgreSQL (Read Replicas):**
- Add read replica in `docker-compose.yml`
- Configure connection pooling
- Update application to use replica for reads

### Database Operations

**Backup Database:**
```bash
# Automatic backup (included in deploy.sh)
./scripts/deploy.sh production rolling

# Manual backup
docker exec postgres pg_dumpall -U postgres > backup_$(date +%Y%m%d_%H%M%S).sql
```

**Restore Database:**
```bash
docker exec -i postgres psql -U postgres < backup_20250118_143000.sql
```

**Check Database Size:**
```bash
docker exec postgres psql -U postgres -c "SELECT pg_size_pretty(pg_database_size('postgres'));"
```

**Vacuum Database:**
```bash
docker exec postgres psql -U postgres -c "VACUUM ANALYZE;"
```

### Redis Operations

**Check Memory Usage:**
```bash
docker exec redis redis-cli INFO memory
```

**Clear Cache (Use with caution!):**
```bash
docker exec redis redis-cli FLUSHDB
```

**Monitor Commands:**
```bash
docker exec redis redis-cli MONITOR
```

### Budget Management

**Check User Budget:**
```bash
curl http://localhost:8000/api/v1/budget/user/user_123?period=daily
```

**Set Budget Limit:**
```bash
curl -X POST http://localhost:8000/api/v1/budget/limit \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user_123", "period": "daily", "limit": 10.00}'
```

**Get Top Spenders:**
```bash
curl http://localhost:8000/api/v1/budget/top-spenders/daily?limit=10
```

---

## Troubleshooting

### Service Won't Start

**Check Docker:**
```bash
docker info
docker ps -a
docker-compose ps
```

**Check Logs:**
```bash
docker-compose logs service_name
```

**Common Issues:**
- Port already in use: `lsof -i :8000`
- Insufficient memory: `free -h`
- Disk full: `df -h`

### High Memory Usage

**Check Memory by Service:**
```bash
docker stats
```

**PostgreSQL Memory:**
```bash
docker exec postgres psql -U postgres -c "SHOW shared_buffers;"
```

**Redis Memory:**
```bash
docker exec redis redis-cli INFO memory
```

**Solutions:**
- Increase server memory
- Tune PostgreSQL `shared_buffers`
- Set Redis `maxmemory` policy
- Scale horizontally

### Slow API Responses

**Check Latency:**
```bash
curl -w "@curl-format.txt" http://localhost:8000/health
```

**Check Database Queries:**
```bash
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

**Check Redis Latency:**
```bash
docker exec redis redis-cli --latency
```

**Solutions:**
- Add database indexes
- Enable query caching
- Scale workers
- Optimize LLM provider tier usage

### LLM Provider Failures

**Check Provider Status:**
```bash
# Ollama
curl http://localhost:11434/api/tags

# Jan
curl http://localhost:1337/health
```

**Fallback Configuration:**
- System automatically falls back to next tier
- Check `provider_router.py` for failover logic
- Monitor provider analytics dashboard

**Solutions:**
- Restart provider service
- Check API keys for cloud providers
- Increase timeout values
- Use privacy mode (Tier 0) as fallback

### Rate Limit Issues

**Check Rate Limit Status:**
```bash
curl -i http://localhost:8000/api/endpoint
# Look for X-RateLimit-* headers
```

**Increase Rate Limits:**
Edit `src/api/main.py`:
```python
app.add_middleware(
    RateLimitMiddleware,
    endpoint_limits={
        "/api/search": {"requests": 100, "window": 60}  # Increase from 10
    }
)
```

### Database Connection Pool Exhausted

**Check Connections:**
```bash
docker exec postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

**Increase Pool Size:**
Edit `asyncpg` connection pool:
```python
pool = await asyncpg.create_pool(
    max_size=50,  # Increase from 20
    min_size=10
)
```

---

## Incident Response

### Severity Levels

**P0 - Critical (Response: Immediate)**
- Complete service outage
- Data loss
- Security breach

**P1 - High (Response: <15 min)**
- Partial service outage
- Significant performance degradation
- Failed deployment

**P2 - Medium (Response: <1 hour)**
- Non-critical component failure
- Elevated error rates
- Minor performance issues

**P3 - Low (Response: <4 hours)**
- Cosmetic issues
- Documentation errors
- Minor bugs

### Incident Response Checklist

1. **Detect & Alert**
   - Check monitoring dashboards
   - Review error logs
   - Confirm issue scope

2. **Communicate**
   - Notify stakeholders
   - Post status update
   - Set up incident channel

3. **Mitigate**
   - Rollback if recent deployment
   - Scale up resources
   - Enable maintenance mode if needed

4. **Resolve**
   - Identify root cause
   - Apply fix
   - Verify resolution

5. **Post-Mortem**
   - Document timeline
   - Identify improvements
   - Update runbook

### Emergency Procedures

**Complete Service Outage:**
```bash
# 1. Check all services
./scripts/health-check.sh

# 2. Restart all services
docker-compose restart

# 3. If still failing, rollback
./scripts/rollback.sh

# 4. Check logs
docker-compose logs -f
```

**High Load / DDoS:**
```bash
# 1. Enable stricter rate limiting
# Edit src/middleware/rate_limit.py

# 2. Block suspicious IPs
# Add to nginx/firewall

# 3. Scale up
docker-compose up -d --scale fastapi=10
```

**Data Corruption:**
```bash
# 1. Stop writes
# Enable maintenance mode

# 2. Restore from backup
./scripts/rollback.sh TIMESTAMP

# 3. Verify data integrity
# Run data validation scripts

# 4. Resume operations
```

---

## Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor dashboards for anomalies
- Check error logs
- Verify backup completion

**Weekly:**
- Review cost trends
- Analyze performance metrics
- Update dependency versions

**Monthly:**
- Database vacuum and reindex
- Clean old logs
- Security updates
- Capacity planning review

### Maintenance Windows

**Schedule Maintenance:**
1. Notify users 24 hours in advance
2. Create backup before changes
3. Use canary deployment for updates
4. Monitor closely during and after

**Maintenance Mode:**
```bash
# Enable maintenance mode (return 503)
# Add to nginx config or FastAPI middleware
```

### Database Maintenance

**Vacuum and Analyze:**
```bash
docker exec postgres psql -U postgres -c "VACUUM FULL ANALYZE;"
```

**Reindex:**
```bash
docker exec postgres psql -U postgres -c "REINDEX DATABASE postgres;"
```

**Check Table Bloat:**
```bash
docker exec postgres psql -U postgres -c "
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"
```

---

## Disaster Recovery

### Backup Strategy

**Automated Backups:**
- Created before each deployment
- Stored in `/backups/` directory
- Retention: Last 10 backups

**Backup Contents:**
- Redis RDB dump
- PostgreSQL full dump
- Qdrant vector data
- Configuration files

**Manual Backup:**
```bash
# Create backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/$TIMESTAMP

# Redis
docker exec redis redis-cli SAVE
docker cp redis:/data/dump.rdb backups/$TIMESTAMP/

# PostgreSQL
docker exec postgres pg_dumpall -U postgres > backups/$TIMESTAMP/postgres.sql

# Qdrant
docker exec qdrant tar -czf /tmp/qdrant.tar.gz /qdrant/storage
docker cp qdrant:/tmp/qdrant.tar.gz backups/$TIMESTAMP/
```

### Disaster Recovery Procedures

**Complete System Failure:**
1. Provision new infrastructure
2. Deploy latest version
3. Restore from most recent backup
4. Verify data integrity
5. Resume operations
6. Investigate root cause

**Data Center Failure:**
1. Failover to secondary region (if configured)
2. Update DNS records
3. Restore from off-site backups
4. Monitor for data consistency issues

**RTO/RPO Targets:**
- **RTO** (Recovery Time Objective): < 1 hour
- **RPO** (Recovery Point Objective): < 15 minutes

### Testing Disaster Recovery

**Quarterly DR Test:**
```bash
# 1. Create test environment
# 2. Deploy from backup
./scripts/rollback.sh LATEST

# 3. Run smoke tests
pytest tests/integration/

# 4. Document results
# 5. Update procedures
```

---

## Contacts

**On-Call Rotation:**
- Primary: [Contact Info]
- Secondary: [Contact Info]
- Manager: [Contact Info]

**Escalation Path:**
1. On-Call Engineer
2. Team Lead
3. Engineering Manager
4. Director of Engineering

**External Vendors:**
- Cloud Provider: [Support Contact]
- Database Support: [Support Contact]
- Security Team: [Contact]

---

## Appendix

### Useful Commands

```bash
# Check all service ports
netstat -tulpn | grep LISTEN

# Monitor system resources
htop

# Check disk I/O
iotop

# Network traffic
nethogs

# Database connections
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Redis slow log
docker exec redis redis-cli SLOWLOG GET 10

# Find large files
du -sh /* | sort -rh | head -10
```

### Configuration Files

- Docker Compose: `/docker-compose.yml`
- FastAPI: `/src/api/main.py`
- Prometheus: `/prometheus.yml`
- Grafana: `/grafana/dashboards/`
- Nginx: `/nginx/nginx.conf` (if using)

### API Endpoints

- Documentation: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Metrics: http://localhost:9090
- Dashboards: http://localhost:3000

---

**End of Runbook**

For questions or updates, contact: DevOps Team
