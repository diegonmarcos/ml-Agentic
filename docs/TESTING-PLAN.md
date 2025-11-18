# Comprehensive Testing Plan - v4.2 Multi-Agent RAG Orchestrator

**Version**: 1.0
**Last Updated**: 2025-11-18
**Test Coverage Goal**: 90%+

---

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Test Pyramid](#test-pyramid)
3. [Unit Tests](#unit-tests)
4. [Integration Tests](#integration-tests)
5. [End-to-End Tests](#end-to-end-tests)
6. [Performance Tests](#performance-tests)
7. [Security Tests](#security-tests)
8. [Chaos Testing](#chaos-testing)
9. [Test Execution Plan](#test-execution-plan)
10. [CI/CD Integration](#cicd-integration)
11. [Test Environments](#test-environments)
12. [Success Criteria](#success-criteria)

---

## Testing Strategy

### Objectives

1. **Functional Correctness**: Verify all features work as specified
2. **Performance**: Ensure system meets latency/throughput requirements
3. **Reliability**: Validate error handling and recovery mechanisms
4. **Security**: Confirm protection against common vulnerabilities
5. **Scalability**: Test system behavior under load
6. **Integration**: Verify seamless interaction between components

### Testing Principles

- **Shift-Left Testing**: Test early and often in development cycle
- **Test Automation**: Automate 95%+ of tests for consistent execution
- **Test Isolation**: Each test should be independent and repeatable
- **Realistic Data**: Use production-like data for integration/E2E tests
- **Fast Feedback**: Unit tests < 1s, Integration < 30s, E2E < 5min

---

## Test Pyramid

```
           /\
          /  \
         / E2E \       10% - End-to-End (40+ tests)
        /______\
       /        \
      /Integration\     30% - Integration (45+ tests)
     /____________\
    /              \
   /   Unit Tests   \   60% - Unit (200+ tests)
  /__________________\
```

### Distribution

- **Unit Tests (60%)**: Fast, isolated, component-level tests
- **Integration Tests (30%)**: Multi-component interaction tests
- **E2E Tests (10%)**: Full workflow tests from API to database

---

## Unit Tests

### Coverage Areas

#### 1. LLM Provider Router (`src/llm/provider_router.py`)

**Test Cases**:
- ✅ Tier-based routing (Tier 0 → Ollama, Tier 3 → Claude)
- ✅ Budget enforcement before LLM calls
- ✅ Failover to next tier on provider failure
- ✅ Privacy mode enforcement (Tier 0 only)
- ✅ Cost calculation for each provider
- ✅ Latency tracking
- ✅ Success/failure tracking

**Example Test**:
```python
@pytest.mark.asyncio
async def test_privacy_mode_enforces_tier_0():
    """Privacy mode should only use Tier 0 providers"""
    router = ProviderRouter(privacy_mode=True)

    # Mock all non-Tier 0 providers as unavailable
    with patch.object(router, 'anthropic_client', None):
        with patch.object(router, 'openai_client', None):
            result = await router.chat_completion(
                tier=3,  # Request Tier 3
                messages=[{"role": "user", "content": "test"}]
            )

            # Should fallback to Tier 0 (Ollama/Jan)
            assert result.provider in ["ollama", "jan"]
            assert result.tier == 0
```

#### 2. Budget Manager (`src/budget/manager.py`)

**Test Cases**:
- ✅ Atomic increment/decrement operations
- ✅ Alert triggering at 80%/100% thresholds
- ✅ Budget reset (daily/monthly)
- ✅ Concurrent request handling (race conditions)
- ✅ Budget exceeded rejection
- ✅ Multi-user budget isolation

**Example Test**:
```python
@pytest.mark.asyncio
async def test_budget_atomic_operations():
    """Budget operations must be atomic under concurrency"""
    manager = BudgetManager(redis_client)
    user_id = "test_user"

    # Set budget
    await manager.set_budget(user_id, "daily", 10.00)

    # Concurrent requests
    async def spend():
        return await manager.check_and_spend(user_id, 1.00)

    results = await asyncio.gather(*[spend() for _ in range(15)])

    # Exactly 10 should succeed, 5 should fail
    assert sum(results) == 10

    # Verify final balance
    spent = await manager.get_spent(user_id, "daily")
    assert spent == 10.00
```

#### 3. Tool Registry (`src/tools/registry.py`)

**Test Cases**:
- ✅ Function registration with decorator
- ✅ OpenAI schema generation
- ✅ Tool execution with arguments
- ✅ Error handling for invalid arguments
- ✅ Tool discovery by category
- ✅ Tool versioning

#### 4. Multi-Agent Coordinator (`src/agents/coordinator.py`)

**Test Cases**:
- ✅ Agent registration
- ✅ Task assignment routing
- ✅ Message publishing/subscribing
- ✅ Workflow orchestration
- ✅ Agent failure handling
- ✅ Result aggregation

#### 5. RAG Components

**BM25 Index** (`src/rag/bm25_index.py`):
- ✅ Document indexing
- ✅ Search with top-k results
- ✅ Score calculation
- ✅ Update/delete operations

**Metadata Filter** (`src/rag/metadata_filter.py`):
- ✅ Temporal filtering (last N days, date range)
- ✅ Category filtering
- ✅ Hierarchical filtering (parent/children)
- ✅ Numeric range filtering
- ✅ Complex filter composition (AND/OR)

#### 6. Streaming (`src/agents/streaming.py`)

**Test Cases**:
- ✅ Token-by-token streaming
- ✅ Buffer management
- ✅ Early termination on quality threshold
- ✅ Error handling during streaming
- ✅ Stream cancellation

#### 7. Workflow Versioning (`src/workflows/versioning.py`)

**Test Cases**:
- ✅ Version creation with semantic versioning
- ✅ Checksum calculation (SHA-256)
- ✅ Rollback to previous version
- ✅ Version comparison
- ✅ Lineage tracking

#### 8. A/B Testing (`src/workflows/ab_testing.py`)

**Test Cases**:
- ✅ Variant routing (50/50, 80/20)
- ✅ Metrics collection per variant
- ✅ Statistical significance calculation
- ✅ Auto-promotion on significance
- ✅ Traffic shifting

---

## Integration Tests

### Coverage Areas

#### 1. Multi-Agent Workflow (`tests/integration/test_multi_agent.py`)

**Test Scenarios**:
- ✅ Plan → Code → Review workflow
- ✅ Tool execution within agents
- ✅ Message passing between agents
- ✅ Shared context across agents
- ✅ Error propagation
- ✅ Timeout handling

**Example Test**:
```python
@pytest.mark.asyncio
async def test_plan_code_review_integration():
    """Test complete multi-agent workflow"""
    coordinator = AgentCoordinator(event_bus)

    # Setup agents
    planner = PlannerAgent(...)
    coder = CoderAgent(...)
    reviewer = ReviewerAgent(...)

    await coordinator.register_agent(planner)
    await coordinator.register_agent(coder)
    await coordinator.register_agent(reviewer)

    # Execute workflow
    task = {"instruction": "Create a function to calculate factorial"}

    plan = await coordinator.assign_task("planner", task)
    assert "steps" in plan

    code = await coordinator.assign_task("coder", plan["steps"][0])
    assert "code" in code

    review = await coordinator.assign_task("reviewer", {"code": code})
    assert review["approved"] is True
```

#### 2. Budget + Provider Integration

**Test Scenarios**:
- ✅ Budget check before LLM call
- ✅ Cost deduction after successful call
- ✅ Budget exceeded prevents call
- ✅ Alert triggered at thresholds
- ✅ Redis + PostgreSQL consistency

#### 3. RAG Pipeline Integration

**Test Scenarios**:
- ✅ Document ingestion → Qdrant
- ✅ Hybrid search (BM25 + semantic)
- ✅ Reranking with cross-encoder
- ✅ Metadata filtering on search
- ✅ Query rewriting → multi-query

#### 4. Health Checks Integration

**Test Scenarios**:
- ✅ All 11+ components checked
- ✅ Liveness probe (always returns 200)
- ✅ Readiness probe (critical deps only)
- ✅ Startup probe
- ✅ Component failure degradation

#### 5. Rate Limiting Integration

**Test Scenarios**:
- ✅ Per-endpoint rate limits
- ✅ Per-user rate limits
- ✅ X-RateLimit-* headers
- ✅ 429 response on limit exceeded
- ✅ Retry-After header

---

## End-to-End Tests

### Coverage Areas (`tests/e2e/test_multi_agent_workflow.py`)

#### 1. Complete Workflows

**Test Scenarios** (40+ test cases):

**Basic Workflows**:
1. ✅ Plan → Code → Review (success path)
2. ✅ Plan with multiple steps
3. ✅ Code generation with tool usage
4. ✅ Review rejection → re-code → approval
5. ✅ Streaming workflow with early termination

**Advanced Workflows**:
6. ✅ Workflow versioning (create, rollback)
7. ✅ A/B testing (variant routing, metrics)
8. ✅ Privacy mode (Tier 0 only)
9. ✅ Budget enforcement (rejection on exceeded)
10. ✅ Failover between providers

**Error Scenarios**:
11. ✅ Provider timeout → failover
12. ✅ Tool execution failure → retry
13. ✅ Invalid LLM response → error handling
14. ✅ Database connection loss → graceful degradation
15. ✅ Redis connection loss → fallback

**Example E2E Test**:
```python
@pytest.mark.asyncio
async def test_complete_workflow_with_versioning_and_ab_testing():
    """
    E2E: Create workflow version, run A/B test, verify metrics
    """
    # 1. Create workflow version
    workflow_data = {
        "name": "plan-code-review",
        "steps": [
            {"agent": "planner", "tier": 3},
            {"agent": "coder", "tier": 1},
            {"agent": "reviewer", "tier": 3}
        ]
    }

    version_id = await versioning_manager.create_version(
        workflow_id="test_workflow",
        version="1.0.0",
        workflow_data=workflow_data
    )

    # 2. Create A/B test
    experiment = await ab_testing_manager.create_experiment(
        name="coder_tier_test",
        variants=[
            {"name": "control", "config": {"coder_tier": 1}, "traffic": 50},
            {"name": "variant", "config": {"coder_tier": 3}, "traffic": 50}
        ]
    )

    # 3. Execute workflow 100 times
    for i in range(100):
        variant = await ab_testing_manager.get_variant(
            experiment_id=experiment.id,
            user_id=f"user_{i}"
        )

        # Execute workflow with variant config
        result = await coordinator.execute_workflow(
            workflow_id="test_workflow",
            version=version_id,
            config=variant.config
        )

        # Record metrics
        await ab_testing_manager.record_metric(
            experiment_id=experiment.id,
            variant_name=variant.name,
            metric_name="success",
            value=1 if result["approved"] else 0
        )

    # 4. Verify metrics
    metrics = await ab_testing_manager.get_metrics(experiment.id)
    assert "control" in metrics
    assert "variant" in metrics

    # 5. Check statistical significance
    is_significant = await ab_testing_manager.calculate_significance(
        experiment.id
    )

    if is_significant:
        await ab_testing_manager.promote_variant(experiment.id)
```

#### 2. API Testing

**Endpoints to Test**:
- ✅ `POST /api/v1/budget/limit` - Set budget
- ✅ `GET /api/v1/budget/status` - Check budget
- ✅ `POST /api/v1/budget/spend` - Record spending
- ✅ `GET /health` - Overall health
- ✅ `GET /health/ready` - Readiness probe
- ✅ `GET /health/live` - Liveness probe

**Example API Test**:
```python
@pytest.mark.asyncio
async def test_budget_api_complete_flow(client):
    """E2E test for budget API"""
    user_id = "test_user"

    # 1. Set budget
    response = await client.post("/api/v1/budget/limit", json={
        "user_id": user_id,
        "period": "daily",
        "limit": 10.00
    })
    assert response.status_code == 200

    # 2. Check status
    response = await client.get(f"/api/v1/budget/status?user_id={user_id}")
    assert response.status_code == 200
    assert response.json()["limit"] == 10.00
    assert response.json()["spent"] == 0.00

    # 3. Spend (should succeed)
    response = await client.post("/api/v1/budget/spend", json={
        "user_id": user_id,
        "amount": 5.00
    })
    assert response.status_code == 200

    # 4. Check status again
    response = await client.get(f"/api/v1/budget/status?user_id={user_id}")
    assert response.json()["spent"] == 5.00
    assert response.json()["utilization"] == 0.5

    # 5. Spend over budget (should fail)
    response = await client.post("/api/v1/budget/spend", json={
        "user_id": user_id,
        "amount": 10.00
    })
    assert response.status_code == 429  # Rate limited / budget exceeded
```

---

## Performance Tests

### Framework (`tests/performance/benchmark.py`)

**Test Scenarios**:

#### 1. Throughput Benchmarks

**Targets**:
- Chat completion: **100 req/s** (Tier 1)
- RAG search: **50 req/s**
- Budget check: **1000 req/s** (Redis)
- Tool execution: **200 req/s**

**Example Benchmark**:
```python
async def test_llm_throughput():
    """Benchmark LLM chat completion throughput"""
    benchmark = PerformanceBenchmark()

    async def chat_request():
        return await provider_router.chat_completion(
            tier=1,
            messages=[{"role": "user", "content": "Hello"}]
        )

    result = await benchmark.run(
        name="Chat Completion Throughput",
        func=chat_request,
        iterations=1000,
        concurrency=50
    )

    # Assert performance requirements
    assert result.throughput >= 100  # 100 req/s minimum
    assert result.p95_latency <= 1.0  # P95 < 1 second
    assert result.success_rate >= 0.99  # 99% success

    benchmark.print_report(result)
```

#### 2. Latency Benchmarks

**Targets**:
- P50 latency: **< 200ms** (RAG search)
- P95 latency: **< 500ms** (RAG search)
- P99 latency: **< 1000ms** (RAG search)
- Chat completion P95: **< 2000ms** (Tier 1)

#### 3. Resource Benchmarks

**Targets**:
- CPU usage: **< 70%** average
- Memory usage: **< 4GB** average
- Redis connections: **< 100**
- PostgreSQL connections: **< 50**

#### 4. Cost Benchmarks

**Targets**:
- Average cost per request: **< $0.002** (Tier 1)
- Daily budget compliance: **100%** enforcement
- Cost tracking accuracy: **99.9%**

#### 5. Concurrent User Benchmarks

**Test Scenarios**:
- ✅ 10 concurrent users
- ✅ 100 concurrent users
- ✅ 1000 concurrent users (stress test)

**Load Pattern**:
```python
async def test_concurrent_users_stress():
    """Stress test with 1000 concurrent users"""
    async def user_session(user_id):
        # Simulate realistic user behavior
        for _ in range(10):  # 10 requests per user
            # RAG search
            await search_workbench.hybrid_search("test query")
            await asyncio.sleep(random.uniform(1, 5))  # Think time

            # Chat completion
            await provider_router.chat_completion(
                tier=1,
                messages=[{"role": "user", "content": "test"}]
            )
            await asyncio.sleep(random.uniform(2, 10))

    # 1000 concurrent users
    tasks = [user_session(f"user_{i}") for i in range(1000)]

    start = time.time()
    results = await asyncio.gather(*tasks, return_exceptions=True)
    duration = time.time() - start

    # Verify
    errors = [r for r in results if isinstance(r, Exception)]
    error_rate = len(errors) / len(results)

    assert error_rate < 0.01  # < 1% error rate
    assert duration < 120  # Complete within 2 minutes
```

---

## Security Tests

### Coverage Areas (`docs/SECURITY-AUDIT.md`)

#### 1. OWASP Top 10 Testing

**A01: Broken Access Control**:
- ✅ Rate limiting enforcement
- ✅ Budget enforcement
- ✅ Endpoint protection

**A02: Cryptographic Failures**:
- ✅ TLS verification
- ✅ Secrets not in code
- ✅ Database password protection

**A03: Injection**:
- ✅ SQL injection (parameterized queries)
- ✅ Command injection (no os.system with user input)
- ✅ NoSQL injection (Pydantic validation)

**A04-A10**: See SECURITY-AUDIT.md for complete test coverage

#### 2. Input Validation Tests

**Test Cases**:
```python
@pytest.mark.asyncio
async def test_input_validation_sql_injection():
    """Verify protection against SQL injection"""
    # Malicious input
    user_id = "'; DROP TABLE users; --"

    # Should be safely parameterized
    result = await budget_manager.get_spent(user_id, "daily")

    # Should not execute SQL injection
    # Verify database integrity
    async with db_pool.acquire() as conn:
        tables = await conn.fetch("SELECT tablename FROM pg_tables")
        table_names = [t["tablename"] for t in tables]
        assert "users" in table_names  # Table still exists
```

#### 3. Rate Limiting Security Tests

**Test Cases**:
- ✅ Sliding window prevents burst attacks
- ✅ Per-IP limiting
- ✅ Per-user limiting
- ✅ Distributed rate limiting (Redis)

#### 4. Secrets Management Tests

**Test Cases**:
- ✅ No hardcoded secrets in code
- ✅ Environment variables used
- ✅ .env files not committed (gitignore)
- ✅ API keys not logged

---

## Chaos Testing

### Objectives

Validate system resilience under failure conditions.

### Test Scenarios

#### 1. Service Failures

**Redis Failure**:
```python
@pytest.mark.chaos
async def test_redis_failure_graceful_degradation():
    """System should degrade gracefully when Redis fails"""
    # Stop Redis
    await redis_client.close()

    # Budget checks should fail open (allow requests)
    result = await provider_router.chat_completion(
        tier=1,
        messages=[{"role": "user", "content": "test"}]
    )

    assert result is not None  # Request succeeds
    # Log warning about Redis unavailability
```

**PostgreSQL Failure**:
```python
@pytest.mark.chaos
async def test_postgres_failure_graceful_degradation():
    """System should continue without PostgreSQL (metrics only)"""
    # Stop PostgreSQL
    await db_pool.close()

    # LLM requests should still work (metrics not recorded)
    result = await provider_router.chat_completion(
        tier=1,
        messages=[{"role": "user", "content": "test"}]
    )

    assert result is not None
```

#### 2. Network Partitions

**Test Scenarios**:
- ✅ Redis network partition (fail open)
- ✅ Qdrant network partition (graceful degradation)
- ✅ LLM provider timeout (failover to next tier)

#### 3. Resource Exhaustion

**Test Scenarios**:
- ✅ Memory exhaustion (OOM handling)
- ✅ CPU saturation (request throttling)
- ✅ Disk full (log rotation)
- ✅ Connection pool exhaustion (backpressure)

#### 4. Cascading Failures

**Test Scenario**:
```python
@pytest.mark.chaos
async def test_cascading_failure_circuit_breaker():
    """Verify circuit breaker prevents cascading failures"""
    # Simulate Tier 1 provider failure
    with patch.object(provider_router, 'fireworks_client', None):
        with patch.object(provider_router, 'together_client', None):

            # Multiple requests should trigger circuit breaker
            for i in range(100):
                try:
                    await provider_router.chat_completion(tier=1, messages=[...])
                except Exception:
                    pass

            # Circuit should be OPEN (fail fast)
            # Next requests should fail immediately without trying provider
            start = time.time()
            with pytest.raises(CircuitBreakerOpenError):
                await provider_router.chat_completion(tier=1, messages=[...])
            duration = time.time() - start

            assert duration < 0.1  # Fail fast (< 100ms)
```

---

## Test Execution Plan

### Phase 1: Development Testing (Continuous)

**Frequency**: On every commit
**Duration**: < 5 minutes

**Tests**:
1. Unit tests (all)
2. Fast integration tests (critical paths)
3. Linting (ruff, mypy)
4. Security scanning (bandit)

**Command**:
```bash
# Run unit tests
pytest tests/unit -v --cov=src --cov-report=html

# Run fast integration tests
pytest tests/integration -m "not slow" -v

# Linting
ruff check src/
mypy src/

# Security scan
bandit -r src/
```

### Phase 2: Pre-Merge Testing (On PR)

**Frequency**: On pull request
**Duration**: < 15 minutes

**Tests**:
1. All unit tests
2. All integration tests
3. Critical E2E tests
4. Performance regression tests
5. Security audit

**Command**:
```bash
# Full test suite
pytest tests/ -v --cov=src --cov-report=html

# Performance benchmarks (critical paths only)
pytest tests/performance -k "critical" -v

# Security audit
python -m scripts.security_audit
```

### Phase 3: Staging Deployment Testing

**Frequency**: On deployment to staging
**Duration**: < 30 minutes

**Tests**:
1. All E2E tests
2. Full performance benchmarks
3. Chaos testing (selected scenarios)
4. Security penetration tests

**Command**:
```bash
# E2E tests against staging
TEST_ENV=staging pytest tests/e2e -v

# Full performance benchmarks
pytest tests/performance -v

# Chaos tests
pytest tests/chaos -m "staging_safe" -v
```

### Phase 4: Production Deployment Testing

**Frequency**: On deployment to production
**Duration**: < 60 minutes

**Tests**:
1. Smoke tests (critical paths)
2. Health checks (all components)
3. Canary analysis (1% traffic)
4. Rollback testing

**Command**:
```bash
# Smoke tests
pytest tests/smoke -v --env=production

# Health checks
./scripts/health-check.sh production

# Canary deployment
./scripts/deploy.sh production canary

# Monitor for 30 minutes, then decide
# If success: promote
# If failure: rollback
```

### Phase 5: Continuous Monitoring (Production)

**Frequency**: Continuous
**Duration**: 24/7

**Monitoring**:
1. Synthetic transactions (every 5 minutes)
2. Real user monitoring (RUM)
3. Error rate tracking
4. Latency monitoring (P95/P99)
5. Cost tracking

**Alerts**:
- Error rate > 1% → Page on-call
- P95 latency > 2s → Slack alert
- Budget exceeded → Email alert
- Service down → Page on-call

---

## CI/CD Integration

### GitHub Actions Workflow (`.github/workflows/ci-cd.yml`)

**Stages**:

1. **Lint & Format** (2 min)
   - Ruff linting
   - Black formatting
   - isort imports
   - mypy type checking

2. **Unit Tests** (3 min)
   - pytest with coverage
   - Coverage threshold: 80%
   - Generate coverage report

3. **Integration Tests** (5 min)
   - Docker Compose setup
   - Integration test suite
   - Teardown

4. **Security Scan** (2 min)
   - Bandit (SAST)
   - Trivy (container scan)
   - Safety (dependency check)

5. **Build** (3 min)
   - Docker image build
   - Tag with commit SHA
   - Push to registry

6. **E2E Tests (Staging)** (10 min)
   - Deploy to staging
   - Run E2E test suite
   - Collect logs

7. **Performance Tests (Staging)** (10 min)
   - Run benchmarks
   - Compare to baseline
   - Fail if regression > 10%

8. **Deploy (Production)** (5 min)
   - Canary deployment (1%)
   - Monitor for 10 minutes
   - Auto-promote or rollback

9. **Post-Deployment** (5 min)
   - Smoke tests
   - Health checks
   - Notify team

**Total Pipeline Duration**: ~45 minutes (with parallelization)

---

## Test Environments

### 1. Local Development

**Setup**:
```bash
docker-compose -f docker-compose.dev.yml up -d
pytest tests/unit -v
```

**Components**:
- Redis (local)
- PostgreSQL (local)
- Qdrant (local)
- Ollama (local)
- Mock LLM providers

### 2. CI Environment

**Setup**: Automated via GitHub Actions

**Components**:
- All services in Docker
- Test databases (ephemeral)
- Mock external APIs

### 3. Staging Environment

**Setup**: Kubernetes cluster (staging namespace)

**Components**:
- All production services
- Separate databases
- Real LLM providers (test accounts)
- Monitoring (Prometheus + Grafana)

### 4. Production Environment

**Setup**: Kubernetes cluster (production namespace)

**Components**:
- High availability (3+ replicas)
- Production databases
- Real LLM providers
- Full monitoring stack
- Alerting (PagerDuty)

---

## Success Criteria

### Test Coverage

- ✅ Unit test coverage: **≥ 80%**
- ✅ Integration test coverage: **≥ 70%**
- ✅ E2E test coverage: **100% of critical paths**
- ✅ Security test coverage: **OWASP Top 10**

### Performance

- ✅ Throughput: **≥ 100 req/s** (Tier 1 LLM)
- ✅ P95 latency: **< 500ms** (RAG search)
- ✅ P99 latency: **< 1000ms** (RAG search)
- ✅ Success rate: **≥ 99.9%**

### Reliability

- ✅ Uptime: **≥ 99.9%** (3 nines)
- ✅ Error rate: **< 0.1%**
- ✅ Recovery time: **< 5 minutes** (automated rollback)

### Security

- ✅ OWASP Top 10: **All protected**
- ✅ Security score: **≥ 90/100**
- ✅ Vulnerability scan: **0 critical, 0 high severity**

### Cost

- ✅ Average cost per request: **< $0.002** (Tier 1)
- ✅ Budget enforcement: **100%** accuracy
- ✅ Cost prediction accuracy: **≥ 95%**

---

## Test Execution Commands

### Run All Tests

```bash
# Full test suite
pytest tests/ -v --cov=src --cov-report=html --cov-report=term

# View coverage report
open htmlcov/index.html
```

### Run Specific Test Suites

```bash
# Unit tests only
pytest tests/unit -v

# Integration tests only
pytest tests/integration -v

# E2E tests only
pytest tests/e2e -v

# Performance tests only
pytest tests/performance -v

# Security tests only
pytest tests/security -v

# Chaos tests only
pytest tests/chaos -v -m chaos
```

### Run with Markers

```bash
# Fast tests only
pytest -m "not slow" -v

# Critical tests only
pytest -m critical -v

# Slow tests only
pytest -m slow -v

# Staging-safe chaos tests
pytest tests/chaos -m staging_safe -v
```

### Generate Reports

```bash
# HTML coverage report
pytest --cov=src --cov-report=html

# JSON report for CI
pytest --json-report --json-report-file=report.json

# JUnit XML report
pytest --junitxml=junit.xml

# Performance benchmark report
pytest tests/performance -v
# Check: agent_benchmark_results.json, rag_benchmark_results.json
```

---

## Continuous Improvement

### Test Metrics to Track

1. **Test Execution Time**: Trend over time (should decrease)
2. **Test Flakiness**: % of flaky tests (target: < 1%)
3. **Test Coverage**: Track coverage delta per PR
4. **Bug Escape Rate**: Bugs found in production vs caught in testing
5. **Performance Regression**: Track performance trends

### Regular Reviews

- **Weekly**: Review failed tests and flaky tests
- **Monthly**: Review test coverage gaps
- **Quarterly**: Performance benchmark review
- **Annually**: Full testing strategy review

---

## Appendix: Test Data

### Sample Test Data

**Users**:
```json
[
  {"user_id": "user_001", "budget_daily": 10.00, "budget_monthly": 100.00},
  {"user_id": "user_002", "budget_daily": 5.00, "budget_monthly": 50.00},
  {"user_id": "user_003", "budget_daily": 0.00, "budget_monthly": 0.00}
]
```

**Documents** (RAG):
```json
[
  {
    "id": "doc_001",
    "content": "Multi-agent systems coordinate multiple AI agents...",
    "metadata": {"category": "ai", "created_at": "2025-01-01", "tags": ["agents", "coordination"]}
  },
  {
    "id": "doc_002",
    "content": "RAG combines retrieval and generation...",
    "metadata": {"category": "ai", "created_at": "2025-01-15", "tags": ["rag", "retrieval"]}
  }
]
```

**Workflows**:
```json
{
  "name": "plan-code-review",
  "version": "1.0.0",
  "steps": [
    {"agent": "planner", "tier": 3},
    {"agent": "coder", "tier": 1},
    {"agent": "reviewer", "tier": 3}
  ]
}
```

---

## Conclusion

This comprehensive testing plan ensures the v4.2 Multi-Agent RAG Orchestrator meets all functional, performance, security, and reliability requirements. By following the test pyramid, automating 95%+ of tests, and integrating with CI/CD, we achieve:

- ✅ **Fast Feedback**: Unit tests in < 1s
- ✅ **High Confidence**: 90%+ test coverage
- ✅ **Production Ready**: Comprehensive E2E and chaos testing
- ✅ **Continuous Improvement**: Performance tracking and regression detection

**Next Steps**:
1. Execute Phase 1 tests (development)
2. Set up CI/CD pipeline
3. Execute Phase 2-4 tests (staging/production)
4. Establish monitoring and alerting
5. Schedule regular test reviews

---

**Prepared By**: Multi-Agent RAG Orchestrator Team
**Review Date**: 2025-11-18
**Next Review**: 2026-02-18 (Quarterly)
