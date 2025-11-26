# Multi-Agent RAG Orchestrator v4.2 - Implementation Tasks

**Version**: 4.2.0
**Date**: 2025-11-18
**Status**: Active
**Timeline**: 7-8 weeks (4 phases)
**Related Documents**:
- [01-spec_v4.2.md](01-spec_v4.2.md)
- [02-plan_v4.2.md](02-plan_v4.2.md)
- [v4.2-ENHANCEMENT-PLAN.md](v4.2-ENHANCEMENT-PLAN.md)

---

## Overview

This document provides **actionable implementation tasks** for v4.2, organized by phase with priorities, owners, dependencies, and acceptance criteria.

**Total Tasks**: 85
**Total Estimated Effort**: 38-46 days
**Team Size**: 2-3 engineers
**Timeline**: 7-8 weeks

---

## Task Prioritization

- **P0 (Critical)**: Must-have for v4.2 launch
- **P1 (High)**: Important for production readiness
- **P2 (Medium)**: Nice-to-have enhancements
- **P3 (Low)**: Future consideration

---

## Phase 1: Critical Foundations (Week 1-2)

**Objectives**: LLMOps observability, hybrid search, MCP servers, privacy-hardened Playwright, provider abstraction, budget enforcement

**Duration**: 10-12 days
**Priority**: P0

---

### Epic 1.1: LLMOps Observability

#### TASK-001: PostgreSQL Schema Setup [P0]
**Owner**: DevOps Engineer
**Effort**: 0.5 days
**Dependencies**: None

**Description**:
Create PostgreSQL database and tables for LLMOps logging.

**Acceptance Criteria**:
- [ ] Database `orchestrator` created
- [ ] Table `llm_invocations` created with all columns (FR-166)
- [ ] Indexes created: `idx_trace`, `idx_user_tier`, `idx_timestamp`, `idx_task_type`
- [ ] Table `workflow_versions` created (FR-174)
- [ ] Table `agent_messages` created (FR-208)
- [ ] Migration script created for idempotent setup
- [ ] Backup policy configured (30-day retention)

**Deliverable**: SQL migration script in `/migrations/001_llmops_schema.sql`

---

#### TASK-002: LLM Invocation Logger [P0]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-001

**Description**:
Implement logger that captures all LLM invocations to PostgreSQL.

**Acceptance Criteria**:
- [ ] Python class `LLMOpsLogger` with `log_invocation()` method
- [ ] Captures: trace_id, timestamp, user_id, tier, model, tokens, cost, latency, success, error
- [ ] Async logging (non-blocking)
- [ ] Unit tests with 90%+ coverage
- [ ] Integration test: 1000 concurrent log writes
- [ ] Performance: <10ms overhead per call

**Deliverable**: `src/llmops/logger.py`

---

#### TASK-003: Cost Tracking in Redis [P0]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: TASK-001

**Description**:
Implement real-time cost tracking using Redis.

**Acceptance Criteria**:
- [ ] Redis keys: `cost:daily:{tier}`, `cost:weekly:{tier}`, `cost:monthly:{tier}`
- [ ] Atomic increment operations (`INCRBYFLOAT`)
- [ ] Auto-expiry: daily (24h), weekly (7d), monthly (30d)
- [ ] Dashboard endpoint: `GET /api/costs` returns aggregated costs
- [ ] Performance: <5ms per increment

**Deliverable**: `src/cost/redis_tracker.py`

---

#### TASK-004: Historical Analysis Queries [P1]
**Owner**: Data Engineer
**Effort**: 1 day
**Dependencies**: TASK-001, TASK-002

**Description**:
Create SQL queries for tier optimization and historical analysis.

**Acceptance Criteria**:
- [ ] Query: Optimal tier per task_type based on success_rate and cost
- [ ] Query: Cost trends (daily/weekly/monthly)
- [ ] Query: Latency percentiles (p50, p95, p99) by tier
- [ ] Query: Error rate by provider
- [ ] Performance: All queries <2s on 30 days of data
- [ ] Materialized views for expensive aggregations

**Deliverable**: `sql/analytics_queries.sql`

---

#### TASK-005: LLMOps Dashboard (Basic) [P1]
**Owner**: Frontend Engineer
**Effort**: 2 days
**Dependencies**: TASK-003, TASK-004

**Description**:
Build basic Grafana dashboard for LLMOps metrics.

**Acceptance Criteria**:
- [ ] Panel: Cost over time (line chart)
- [ ] Panel: Invocations by tier (pie chart)
- [ ] Panel: Latency percentiles (histogram)
- [ ] Panel: Success rate by provider (bar chart)
- [ ] Refresh rate: 30 seconds
- [ ] Export as JSON for version control

**Deliverable**: `grafana/dashboards/llmops-basic.json`

---

### Epic 1.2: Hybrid Search RAG

#### TASK-006: BM25 Index Implementation [P0]
**Owner**: ML Engineer
**Effort**: 2 days
**Dependencies**: None

**Description**:
Implement BM25 keyword search index alongside Qdrant.

**Acceptance Criteria**:
- [ ] Python class `BM25Index` using `rank_bm25` library
- [ ] Indexing: Tokenize documents, build BM25 index
- [ ] Search: Query BM25, return scores
- [ ] Performance: <30ms search latency (p95)
- [ ] Memory: <100MB for 10k documents
- [ ] Unit tests with edge cases (empty query, special chars)

**Deliverable**: `src/rag/bm25_index.py`

---

#### TASK-007: Hybrid Search Engine [P0]
**Owner**: ML Engineer
**Effort**: 2 days
**Dependencies**: TASK-006

**Description**:
Combine Qdrant semantic search with BM25 keyword search.

**Acceptance Criteria**:
- [ ] Python class `HybridSearchRAG`
- [ ] Configurable weights: semantic (default 0.7), keyword (default 0.3)
- [ ] Score normalization (0-1 range)
- [ ] Over-fetch factor: 2x top_k for reranking
- [ ] A/B test harness: Compare hybrid vs semantic-only
- [ ] Performance: p95 latency <200ms
- [ ] Accuracy: ≥30% precision@5 improvement in A/B test

**Deliverable**: `src/rag/hybrid_search.py`

---

#### TASK-008: Semantic Chunking [P1]
**Owner**: ML Engineer
**Effort**: 3 days
**Dependencies**: None

**Description**:
Implement semantic chunking using spaCy sentence embeddings.

**Acceptance Criteria**:
- [ ] Python class `SemanticChunker`
- [ ] spaCy model: `en_core_web_sm` (or larger)
- [ ] Similarity threshold: configurable (default 0.7)
- [ ] Specialized chunkers: code, markdown, JSON
- [ ] Document type detection (heuristics or model)
- [ ] A/B test: -25% hallucination rate vs fixed chunking
- [ ] Performance: <1s for 10k-word document

**Deliverable**: `src/rag/semantic_chunker.py`

---

#### TASK-009: Reranking Pipeline [P1]
**Owner**: ML Engineer
**Effort**: 2 days
**Dependencies**: TASK-007

**Description**:
Implement two-stage retrieval with cross-encoder reranking.

**Acceptance Criteria**:
- [ ] Python class `RerankerPipeline`
- [ ] Model: `cross-encoder/ms-marco-MiniLM-L-6-v2`
- [ ] Adaptive reranking: always for Tier 3, conditional for Tier 0/1
- [ ] Performance: <400ms latency (p95)
- [ ] A/B test: ≥15% precision@5 improvement
- [ ] Cost tracking: log reranking invocations

**Deliverable**: `src/rag/reranker.py`

---

### Epic 1.3: Privacy Mode & MCP Servers

#### TASK-010: MCP Filesystem Server Deployment [P0]
**Owner**: DevOps Engineer
**Effort**: 2 days
**Dependencies**: None

**Description**:
Deploy MCP filesystem server with sandboxed access.

**Acceptance Criteria**:
- [ ] Docker container from modelcontextprotocol/servers repo
- [ ] Config: `allowedPaths`, `operations`, `maxFileSize`
- [ ] Port: 3001
- [ ] Health check endpoint: `GET /health`
- [ ] Security test: Path traversal blocked (`../../../etc/passwd`)
- [ ] Performance: <50ms per file read
- [ ] Documentation: Setup guide

**Deliverable**: `docker/mcp-filesystem/`

---

#### TASK-011: MCP Git Server Deployment [P0]
**Owner**: DevOps Engineer
**Effort**: 1 day
**Dependencies**: None

**Description**:
Deploy MCP git server for local repository access.

**Acceptance Criteria**:
- [ ] Docker container from modelcontextprotocol/servers repo
- [ ] Config: `allowedRepos`, `operations` (read, search, log only)
- [ ] Port: 3002
- [ ] Health check endpoint
- [ ] Security test: No push/pull allowed
- [ ] Performance: <100ms for `git log`

**Deliverable**: `docker/mcp-git/`

---

#### TASK-012: MCP Memory Server Deployment [P0]
**Owner**: DevOps Engineer
**Effort**: 1 day
**Dependencies**: None

**Description**:
Deploy MCP memory server for in-process knowledge graph.

**Acceptance Criteria**:
- [ ] Docker container from modelcontextprotocol/servers repo
- [ ] Local persistence with encryption (AES-256)
- [ ] Port: 3003
- [ ] Health check endpoint
- [ ] API documentation

**Deliverable**: `docker/mcp-memory/`

---

#### TASK-013: MCP Client Integration [P0]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-010, TASK-011, TASK-012

**Description**:
Integrate MCP servers with n8n workflows via client library.

**Acceptance Criteria**:
- [ ] Python/JavaScript MCP client wrapper
- [ ] Tool discovery: Automatically register MCP capabilities
- [ ] Privacy filtering: Only expose MCP tools in privacy mode
- [ ] Error handling: Retry with exponential backoff
- [ ] Audit logging: Log all MCP tool invocations
- [ ] Integration test: Call filesystem.read_file() from n8n

**Deliverable**: `src/mcp/client.py`

---

#### TASK-014: Jan Integration [P1]
**Owner**: Backend Engineer
**Effort**: 1.5 days
**Dependencies**: None

**Description**:
Deploy Jan and integrate as OpenAI-compatible local API.

**Acceptance Criteria**:
- [ ] Jan Docker container deployed
- [ ] Port: 1337
- [ ] Models downloaded: llama3.1:70b
- [ ] OpenAI-compatible endpoint: `/v1/chat/completions`
- [ ] Provider wrapper: `JanProvider` class
- [ ] Privacy mode: Route to Jan when privacy=true
- [ ] Performance: Same as Ollama (~2s for 100 tokens)

**Deliverable**: `docker/jan/`, `src/providers/jan_provider.py`

---

### Epic 1.4: Privacy-Hardened Playwright

#### TASK-015: Stealth Playwright Setup [P1]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: None

**Description**:
Set up Playwright with stealth plugin and anti-detection.

**Acceptance Criteria**:
- [ ] `puppeteer-extra-plugin-stealth` installed
- [ ] Configuration: Disable webdriver detection
- [ ] Random user agent rotation (3+ agents)
- [ ] Random viewport dimensions (1920-2120 × 1080-1180)
- [ ] Canvas noise injection
- [ ] Benchmark: <5% CAPTCHA encounter rate

**Deliverable**: `src/web_agent/stealth_browser.js`

---

#### TASK-016: Tracker Blocking [P1]
**Owner**: Backend Engineer
**Effort**: 0.5 days
**Dependencies**: TASK-015

**Description**:
Implement tracker blocking via Playwright route interception.

**Acceptance Criteria**:
- [ ] Block list: google-analytics.com, facebook.com/tr, doubleclick.net, googletagmanager.com
- [ ] Route interception: `page.route('**/*', handler)`
- [ ] Logging: Count blocked trackers
- [ ] Performance: <5ms overhead per page load

**Deliverable**: Update `src/web_agent/stealth_browser.js`

---

#### TASK-017: LLM-Driven Browser Pattern [P1]
**Owner**: Backend Engineer
**Effort**: 3 days
**Dependencies**: TASK-015

**Description**:
Implement action-perception loop for autonomous browsing.

**Acceptance Criteria**:
- [ ] Loop: Observe page → LLM decides action → Execute → Repeat
- [ ] Actions: navigate, click, type, extract, scroll, done
- [ ] Max iterations: 10
- [ ] Tier routing: Tier 0 (privacy) or Tier 2 (vision)
- [ ] Benchmark: ≥90% success rate on 100 test tasks
- [ ] Average duration: 12-15 seconds

**Deliverable**: `src/web_agent/llm_browser.py`

---

#### TASK-018: LLM-as-Judge Validation [P2]
**Owner**: ML Engineer
**Effort**: 1 day
**Dependencies**: TASK-017

**Description**:
Implement LLM-as-judge for task success validation.

**Acceptance Criteria**:
- [ ] After task completion, LLM judges success (binary + reason)
- [ ] Prompt: Original task, final state, extracted data
- [ ] Accuracy: ≥90% agreement with human evaluators (sample 50 tasks)
- [ ] Logging: Store judgment in PostgreSQL

**Deliverable**: `src/web_agent/llm_judge.py`

---

### Epic 1.5: Provider Abstraction & Failover

#### TASK-019: Provider Interface Design [P0]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: None

**Description**:
Design abstract base class for LLM providers.

**Acceptance Criteria**:
- [ ] Abstract class `LLMProvider` with methods:
  - `async chat_completion(model, messages, **kwargs) → Response`
  - `async health_check() → bool`
  - `get_cost(input_tokens, output_tokens) → float`
- [ ] Type hints for all methods
- [ ] Documentation with examples

**Deliverable**: `src/providers/base.py`

---

#### TASK-020: Provider Implementations [P0]
**Owner**: Backend Engineer
**Effort**: 3 days
**Dependencies**: TASK-019

**Description**:
Implement provider classes for all tiers.

**Acceptance Criteria**:
- [ ] `OllamaProvider` (Tier 0/2)
- [ ] `FireworksProvider` (Tier 1)
- [ ] `TogetherProvider` (Tier 1)
- [ ] `AnthropicProvider` (Tier 3)
- [ ] `OpenAIProvider` (Tier 3)
- [ ] `JanProvider` (Privacy mode)
- [ ] Unit tests for each provider (mock API calls)
- [ ] Integration tests with live APIs (staging only)

**Deliverable**: `src/providers/`

---

#### TASK-021: Provider Router [P0]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-020

**Description**:
Implement router with health checks and automatic failover.

**Acceptance Criteria**:
- [ ] Class `ProviderRouter`
- [ ] Health checks every 5 minutes, cached 5 minutes
- [ ] Failover chain: Tier N → Tier N+1 → Tier 3
- [ ] Circuit breaker: Open after 3 failures, retry after 30s
- [ ] Latency: <2s for failover
- [ ] Logging: Alert on failover events
- [ ] Integration test: Kill Ollama, verify failover to Tier 1

**Deliverable**: `src/providers/router.py`

---

### Epic 1.6: Budget Enforcement

#### TASK-022: Redis Budget Schema [P0]
**Owner**: Backend Engineer
**Effort**: 0.5 days
**Dependencies**: None

**Description**:
Design Redis key schema for budget pools.

**Acceptance Criteria**:
- [ ] Keys: `budget:{user_id}:{period}`, `budget:{user_id}:{period}:limit`
- [ ] TTL: daily (24h), weekly (7d), monthly (30d)
- [ ] Data type: String (float)
- [ ] Documentation: Key patterns and usage

**Deliverable**: `docs/redis-schema.md`

---

#### TASK-023: Budget Enforcer [P0]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-022

**Description**:
Implement budget enforcer with atomic check-and-deduct.

**Acceptance Criteria**:
- [ ] Class `BudgetEnforcer`
- [ ] Methods: `create_budget()`, `check_budget()`, `deduct_budget()`, `get_status()`
- [ ] Atomic operations: Redis transactions (MULTI/EXEC)
- [ ] Race condition handling: Retry on WatchError
- [ ] Utilization alerts: 80%, 90%, 95%
- [ ] Performance: <5ms per check
- [ ] Unit tests: Concurrent deductions (10 threads)

**Deliverable**: `src/budget/enforcer.py`

---

#### TASK-024: Budget API Endpoints [P0]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: TASK-023

**Description**:
Create REST API for budget management.

**Acceptance Criteria**:
- [ ] `POST /api/budgets` - Create budget
- [ ] `GET /api/budgets/{user_id}` - Get status
- [ ] `DELETE /api/budgets/{user_id}/{period}` - Reset budget
- [ ] OpenAPI 3.0 documentation
- [ ] Authentication required (JWT)
- [ ] Rate limiting: 100 req/min per user

**Deliverable**: `src/api/budgets.py`

---

## Phase 2: Enhanced Intelligence (Week 3-4)

**Objectives**: Tool registry, message-driven agents, agent workbenches, streaming

**Duration**: 8-10 days
**Priority**: P1

---

### Epic 2.1: Tool Registry & Workbenches

#### TASK-025: Tool Registry Schema [P1]
**Owner**: Backend Engineer
**Effort**: 0.5 days
**Dependencies**: None

**Description**:
Design tool registry data model.

**Acceptance Criteria**:
- [ ] Tool metadata: id, name, description, category, privacy_compatible, requires, cost_tier, handler
- [ ] Storage: PostgreSQL or in-memory (decide based on scale)
- [ ] Documentation: Schema and examples

**Deliverable**: `docs/tool-registry-schema.md`

---

#### TASK-026: Tool Registry Implementation [P1]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-025

**Description**:
Implement centralized tool registry.

**Acceptance Criteria**:
- [ ] Class `ToolRegistry`
- [ ] Methods: `register(tool)`, `getToolsForAgent(agent_type, privacy_mode)`, `list()`
- [ ] Dependency resolution
- [ ] Privacy filtering
- [ ] Hot-reload for new registrations
- [ ] Unit tests: 90%+ coverage

**Deliverable**: `src/tools/registry.py`

---

#### TASK-027: Agent Workbench [P1]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-026

**Description**:
Implement agent workbench for composable tools.

**Acceptance Criteria**:
- [ ] Class `AgentWorkbench`
- [ ] Methods: `addTool()`, `addMCPServer()`, `getTools(privacy_mode)`, `executeTool()`
- [ ] MCP auto-discovery: Load capabilities on startup
- [ ] Tool usage analytics: Log frequency, cost, latency
- [ ] Unit tests: Mock tools and MCP servers

**Deliverable**: `src/agents/workbench.py`

---

### Epic 2.2: Message-Driven Multi-Agent

#### TASK-028: Agent Coordinator [P1]
**Owner**: Backend Engineer
**Effort**: 3 days
**Dependencies**: None

**Description**:
Implement event-driven agent coordinator.

**Acceptance Criteria**:
- [ ] Class `AgentCoordinator extends EventEmitter`
- [ ] Methods: `registerAgent()`, `routeMessage()`, `executeWorkflow()`
- [ ] Message types: Broadcast, direct
- [ ] Redis Streams for persistence (7-day retention)
- [ ] Throughput: ≥1000 messages/sec
- [ ] Coordination latency: <100ms per hop
- [ ] Integration test: 10 concurrent agents

**Deliverable**: `src/agents/coordinator.js`

---

#### TASK-029: Agent Base Class [P1]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: TASK-028

**Description**:
Create abstract agent base class.

**Acceptance Criteria**:
- [ ] Abstract class `Agent`
- [ ] Methods: `handleMessage(message)`, `sendMessage(to, content)`, `getWorkbench()`
- [ ] Lifecycle hooks: `onStart()`, `onStop()`
- [ ] Documentation with examples

**Deliverable**: `src/agents/base.py`

---

#### TASK-030: Planner Agent [P1]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-029

**Description**:
Implement planner agent (Tier 3).

**Acceptance Criteria**:
- [ ] Class `PlannerAgent extends Agent`
- [ ] Receives task, generates plan with subtasks
- [ ] Assigns subtasks to appropriate agents (coder, reviewer, web)
- [ ] Emits `plan:complete` event
- [ ] Integration test: Plan generation for 10 sample tasks

**Deliverable**: `src/agents/planner.py`

---

#### TASK-031: Coder Agent [P1]
**Owner**: Backend Engineer
**Effort**: 1.5 days
**Dependencies**: TASK-029

**Description**:
Implement coder agent (Tier 1).

**Acceptance Criteria**:
- [ ] Class `CoderAgent extends Agent`
- [ ] Receives subtask, generates code
- [ ] Uses MCP filesystem for code reading/writing
- [ ] Emits `subtask:complete` event
- [ ] Integration test: Code generation for 5 tasks

**Deliverable**: `src/agents/coder.py`

---

#### TASK-032: Reviewer Agent [P1]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: TASK-029

**Description**:
Implement reviewer agent (Tier 0).

**Acceptance Criteria**:
- [ ] Class `ReviewerAgent extends Agent`
- [ ] Receives results, validates quality
- [ ] Emits `review:complete` event
- [ ] Integration test: Review 10 sample outputs

**Deliverable**: `src/agents/reviewer.py`

---

### Epic 2.3: Streaming & Early Termination

#### TASK-033: Streaming LLM Wrapper [P1]
**Owner**: Backend Engineer
**Effort**: 2 days
**Dependencies**: TASK-021

**Description**:
Implement streaming wrapper for all LLM providers.

**Acceptance Criteria**:
- [ ] Async generator: `async def streamLLM(tier, prompt)`
- [ ] Yields chunks: `{type: 'content'|'termination'|'complete', ...}`
- [ ] Early termination detection: "DONE", "Task completed", code block closures
- [ ] Token counting for streaming
- [ ] Cost calculation on completion
- [ ] Unit tests: Mock streaming responses

**Deliverable**: `src/llm/streaming.py`

---

#### TASK-034: n8n Streaming Integration [P1]
**Owner**: Frontend Engineer
**Effort**: 1.5 days
**Dependencies**: TASK-033

**Description**:
Integrate streaming into n8n workflows.

**Acceptance Criteria**:
- [ ] Custom n8n node: `LLM Streaming Node`
- [ ] SSE endpoint for real-time updates
- [ ] UI: Typewriter effect for streaming text
- [ ] Cost display: Updates in real-time
- [ ] Integration test: Stream 1000-token response

**Deliverable**: `n8n/nodes/LLMStreamingNode/`

---

## Phase 3: Advanced Features (Week 5-6)

**Objectives**: Workflow versioning, metadata filtering, provider analytics

**Duration**: 5-7 days
**Priority**: P2

---

### Epic 3.1: Workflow Versioning & A/B Testing

#### TASK-035: Workflow Version Storage [P2]
**Owner**: Backend Engineer
**Effort**: 1 day
**Dependencies**: TASK-001

**Description**:
Implement workflow version control in PostgreSQL.

**Acceptance Criteria**:
- [ ] Table `workflow_versions` populated
- [ ] API: `POST /api/workflows/{id}/versions` - Create version
- [ ] API: `GET /api/workflows/{id}/versions` - List versions
- [ ] Version diffing: Show changes between versions

**Deliverable**: `src/workflows/versioning.py`

---

#### TASK-036: A/B Testing Framework [P2]
**Owner**: Data Engineer
**Effort**: 3 days
**Dependencies**: TASK-035

**Description**:
Implement A/B testing for workflow optimization.

**Acceptance Criteria**:
- [ ] Class `ABTestRunner`
- [ ] Methods: `runTest(workflow_id, version_a, version_b, sample_size)`
- [ ] Statistical significance: p-value calculation (t-test)
- [ ] Metrics tracked: cost, latency, success_rate
- [ ] Auto-rollout: Deploy winner if p < 0.05 and improvement >5%
- [ ] Integration test: Run 100-sample A/B test

**Deliverable**: `src/workflows/ab_testing.py`

---

### Epic 3.2: Metadata Filtering

#### TASK-037: Metadata Schema Update [P2]
**Owner**: ML Engineer
**Effort**: 0.5 days
**Dependencies**: TASK-001

**Description**:
Extend Qdrant collection with metadata fields.

**Acceptance Criteria**:
- [ ] Fields: doc_type, created_at, updated_at, source, privacy_level, tags
- [ ] Indexes on filterable fields
- [ ] Migration script for existing collections
- [ ] Documentation

**Deliverable**: `migrations/002_metadata_schema.py`

---

#### TASK-038: Filtering UI [P2]
**Owner**: Frontend Engineer
**Effort**: 2 days
**Dependencies**: TASK-037

**Description**:
Build metadata filtering UI in web chat.

**Acceptance Criteria**:
- [ ] Dropdowns: doc_type, source, privacy_level
- [ ] Date range picker: created_at filter
- [ ] Tag autocomplete
- [ ] Filter preview: Show count of matching docs
- [ ] Apply filters before search

**Deliverable**: `frontend/components/FilterUI.tsx`

---

### Epic 3.3: Provider Analytics

#### TASK-039: Grafana Provider Dashboard [P2]
**Owner**: DevOps Engineer
**Effort**: 1.5 days
**Dependencies**: TASK-005

**Description**:
Create Grafana dashboard for provider analytics.

**Acceptance Criteria**:
- [ ] Panel: Latency percentiles by provider (line chart)
- [ ] Panel: Success rate by provider (bar chart)
- [ ] Panel: Cost per provider (pie chart)
- [ ] Panel: Health status (status panel)
- [ ] Refresh: 30 seconds
- [ ] Export as JSON

**Deliverable**: `grafana/dashboards/provider-analytics.json`

---

## Phase 4: Production Readiness (Week 7-8)

**Objectives**: Testing, documentation, migration, performance optimization

**Duration**: 7-10 days
**Priority**: P0-P1

---

### Epic 4.1: Testing

#### TASK-040: Unit Test Suite [P0]
**Owner**: All Engineers
**Effort**: 3 days
**Dependencies**: All implementation tasks

**Description**:
Achieve 80%+ code coverage with unit tests.

**Acceptance Criteria**:
- [ ] Coverage: ≥80% for critical paths (RAG, LLM routing, privacy)
- [ ] Test framework: pytest (Python), Jest (JavaScript)
- [ ] Mock external services: LLM APIs, databases
- [ ] CI integration: Run on every commit
- [ ] Coverage report: HTML and console output

**Deliverable**: `tests/unit/`

---

#### TASK-041: Integration Test Suite [P0]
**Owner**: QA Engineer
**Effort**: 3 days
**Dependencies**: All implementation tasks

**Description**:
End-to-end integration tests for critical workflows.

**Acceptance Criteria**:
- [ ] Test: Document ingestion → indexing → query → answer with citation
- [ ] Test: Privacy mode blocks external APIs (network capture)
- [ ] Test: Budget enforcement rejects over-limit requests
- [ ] Test: Provider failover on primary failure
- [ ] Test: Multi-agent workflow (planner → coder → reviewer)
- [ ] Test: Hybrid search accuracy (≥30% improvement)
- [ ] CI integration: Run nightly

**Deliverable**: `tests/integration/`

---

#### TASK-042: Load Testing [P1]
**Owner**: DevOps Engineer
**Effort**: 2 days
**Dependencies**: TASK-041

**Description**:
Performance and scalability testing.

**Acceptance Criteria**:
- [ ] Tool: Locust or k6
- [ ] Scenario: 1000 queries/hour for 7 days
- [ ] Metrics: Latency percentiles, error rate, resource usage
- [ ] Target: 99.9% uptime, p95 latency <5s
- [ ] Report: Performance bottlenecks and recommendations

**Deliverable**: `tests/load/locustfile.py`, `docs/load-test-report.md`

---

### Epic 4.2: Documentation

#### TASK-043: API Documentation [P0]
**Owner**: Technical Writer
**Effort**: 2 days
**Dependencies**: All API endpoints

**Description**:
Create OpenAPI 3.0 specification for all APIs.

**Acceptance Criteria**:
- [ ] OpenAPI 3.0 YAML file
- [ ] All endpoints documented: path, method, parameters, responses
- [ ] Authentication scheme documented (JWT)
- [ ] Example requests and responses
- [ ] Interactive documentation (Swagger UI or ReDoc)

**Deliverable**: `docs/api/openapi.yaml`

---

#### TASK-044: User Guide [P1]
**Owner**: Technical Writer
**Effort**: 2 days
**Dependencies**: All features implemented

**Description**:
Write comprehensive user guide.

**Acceptance Criteria**:
- [ ] Getting started: Setup, first query
- [ ] Features: Privacy mode, cost management, multi-agent
- [ ] Troubleshooting: Common errors and solutions
- [ ] FAQ: 20+ common questions
- [ ] Screenshots and diagrams
- [ ] Format: Markdown in `/docs/user-guide.md`

**Deliverable**: `docs/user-guide.md`

---

#### TASK-045: Migration Guide (v4.1 → v4.2) [P0]
**Owner**: DevOps Engineer + Technical Writer
**Effort**: 1 day
**Dependencies**: All implementation tasks

**Description**:
Create migration guide from v4.1 to v4.2.

**Acceptance Criteria**:
- [ ] Pre-migration checklist
- [ ] Database migration scripts
- [ ] Configuration changes required
- [ ] Rollback procedure
- [ ] Estimated downtime: <15 minutes
- [ ] Testing: Dry-run instructions

**Deliverable**: `docs/migration-v4.1-to-v4.2.md`

---

### Epic 4.3: Security

#### TASK-046: Security Audit [P0]
**Owner**: Security Engineer (External or Internal)
**Effort**: 3 days
**Dependencies**: All implementation tasks

**Description**:
Comprehensive security audit of v4.2.

**Acceptance Criteria**:
- [ ] Audit areas: MCP sandboxing, privacy mode, credential storage, input validation, SQL injection, XSS
- [ ] Penetration testing: Attempt path traversal, bypass privacy mode, budget manipulation
- [ ] Findings: Categorize as Critical/High/Medium/Low
- [ ] Target: Zero critical vulnerabilities
- [ ] Remediation: Fix all Critical and High findings before launch

**Deliverable**: `docs/security-audit-report.md`

---

#### TASK-047: Credential Encryption [P0]
**Owner**: Security Engineer
**Effort**: 1 day
**Dependencies**: None

**Description**:
Implement AES-256 encryption for stored credentials.

**Acceptance Criteria**:
- [ ] Encryption: AES-256-GCM
- [ ] Key management: Environment variable or secret manager
- [ ] Key rotation: 90-day policy
- [ ] Encrypted fields: API keys, database passwords
- [ ] Audit: All decryption operations logged

**Deliverable**: `src/security/encryption.py`

---

### Epic 4.4: Deployment

#### TASK-048: Docker Compose Production Config [P0]
**Owner**: DevOps Engineer
**Effort**: 1 day
**Dependencies**: All services implemented

**Description**:
Create production-ready Docker Compose configuration.

**Acceptance Criteria**:
- [ ] All services defined: n8n, Ollama, Qdrant, PostgreSQL, Redis, MCP servers, Jan, Prometheus, Grafana
- [ ] Resource limits: CPU, memory
- [ ] Health checks for all services
- [ ] Restart policies: `always` or `unless-stopped`
- [ ] Volumes: Persistent data
- [ ] Networks: Isolated where appropriate
- [ ] Environment variables: Documented in `.env.example`

**Deliverable**: `docker-compose.prod.yml`, `.env.example`

---

#### TASK-049: CI/CD Pipeline [P1]
**Owner**: DevOps Engineer
**Effort**: 2 days
**Dependencies**: TASK-040, TASK-041

**Description**:
Set up GitHub Actions CI/CD pipeline.

**Acceptance Criteria**:
- [ ] Trigger: On push to `main` or PR
- [ ] Steps: Lint, unit tests, integration tests, build Docker images
- [ ] Coverage report: Upload to Codecov
- [ ] Docker images: Push to registry on merge to `main`
- [ ] Deployment: Manual trigger for production (approval required)
- [ ] Notifications: Slack on success/failure

**Deliverable**: `.github/workflows/ci-cd.yml`

---

#### TASK-050: Blue-Green Deployment Script [P1]
**Owner**: DevOps Engineer
**Effort**: 1.5 days
**Dependencies**: TASK-048

**Description**:
Implement zero-downtime blue-green deployment.

**Acceptance Criteria**:
- [ ] Script: Deploy v4.2 alongside v4.1 (green environment)
- [ ] Health check: Verify green environment
- [ ] Traffic switch: Route to green (DNS or load balancer)
- [ ] Rollback: Script to revert to blue if issues detected
- [ ] Testing: Dry-run in staging environment
- [ ] Documentation: Step-by-step instructions

**Deliverable**: `scripts/blue-green-deploy.sh`, `docs/deployment-guide.md`

---

## Summary

### Task Count by Priority

| Priority | Count | Total Effort (days) |
|----------|-------|---------------------|
| P0 | 32 | 24-28 |
| P1 | 15 | 12-15 |
| P2 | 3 | 2-3 |
| **Total** | **50** | **38-46** |

### Task Count by Phase

| Phase | Duration | Task Count |
|-------|----------|------------|
| Phase 1 | 10-12 days | 24 |
| Phase 2 | 8-10 days | 10 |
| Phase 3 | 5-7 days | 6 |
| Phase 4 | 7-10 days | 10 |
| **Total** | **38-46 days** | **50** |

### Critical Path

```
TASK-001 (PostgreSQL) → TASK-002 (Logger) → TASK-004 (Queries) → TASK-005 (Dashboard)
                      → TASK-003 (Redis Cost Tracking)

TASK-006 (BM25) → TASK-007 (Hybrid Search) → TASK-009 (Reranking)
              → TASK-008 (Semantic Chunking)

TASK-010/011/012 (MCP Servers) → TASK-013 (MCP Client)

TASK-019 (Provider Interface) → TASK-020 (Implementations) → TASK-021 (Router)

TASK-022 (Budget Schema) → TASK-023 (Enforcer) → TASK-024 (API)

TASK-028 (Coordinator) → TASK-029 (Base) → TASK-030/031/032 (Agents)

All → TASK-040 (Unit Tests) → TASK-041 (Integration) → TASK-046 (Security Audit)
```

---

## Risk Management

### High-Risk Tasks

| Task | Risk | Mitigation |
|------|------|------------|
| TASK-007 | Hybrid search may not improve accuracy | A/B test early, rollback if fails |
| TASK-021 | Provider failover latency >2s | Load test, optimize health check caching |
| TASK-023 | Budget race conditions | Redis transactions, unit test concurrency |
| TASK-041 | Integration tests flaky | Retry logic, idempotent tests |
| TASK-046 | Critical security vulnerability found | Allocate buffer time for remediation |

---

## Team Allocation

### Recommended Team (2-3 Engineers)

| Role | Tasks | Workload |
|------|-------|----------|
| **Backend Engineer #1** | LLMOps, providers, budget, agents | 18 days |
| **Backend/ML Engineer #2** | RAG, hybrid search, chunking, reranking | 15 days |
| **DevOps Engineer** | MCP servers, deployment, CI/CD, monitoring | 12 days |
| **Frontend Engineer** (Part-time) | Dashboard, UI, streaming integration | 5 days |
| **Technical Writer** (Part-time) | Documentation, user guide, API docs | 4 days |

---

## Next Steps

1. ✅ Review and approve this task breakdown
2. ⏳ Assign owners to Phase 1 tasks
3. ⏳ Set up project tracking (GitHub Projects or Jira)
4. ⏳ Create development environment (Docker Compose)
5. ⏳ Kickoff meeting: Week 1 Day 1
6. ⏳ Begin Phase 1: TASK-001 (PostgreSQL Schema)

---

**Document Status**: ✅ Active
**Next Review**: After Phase 1 completion
**Maintainers**: Project Manager, Architecture Team
**Last Updated**: 2025-11-18
