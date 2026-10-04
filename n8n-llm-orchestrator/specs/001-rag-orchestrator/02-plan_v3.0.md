# Implementation Plan: Multi-Agent RAG Workflow Orchestrator

**Branch**: `001-rag-orchestrator` | **Version**: 3.0.0 | **Created**: 2025-10-30 | **Updated**: 2025-11-18
**Spec**: [01-spec_v3.0.md](./01-spec_v3.0.md)
**Input**: Feature specification from `/specs/001-rag-orchestrator/01-spec_v3.0.md`

---

## Version History

- **v3.0.0** (2025-11-18): LiteLLM integration, 5-tier routing, pre-budget checks, architect/executor pattern, batch routing
- **v2.1.0** (2025-11-17): Web agent capabilities, multi-tier cost orchestration
- **v2.0.0** (2025-11-15): aisuite integration, RouteLLM, observability stack
- **v1.0.0** (2025-10-30): Initial plan with basic RAG workflow

---

## Summary

Build a **production-grade cost-optimized RAG system** using n8n for visual workflow orchestration, **LiteLLM** for unified LLM interface with 5-tier routing, and Qdrant for vector storage. The system enables users to query document knowledge bases using natural language with **60-70% cost reduction** vs naive routing through intelligent model selection, pre-budget checks, and architect/executor pattern.

Core features include:
- **5-Tier intelligent routing**: Tier 0 (local fast filter $0), Tier 1 (per-token $0.20-0.80/M), Tier 2 (local multimodal VPS), Tier 3 (premium $3-15/M), Tier 4 (GPU rental $0.69-2/hour)
- **Pre-budget checks**: MANDATORY before every LLM call to prevent budget overruns
- **Architect/Executor pattern**: Tier 3 plans, Tier 0/1 executes (57% cost savings on multi-step tasks)
- **Batch size routing**: >50 requests auto-route to Tier 4 GPU rental (30-50% savings)
- **Prompt compression**: Tier 0 compresses long contexts before Tier 3 (60% token reduction)
- Document ingestion (PDF/Markdown/TXT) and web content extraction (**Firecrawl**)
- Dual retrieval: Vector search (Qdrant) + Vectorless RAG (**PageIndex MCP**)
- Multi-agent orchestration with ReAct patterns
- LLM provider abstraction via **LiteLLM** (Ollama, Claude, Gemini, GPT-4, Fireworks, Together.ai, RunPod, Salad, CloudRift)
- Comprehensive observability: **OpenTelemetry**, **LangSmith**/**Langfuse**, **MCPcat**, **Helicone**

**Technical Approach**: Visual-first architecture using n8n workflows as the orchestration layer, eliminating custom code where possible. All LLM calls routed through **LiteLLM** unified OpenAI-compatible interface with **mandatory pre-budget checks**. n8n workflows interact with HTTP APIs: LiteLLM, RouteLLM, Firecrawl, PageIndex MCP, Qdrant. State passed explicitly between nodes via JSON. Full distributed tracing with OpenTelemetry. Real-time cost tracking via Helicone proxy. Budget pool management with auto-shutdown of idle Tier 4 instances.

---

## Technical Context

**Primary Platform**: n8n v1.x (self-hosted via Docker)

**LLM Interface Layer**:
- **LiteLLM** (unified LLM API wrapper) - OpenAI-compatible HTTP service (replaces aisuite from v2.0)
- **RouteLLM** (intelligent routing) - Analyzes query complexity and routes to optimal tier
- **Helicone** (cost proxy) - Caching, logging, real-time cost tracking

**LLM Providers** (via LiteLLM 5-Tier System):
- **Tier 0 (Fast Filter)**: Ollama 3B-13B (local) - Intent detection, classification, prompt compression - <500ms, $0
- **Tier 1 (Hosted Open Source)**: Fireworks.ai, Together.ai - Standard text generation, API responses - $0.20-0.80/M tokens
- **Tier 2 (Local Multimodal)**: Ollama 70B+Vision (local) - Image analysis, screenshot understanding - VPS fixed cost ~$75/month
- **Tier 3 (Premium APIs)**: Claude 3.5 Sonnet, Gemini 1.5 Pro - Complex reasoning, architecture planning - $3-15/M tokens
- **Tier 4 (GPU Rental)**: RunPod, Salad, CloudRift - Batch processing (>50 requests), sustained high-volume - $0.69-2/hour
- **Embeddings**: nomic-embed-text via Ollama (768 dimensions)

**Data & Retrieval**:
- **Vector Database**: Qdrant v1.7+ (self-hosted via Docker)
- **Vectorless RAG**: PageIndex MCP (documentation, cost-optimized)
- **Web Extraction**: Firecrawl (LLM-friendly markdown output)

**Observability Stack**:
- **Distributed Tracing**: OpenTelemetry + Jaeger/Zipkin
- **LLM Monitoring**: LangSmith (preferred) or Langfuse (opensource)
- **Agent Metrics**: MCPcat (tool call tracking)
- **Cost Dashboard**: Helicone (real-time token usage, cache hit rate)

**Storage**:
- Vector embeddings: Qdrant (persistent volume)
- Workflow state: n8n SQLite database (default)
- Traces: OpenTelemetry Collector → Jaeger
- Execution logs: n8n internal storage (30-day retention)
- Metrics: LangSmith/Langfuse (90-day aggregated data)
- Budget state: Redis or n8n workflow variables (real-time pool balances)

**Testing Approach**:
- Manual testing via n8n test mode (trigger workflows with sample data)
- Integration tests: Document ingestion + query end-to-end with cost validation
- Evaluation dataset: 50 question-answer pairs with ground truth + tier selection validation
- Metrics tracking: LangSmith dashboards, Helicone cost reports, OpenTelemetry traces
- Cost validation: Budget pool balances, tier distribution, savings vs baseline

**Target Platform**: Linux server (Docker containers on Ubuntu 22.04+)
**Project Type**: Workflow orchestration (n8n workflows + configuration)

**Performance Goals**:
- Query response time: < 5 seconds (p90), including pre-budget check overhead <100ms
- Tier 0 fast filter: < 500ms for classification/intent detection
- Document ingestion: > 10 docs/minute (batch routing for >50 docs)
- Concurrent workflows: 5+ simultaneous executions
- Vector search: < 500ms for top-5 retrieval
- Tier 4 cold start: < 3 minutes (fallback to Tier 1 during startup)

**Constraints**:
- Context window: 8K tokens (llama3.1:8b Tier 0), 128K (Claude Tier 3), 200K (Claude Opus)
- Embedding dimensions: 768 (nomic-embed-text), fixed architecture
- Memory: **32GB RAM minimum** (INCREASED from 24GB in v2.0):
  - 12GB Ollama (Tier 0: 3GB, Tier 2: 9GB for 70B+Vision)
  - 4GB Qdrant
  - 2GB n8n
  - 3GB LiteLLM (handles multiple provider connections)
  - 2GB Helicone
  - 2GB OpenTelemetry + Jaeger
  - 2GB LangSmith/Langfuse
  - 1GB MCPcat
  - 4GB headroom
- VPS Requirements for Tier 2: 48GB RAM, RTX 4090 or equivalent GPU
- Network: Local network latency < 10ms between containers
- Observability overhead: ~5-10% latency increase from tracing instrumentation
- API costs: Budget **$30/month** (REDUCED from $50 in v2.0) for cloud LLM usage via 5-tier routing
  - Hourly VRAM pool: $100/month (RunPod/Salad/CloudRift - auto-shutdown after 30 min idle)
  - Per-Token pool: $50/month (Fireworks/Together.ai)
  - Premium pool: $30/month (Claude/Gemini)
  - Local VPS: $75/month (fixed infrastructure for Tier 0/2)

**Scale/Scope**:
- Knowledge base: Up to 100,000 document chunks (800 chars each)
- Query volume: 10,000 queries/month (expected tier distribution: 40% Tier 0, 30% Tier 1, 5% Tier 2, 20% Tier 3, 5% Tier 4)
- Document collection: 1,000-5,000 documents
- User base: Single-tenant (no multi-tenancy in MVP)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Visual-First Design ✅

- **Requirement**: All agentic workflows MUST be representable in n8n's visual interface
- **Status**: PASS
- **Evidence**: All agent logic including pre-budget checks, tier routing, and architect/executor pattern implemented as n8n workflows with HTTP Request, Code, IF, and Loop nodes. No external Python/Node.js scripts required for core functionality.
- **Implementation**:
  - Document ingestion: n8n workflow (Read Files → Batch Size Detection → Route to Tier 1/4 → Split Text → Generate Embeddings → Insert to Qdrant)
  - Query workflow: n8n workflow (Webhook → Pre-Budget Check → Tier 0 Fast Filter → Complexity Analysis → Route to Tier → Embed Query → Search Qdrant → Augment Prompt → Call LLM → Update Budget → Response)
  - Multi-agent: n8n conditional branches and loops with architect/executor pattern (Architect Tier 3 → Executor Tier 0/1 → Reviewer Tier 3)
  - Budget monitoring: n8n scheduled workflow checks pool balances, sends alerts, auto-shutdowns idle Tier 4 instances

### II. LLM-Agnostic & Modality-Aware Architecture ✅

- **Requirement**: Support multiple LLM providers interchangeably with modality awareness
- **Status**: PASS
- **Evidence**: Provider configuration per workflow via n8n variables and LiteLLM model groups. Fallback chain implemented using n8n IF nodes + error branches. Modality detection routes vision tasks to Tier 2 (Ollama Vision) or Tier 3 (Claude 3.5/GPT-4V).
- **Implementation**:
  - Primary: HTTP Request node → LiteLLM API (http://litellm:4000/v1/chat/completions) with model group aliases
  - Model groups: `fast_filter` (Tier 0), `executor` (Tier 1), `vision` (Tier 2), `architect` (Tier 3), `batch_gpu` (Tier 4)
  - Fallback chain: Tier 0 → Tier 1 → Tier 2 → Tier 3 (with pre-budget check at each tier)
  - Provider switch: Change single variable in workflow settings or LiteLLM config
  - Modality detection: n8n Code node checks for image inputs → routes to `vision` model group

### III. Fail-Safe Operations (NON-NEGOTIABLE) ✅

- **Requirement**: Error handling, retries, graceful degradation
- **Status**: PASS
- **Evidence**: n8n native retry logic configured on all HTTP nodes. Error branches catch failures and return user-friendly messages. Pre-budget checks prevent budget exhaustion failures. Tier fallback handles provider failures.
- **Implementation**:
  - Retry config: 3 attempts, exponential backoff (1s, 2s, 4s)
  - Timeout: 30 seconds per LLM call (Tier 3/4), 5 seconds per Tier 0 call
  - Error branches: IF node checks for error, routes to fallback tier or error response
  - Circuit breaker: n8n execution tracking, disable workflow after 10 consecutive failures
  - Pre-budget check: Blocks LLM call before sending if insufficient budget, returns "budget exhausted" error
  - Tier 4 cold start timeout: 3 minutes, fallback to Tier 1 during startup

### IV. Cost-Conscious Design ✅ (v3.0 ENHANCED)

- **Requirement**: Monitor token usage, cache responses, optimize prompts, **implement pre-budget checks**
- **Status**: PASS
- **Evidence**: **Mandatory pre-budget checks before all LLM calls**. Real-time budget pool tracking. Token tracking via n8n Code node parsing LLM responses. Query caching via Helicone with 1-hour TTL. Intelligent tier routing. Prompt compression for long contexts. Batch size detection. Architect/executor pattern. Auto-shutdown of idle Tier 4 instances.
- **Implementation**:
  - **Pre-budget check**: n8n Code node BEFORE every LLM call validates budget pool balance ≥ estimated cost, blocks if insufficient
  - Token tracking: Parse `usage` field from LLM API responses, log to n8n execution data + update budget pool
  - Caching: Helicone proxy caches identical queries for 1 hour (20%+ cache hit rate)
  - Cost monitoring: Real-time budget pool balances tracked in n8n workflow variables or Redis
  - Tier routing: RouteLLM complexity analysis → route to Tier 0 (40% queries $0), Tier 1 (30% queries low cost), Tier 3 (20% queries high quality)
  - Prompt compression: Tier 0 compresses >10k token prompts before sending to Tier 3 (60% token reduction)
  - Batch routing: n8n Code node detects batch size ≥50 → route to Tier 4 GPU rental (30-50% savings)
  - Architect/Executor: Multi-step tasks use Tier 3 planning + Tier 0/1 execution (57% savings vs all-Tier-3)
  - Budget alerts: n8n scheduled workflow checks pool balances, sends alert at 90% capacity
  - Auto-shutdown: n8n scheduled workflow checks Tier 4 instance idle time >30 min → shutdown API call

### V. Observable Agent Flows ✅ (v3.0 ENHANCED)

- **Requirement**: Structured logging, prompt/response capture, metrics tracking, **cost analytics**
- **Status**: PASS
- **Evidence**: n8n execution logs retain all node inputs/outputs for 30 days including tier selection, cost, budget impacts. Custom logging workflow aggregates metrics. LangSmith/Langfuse captures all prompts/responses. OpenTelemetry distributed tracing. MCPcat tracks tool calls. Helicone provides cost dashboard.
- **Implementation**:
  - Execution logs: n8n default (all node I/O captured automatically) + custom fields for tier, cost, budget remaining
  - LLM prompts: Logged as node input in execution data + captured by LangSmith/Langfuse
  - RAG retrieval: Qdrant response logged with relevance scores + PageIndex if used
  - Distributed tracing: OpenTelemetry spans capture full request path (n8n → LiteLLM → Helicone → Provider)
  - Cost analytics: Helicone dashboard shows cost per tier, cache hit rate, token usage over time
  - Budget tracking: n8n workflow variable or Redis stores real-time pool balances, burn rate, alert status
  - Metrics workflow: Scheduled daily aggregation of execution data → CSV export with tier distribution, cost breakdown, savings vs baseline
  - Pre-budget check logs: Every check result logged (pass/fail, pool, balance, estimated cost, routing decision)

### VI. Intelligent Routing ✅ (v3.0 ENHANCED: 5-Tier System)

- **Requirement**: Query complexity MUST determine model selection automatically
- **Status**: PASS
- **Evidence**: **RouteLLM analyzes queries and routes to 5 tiers** based on complexity, modality, batch size. Routing decisions logged and auditable. Manual override available per workflow via configuration.
- **Implementation**:
  - **Tier 0 (Fast Filter)**: <500 chars, factual lookup, classification → Ollama 3B-13B → <500ms, $0
  - **Tier 1 (Hosted Open Source)**: Standard text gen, API responses → Fireworks/Together → $0.20-0.80/M tokens
  - **Tier 2 (Local Multimodal)**: Image analysis, screenshots → Ollama 70B+Vision → VPS fixed cost
  - **Tier 3 (Premium)**: Complex reasoning, architecture planning → Claude/Gemini → $3-15/M tokens
  - **Tier 4 (GPU Rental)**: Batch processing ≥50 requests → RunPod/Salad → $0.69-2/hour
  - RouteLLM integration: n8n HTTP Request node calls RouteLLM API → receives complexity score → n8n Code node maps to tier
  - Routing log: All decisions logged with query ID, complexity score, tier selected, routing reason, cost projection
  - Manual override: n8n workflow parameter `force_tier: 0-4` bypasses RouteLLM

### VII. Tool Integration Standards ✅

- **Requirement**: External tools and data sources MUST follow MCP patterns
- **Status**: PASS
- **Evidence**: Firecrawl for web scraping, PageIndex MCP for vectorless RAG, all exposed via HTTP APIs callable from n8n. Tool failures handled gracefully with fallbacks.
- **Implementation**:
  - **Web scraping**: Firecrawl API (http://firecrawl:8080/scrape) returns LLM-friendly markdown
  - **Vectorless RAG**: PageIndex MCP server (http://pageindex-mcp:3000/search) for documentation queries
  - **App integrations**: Future - Composio or Rube for standardized API access
  - **Authentication**: Future - AgentAuth for OAuth flows
  - Tool failures: n8n error branches catch failures → fallback to degraded functionality (e.g., Firecrawl fails → simple HTTP fetch)

### VIII. Cost-Optimized Provider Selection ✅ (v3.0 NEW)

- **Requirement**: Provider orchestration MUST consider both model capability AND pricing model economics
- **Status**: PASS
- **Evidence**: System implements 5-tier pricing model routing with workload volume detection, batch size analysis, and dynamic tier selection. Budget pools managed separately for hourly VRAM, per-token, premium, and local VPS. Auto-shutdown of idle instances.
- **Implementation**:
  - **Local (Free)**: Tier 0/2 Ollama → $0 per query, VPS fixed $75/month
  - **Hourly VRAM**: Tier 4 RunPod/Salad → $0.69-2/hour, use when batch size ≥50 or sustained load
  - **Per-Token**: Tier 1 Fireworks/Together → $0.20-0.80/M tokens, use for bursty traffic <50 requests
  - **Premium APIs**: Tier 3 Claude/Gemini → $3-15/M tokens, reserve for complex reasoning only
  - Batch detection: n8n Code node counts pending requests → if ≥50, spin up Tier 4 GPU instance
  - Cost comparison: n8n Code node calculates Tier 4 hourly cost vs Tier 1 per-token cost → logs decision
  - Instance lifecycle: Tier 4 instance spins up (1-3 min cold start) → kept warm while queries queued → auto-shutdown after 30 min idle
  - Budget pools: n8n workflow variables or Redis tracks 4 separate pools (hourly $100, per-token $50, premium $30, VPS $75)
  - Alerts: n8n scheduled workflow checks pool balances → alert at 90% → force routing to lower tiers

### IX. Architect/Executor Pattern ✅ (v3.0 NEW)

- **Requirement**: Multi-step tasks MUST use tiered agent roles for cost optimization
- **Status**: PASS
- **Evidence**: Coder Agent workflow implements architect/executor pattern where Tier 3 (Claude) plans tasks, Tier 0/1 (Ollama/Fireworks) executes subtasks, Tier 3 reviews results. Achieves 50%+ cost savings vs all-Tier-3 execution.
- **Implementation**:
  - **Architect Role**: n8n HTTP Request node calls LiteLLM with `model: architect` (Tier 3 Claude) → receives detailed plan with subtasks
  - **Executor Role**: n8n Loop node iterates subtasks → each subtask routed to Tier 0/1 based on complexity → executes implementation
  - **Reviewer Role**: n8n HTTP Request node calls LiteLLM with `model: architect` (Tier 3 Claude) → validates results, provides feedback
  - Cost tracking: n8n Code node logs cost per role (architect $0.15, executor $0.35, reviewer $0.15 = $0.65 total vs $1.50 all-Tier-3)
  - Savings calculation: n8n execution data tracks savings vs baseline, logged to cost dashboard

### Architecture Constraints Check ✅

**Vector Database Standards**:
- ✅ Qdrant self-hosted via Docker: `docker run -p 6333:6333 qdrant/qdrant`
- ✅ Embedding model: nomic-embed-text (768 dimensions)
- ✅ Metadata schema: {source, timestamp, chunk_id, page_number}
- ✅ Backup: n8n scheduled workflow calls Qdrant snapshot API daily

**Document Processing Rules**:
- ✅ Chunk size: 800 characters (configurable via n8n variable)
- ✅ Chunk overlap: 200 characters
- ✅ Top-k retrieval: 3-5 chunks (n8n Code node filters by score)
- ✅ Re-ranking: Optional Code node with keyword overlap scoring

**State Management**:
- ✅ Explicit state passing: JSON objects between n8n nodes (including tier, cost, budget remaining)
- ✅ No hidden globals: All state in workflow execution context
- ✅ Persistence: Long-running workflows save intermediate state to n8n database
- ✅ Budget state: Real-time pool balances in n8n workflow variables or Redis

**LLM Interface & Routing Layer** (v3.0 UPDATED):
- ✅ **Unified API**: All LLM calls routed through **LiteLLM** HTTP wrapper service (OpenAI-compatible)
- ✅ **Intelligent Routing**: **RouteLLM** determines optimal tier based on query complexity
- ✅ **Cost Orchestration**: **Pre-budget check** validates pool balance before LLM call
- ✅ **Cost Proxy**: **Helicone** sits between LiteLLM and providers for caching/logging
- ✅ **Request Flow**: n8n → Pre-Budget Check → RouteLLM (complexity) → LiteLLM (tier selection) → Helicone (cache/log) → Provider
- ✅ **Configuration**: Model preferences, routing thresholds, fallback chains in LiteLLM config + n8n workflow variables
- ✅ **Override**: Manual tier selection available via workflow parameters

### Quality Standards Check ✅

**Testing Requirements**:
- ✅ Evaluation dataset: 50 Q&A pairs stored in n8n workflow test data + tier selection validation
- ✅ Metrics: recall@k (Qdrant logs), answer relevance (manual review), latency (n8n execution time), cost per query
- ✅ Integration tests: End-to-end workflow execution via n8n test mode with cost validation
- ✅ Manual protocol: Documented in quickstart.md
- ✅ **Cost validation**: Test budget exhaustion scenario, verify pre-check blocks calls, validate tier routing decisions

**Performance Benchmarks**:
- ✅ Response time < 5s: Monitored via n8n execution duration (including <100ms pre-budget check overhead)
- ✅ Tier 0 fast filter < 500ms: Monitored via n8n node execution time
- ✅ Ingestion > 10 docs/min: Timed via n8n loop node iterations (batch routing for >50 docs)
- ✅ Concurrent support: n8n queue mode with 5 worker threads
- ✅ Timeout: 30s configured on HTTP Request nodes (Tier 3/4), 5s for Tier 0
- ✅ Tier 4 cold start < 3 min: Monitored via n8n execution logs, fallback to Tier 1 during startup

**Security**:
- ✅ API keys: Stored in n8n Credentials (encrypted at rest)
- ✅ Network isolation: Docker network, no external access to Qdrant
- ✅ Input sanitization: n8n Code node validates/escapes user input
- ✅ No PII in logs: n8n log filter removes sensitive fields
- ✅ Budget protection: Pre-budget checks prevent unauthorized charges

**Result**: All constitution checks PASS. No violations requiring justification.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-rag-orchestrator/
   0.constitution_v3.0.md   # Constitution with 5-tier routing, pre-budget checks
   01-spec_v3.0.md          # Feature specification with v3.0 requirements
   02-plan_v3.0.md          # This file (v3.0 implementation plan)
   03-research_v3.0.md      # Phase 0: Technology decisions (v3.0 research topics)
   04-tasks_v3.0.md         # Phase 2: Implementation tasks (v3.0 task breakdown)
   data-model.md            # Phase 1: Entity schemas and state definitions
   quickstart.md            # Phase 1: Setup and testing guide
   contracts/               # Phase 1: n8n workflow schemas (JSON exports)
      ingestion-workflow.json
      query-workflow.json
      architect-executor-workflow.json
      budget-monitoring-workflow.json
      tier-routing-workflow.json
   checklists/              # Already exists from /speckit.specify
      requirements.md
```

### n8n Workflows (project root)

```text
n8n-llm-orchestrator/
   workflows/                           # n8n workflow exports (JSON)
      001-document-ingestion.json       # With batch size detection
      002-query-processing.json         # With pre-budget check + tier routing
      003-architect-executor.json       # NEW: Coder agent with tier optimization
      004-provider-fallback.json        # Updated: Tier-based fallback
      005-metrics-aggregation.json      # Updated: Cost analytics per tier
      006-budget-monitoring.json        # NEW: Budget pool monitoring + alerts
      007-tier-routing.json             # NEW: RouteLLM integration + tier selection
      008-prompt-compression.json       # NEW: Tier 0 prompt optimization
   configs/                             # Configuration files
      litellm-config.yaml               # NEW: LiteLLM model groups, provider credentials
      routellm-config.yaml              # NEW: Routing thresholds, tier definitions
      helicone-config.yaml              # NEW: Cache TTL, logging settings
      qdrant-collection-config.json
      embedding-models.json
      budget-pools.json                 # NEW: Monthly budget limits per pool
      otel-collector-config.yaml        # NEW: OpenTelemetry trace exporters
      langsmith-config.yaml             # NEW: LLM monitoring project settings
   scripts/                             # Helper scripts (minimal)
      setup-qdrant-collection.sh
      setup-litellm-service.sh          # NEW: LiteLLM deployment
      setup-budget-pools.sh             # NEW: Initialize budget tracking
      import-workflows.sh
   test-data/                           # Test datasets
      sample-documents/                 # PDFs, Markdown, TXT
      evaluation-set.json               # 50 Q&A pairs with tier validation
      cost-baseline.json                # NEW: Naive routing cost for comparison
   .env.example                         # Environment variables template
   docker-compose.yml                   # n8n + Ollama + Qdrant + LiteLLM + observability stack
   README.md                            # Project overview and setup
```

**Structure Decision**:

This is a **workflow orchestration project with cost optimization**, not a traditional application. The primary deliverable is n8n workflow configurations (JSON files) that define the agent logic with intelligent tier routing, not source code. The structure reflects this:

- **`workflows/`**: Core implementation (8 n8n workflows exported as JSON) including new v3.0 workflows for budget monitoring, tier routing, architect/executor pattern
- **`configs/`**: Supporting configurations for LiteLLM, RouteLLM, Helicone, Qdrant, budget pools, observability
- **`scripts/`**: Minimal shell scripts for initial setup only (<50 lines each) including LiteLLM deployment
- **`test-data/`**: Sample documents, evaluation datasets, cost baselines for validation

**Rationale**:
- Follows "Visual-First Design" principle - workflows are the source of truth
- Minimal custom code - only setup scripts, no runtime logic outside n8n
- Version controlled: n8n JSON exports + config files committed to Git
- Testable: Workflows imported to n8n and tested via GUI with cost validation
- Observable: All workflows instrumented with OpenTelemetry, LangSmith, Helicone

---

## Complexity Tracking

> No violations of constitution principles. This section is empty.

---

## Phase 0: Research & Technology Decisions

**Goal**: Resolve all technical unknowns and document decisions for v3.0 architecture.

### Research Tasks (v3.0 Updated)

#### Core RAG Pipeline (from v1.0)

1. **n8n Node Selection for RAG Pipeline**
   - **Question**: Which n8n nodes handle PDF extraction, text splitting, and embedding generation?
   - **Research**: n8n documentation for LangChain nodes, Code nodes, HTTP Request nodes
   - **Decision TBD**: Document in research.md

2. **Ollama API Endpoints for RAG**
   - **Question**: API endpoints for embeddings vs generation, request/response formats
   - **Research**: Ollama API docs (https://github.com/ollama/ollama/blob/main/docs/api.md)
   - **Decision TBD**: Document exact curl commands and n8n HTTP Request configs for Tier 0 (3B-13B) and Tier 2 (70B+Vision)

3. **Qdrant Collection Setup**
   - **Question**: Collection creation, index configuration, metadata schema
   - **Research**: Qdrant docs for REST API, distance metrics (Cosine vs Dot Product)
   - **Decision TBD**: Optimal index settings for 100K vectors

#### LiteLLM Integration (v3.0 NEW)

4. **LiteLLM Setup & Configuration**
   - **Question**: How to deploy LiteLLM as HTTP service accessible to n8n? How to configure model groups for 5-tier system?
   - **Research**: LiteLLM docs (https://litellm.vercel.app/docs), Docker deployment, OpenAI-compatible API format, model group aliasing
   - **Decision TBD**: Port selection (4000), authentication method (API key), model group definitions (`fast_filter`, `executor`, `vision`, `architect`, `batch_gpu`), provider credentials, fallback chains

5. **LiteLLM Model Groups and Tier Mapping**
   - **Question**: How to map model groups to tiers? How to configure provider fallback per tier?
   - **Research**: LiteLLM config YAML schema, model aliasing, router configuration
   - **Decision TBD**: Model group → Tier mapping, fallback chain per tier, cost tracking metadata

#### 5-Tier Routing System (v3.0 NEW)

6. **RouteLLM Integration with 5 Tiers**
   - **Question**: How to integrate RouteLLM with LiteLLM for pre-call routing? How to map complexity scores to 5 tiers?
   - **Research**: RouteLLM API (https://github.com/lm-sys/RouteLLM), complexity scoring algorithm, tier threshold configuration
   - **Decision TBD**: Routing thresholds (complexity score ranges for Tier 0-4), override mechanism, n8n integration pattern

7. **Tier 0 Fast Filter Implementation**
   - **Question**: Which Ollama models for Tier 0? How to achieve <500ms latency? What tasks to route to Tier 0?
   - **Research**: Ollama model performance benchmarks (3B-13B models), quantization options, caching strategies
   - **Decision TBD**: Tier 0 model selection (Ollama 3B vs 7B vs 13B), quantization level, task classification rules

8. **Tier 4 GPU Rental Provider Selection**
   - **Question**: Which provider to use (RunPod, Salad, CloudRift)? API for instance lifecycle management?
   - **Research**: Provider pricing comparison, cold start times, API documentation for spin-up/shutdown
   - **Decision TBD**: Primary Tier 4 provider, API integration pattern, instance type selection, cold start handling

#### Pre-Budget Checks (v3.0 NEW)

9. **Pre-Budget Check Mechanism**
   - **Question**: How to implement blocking pre-budget check in n8n? Where to store budget pool balances?
   - **Research**: n8n workflow variables, Redis integration, real-time state management
   - **Decision TBD**: Budget state storage (n8n variables vs Redis), pre-check n8n Code node implementation, cost estimation algorithm

10. **Budget Pool Management**
    - **Question**: How to track 4 separate budget pools (hourly VRAM, per-token, premium, VPS)? How to reset monthly?
    - **Research**: n8n scheduled workflows, budget tracking patterns, alert mechanisms
    - **Decision TBD**: Budget storage schema, reset automation, alert thresholds, pool reallocation rules (if any)

#### Cost Optimization Patterns (v3.0 NEW)

11. **Batch Size Detection and Routing**
    - **Question**: How to detect batch size in real-time? How to calculate Tier 4 vs Tier 1 cost comparison?
    - **Research**: n8n queue inspection, batch processing patterns, cost calculation formulas
    - **Decision TBD**: Batch size threshold (50 requests?), cost comparison algorithm, queue management

12. **Prompt Compression with Tier 0**
    - **Question**: How to compress long prompts using Tier 0 Ollama? What compression techniques?
    - **Research**: Extractive summarization techniques, Ollama prompt patterns, context preservation methods
    - **Decision TBD**: Compression algorithm (extractive vs abstractive), token reduction target (60%?), quality validation method

13. **Architect/Executor Pattern Implementation**
    - **Question**: How to structure n8n workflow for architect/executor pattern? How to track cost savings?
    - **Research**: Multi-agent orchestration patterns, task decomposition strategies, cost tracking across agent roles
    - **Decision TBD**: Workflow structure, task decomposition format, cost attribution per role

#### Observability & Monitoring (v2.0 + v3.0 Enhanced)

14. **Helicone Proxy Setup**
    - **Question**: How to configure Helicone between LiteLLM and providers? How to track cost per tier?
    - **Research**: Helicone docs, proxy configuration, cache TTL settings, custom metadata for tier tracking
    - **Decision TBD**: Caching strategy (1-hour TTL?), logging verbosity, tier metadata format

15. **OpenTelemetry Instrumentation**
    - **Question**: How to instrument n8n, LiteLLM, and RouteLLM for distributed tracing?
    - **Research**: OpenTelemetry SDKs, trace propagation patterns, Jaeger vs Zipkin for trace backend
    - **Decision TBD**: Trace backend selection, sampling rate, span attributes (tier, cost, model)

16. **LangSmith vs Langfuse**
    - **Question**: Which LLM monitoring tool to use (paid vs opensource)?
    - **Research**: Feature comparison, cost, LiteLLM integration ease, cost analytics capabilities
    - **Decision TBD**: Primary monitoring platform, cost dashboard configuration

17. **Cost Analytics Dashboard**
    - **Question**: How to visualize cost per tier, budget pool status, savings vs baseline?
    - **Research**: Helicone dashboard customization, LangSmith cost analytics, custom n8n metrics workflows
    - **Decision TBD**: Dashboard tool selection, metrics to track, visualization format

#### Workflow Development (from v1.0)

18. **n8n Workflow Export/Import**
    - **Question**: Best practices for version controlling workflows with v3.0 complexity, testing workflows in isolation
    - **Research**: n8n CLI tools, workflow export formats, CI/CD integration
    - **Decision TBD**: Workflow development process, version control strategy

19. **Error Handling Patterns for Budget Failures**
    - **Question**: How to handle budget exhaustion gracefully? How to communicate to user?
    - **Research**: n8n error workflows, budget failure UX patterns, tier downgrade strategies
    - **Decision TBD**: Error handling template for budget exhaustion, user messaging, retry logic

**Output**: `03-research_v3.0.md` with decisions, rationale, and alternatives for all 19 topics.

---

## Phase 1: Design & Contracts

**Prerequisites**: `03-research_v3.0.md` complete with all decisions documented

### 1. Data Model (`data-model.md`)

Define entities and their attributes based on v3.0 spec requirements:

**Entities from Spec** (v3.0 Enhanced):

1. **Document**: {id, filename, file_type, upload_timestamp, size_bytes, processing_status, chunk_count, batch_job_id}
2. **Chunk**: {id, document_id, text_content, chunk_index, page_number, embedding_vector[], metadata{}}
3. **Query**: {id, query_text, timestamp, embedding_vector[], execution_id, user_id, complexity_score, **tier_selected (0-4), estimated_cost, actual_cost**}
4. **RetrievalResult**: {query_id, chunk_id, relevance_score, rank_position, source_document, source_type (Qdrant/PageIndex)}
5. **WorkflowExecution**: {execution_id, workflow_name, start_time, end_time, status, error_message, token_usage, **total_cost, cost_per_tier, budget_impact**}
6. **LLMResponse**: {execution_id, answer_text, source_citations[], provider, token_count, latency_ms, **tier_used (0-4), cost**, cache_hit}
7. **RoutingDecision**: {query_id, complexity_score, **tier_selected (0-4)**, routing_reason, manual_override, **pre_budget_check_result**}
8. **BudgetCheck** (NEW v3.0): {check_timestamp, query_id, tier_requested, estimated_cost, budget_pool, current_balance, result (pass/fail), blocking_reason}
9. **BatchJob** (NEW v3.0): {job_id, batch_size, tier_selected (4 if ≥50 else 1), start_time, end_time, total_cost, cost_comparison (Tier 4 vs Tier 1), instance_uptime}
10. **BudgetPool** (NEW v3.0): {pool_name (hourly_vram/per_token/premium/local_vps), monthly_limit ($100/$50/$30/$75), current_balance, burn_rate ($/day), alert_threshold (90%), last_reset_date}
11. **AgentTask** (NEW v3.0): {task_id, role (architect/executor/reviewer), tier_used, prompt_tokens, completion_tokens, cost, parent_task_id, savings_vs_baseline}
12. **PromptCompression** (NEW v3.0): {original_prompt, compressed_prompt, original_token_count, compressed_token_count, compression_ratio (%), tier_0_cost, tier_3_savings}

**State Transitions** (v3.0 Enhanced):
- Document: UPLOADED → BATCH_SIZE_DETECTED → TIER_SELECTED → PROCESSING → INDEXED | FAILED
- Query: RECEIVED → PRE_BUDGET_CHECK → (BLOCKED | TIER_ROUTED) → EMBEDDED → SEARCHING → GENERATING → BUDGET_UPDATED → COMPLETED | FAILED
- BudgetPool: INITIALIZED → ACTIVE → WARN_90% → EXHAUSTED → RESET (monthly)
- Tier4Instance: SPINNING_UP (1-3 min) → ACTIVE → IDLE (30 min timer) → SHUTDOWN

**Validation Rules** (v3.0 Enhanced):
- Document: filename unique per upload_timestamp
- Chunk: embedding_vector must be 768-dimensional array
- Query: query_text min 3 chars, max 500 chars, **tier_selected must be 0-4**
- RetrievalResult: relevance_score 0.0-1.0 range
- **BudgetCheck: estimated_cost must be ≤ current_balance for pass**
- **BudgetPool: current_balance must be ≥ 0 (never negative)**
- **AgentTask: cost must match tier pricing (Tier 0 = $0, Tier 1 ≥ $0.20/M, Tier 3 ≥ $3/M)**

**Output**: `data-model.md` with complete entity definitions including v3.0 entities

### 2. API Contracts (`contracts/`)

Generate n8n workflow schemas (exported JSON) for each workflow including v3.0 new workflows:

**Workflow 1: Document Ingestion** (`001-document-ingestion.json`) - v3.0 UPDATED
- **Trigger**: Manual or Scheduled (folder watch)
- **Input**: Folder path with documents
- **Nodes**: Read Files → **Batch Size Detection** → **(IF ≥50 → Tier 4, ELSE → Tier 1)** → Extract Text → Split Chunks → Generate Embeddings → Insert Qdrant
- **Output**: {documents_processed, chunks_created, status, **tier_used, batch_cost, cost_comparison**}

**Workflow 2: Query Processing** (`002-query-processing.json`) - v3.0 UPDATED
- **Trigger**: Webhook (POST /query)
- **Input**: {query: string}
- **Nodes**: Validate → **Pre-Budget Check** → **Tier 0 Fast Filter** → **Complexity Analysis (RouteLLM)** → **Route to Tier** → Embed Query → Search Qdrant → **Prompt Compression (if >10k tokens)** → Augment Prompt → Call LLM (via LiteLLM) → **Update Budget** → Format Response
- **Output**: {answer: string, sources: [{doc, score}], latency_ms: number, **tier_used: 0-4, cost: number, budget_remaining: number, routing_reason: string**}

**Workflow 3: Architect/Executor Orchestration** (`003-architect-executor.json`) - v3.0 NEW
- **Trigger**: Webhook (POST /coder-task)
- **Input**: {task_description: string, max_iterations: number}
- **Nodes**: **Architect Agent (Tier 3 Claude)** → Parse Plan → Loop Subtasks → **Route Subtask to Tier** → **Executor Agent (Tier 0/1)** → Aggregate Results → **Reviewer Agent (Tier 3 Claude)** → **Cost Summary**
- **Output**: {answer: string, iterations: number, subtasks: [{task, tier, cost}], **total_cost: number, cost_breakdown: {architect, executor, reviewer}, savings_vs_baseline: number**}

**Workflow 4: Provider Fallback** (`004-provider-fallback.json`) - v3.0 UPDATED
- **Trigger**: Called by other workflows
- **Input**: {prompt: string, tier_preference: 0-4, budget_pool: string}
- **Nodes**: **Pre-Budget Check** → Try Tier 0 (Ollama) → Error Branch → **Pre-Budget Check** → Try Tier 1 (Fireworks) → Error Branch → **Pre-Budget Check** → Try Tier 2 (Ollama Vision) → Error Branch → **Pre-Budget Check** → Try Tier 3 (Claude) → Error Response
- **Output**: {response: string, tier_used: 0-4, fallback_count: number, **cost: number, budget_remaining: number**}

**Workflow 5: Metrics Aggregation** (`005-metrics-aggregation.json`) - v3.0 UPDATED
- **Trigger**: Scheduled (daily at 2 AM)
- **Input**: None (reads n8n execution logs)
- **Nodes**: Fetch Executions → Aggregate Metrics → **Calculate Cost Per Tier** → **Calculate Savings vs Baseline** → Export CSV
- **Output**: {total_queries, avg_latency, token_usage, error_rate, **cost_per_tier: {tier_0, tier_1, tier_2, tier_3, tier_4}, total_cost: number, savings_vs_baseline: number, tier_distribution: {0: 40%, 1: 30%, 2: 5%, 3: 20%, 4: 5%}**}

**Workflow 6: Budget Monitoring** (`006-budget-monitoring.json`) - v3.0 NEW
- **Trigger**: Scheduled (hourly)
- **Input**: None (reads budget pool state)
- **Nodes**: Fetch Budget Pools → Calculate Burn Rate → Check Alert Thresholds → Send Alerts (if ≥90%) → **Check Tier 4 Idle Time** → **Auto-Shutdown (if >30 min)**
- **Output**: {pools: [{name, balance, burn_rate, alert_status}], **tier_4_instances: [{id, uptime, idle_time, action (keep_alive/shutdown)}]**}

**Workflow 7: Tier Routing** (`007-tier-routing.json`) - v3.0 NEW
- **Trigger**: Called by other workflows
- **Input**: {query: string, has_images: boolean, batch_size: number}
- **Nodes**: **Detect Modality** → **RouteLLM Complexity Analysis** → **Detect Batch Size** → **Select Tier (0-4)** → **Pre-Budget Check** → Return Routing Decision
- **Output**: {tier_selected: 0-4, routing_reason: string, complexity_score: number, estimated_cost: number, budget_check: pass/fail}

**Workflow 8: Prompt Compression** (`008-prompt-compression.json`) - v3.0 NEW
- **Trigger**: Called by query workflow
- **Input**: {original_prompt: string, target_tier: 3}
- **Nodes**: Check Prompt Length → **(IF >10k tokens)** → **Call Tier 0 (Ollama 3B) for Compression** → Validate Compressed Prompt → Return
- **Output**: {compressed_prompt: string, original_tokens: number, compressed_tokens: number, compression_ratio: number, **tier_0_cost: number, tier_3_savings: number**}

**Output**: 8 workflow JSON files in `contracts/` including 3 new v3.0 workflows

### 3. Quickstart Guide (`quickstart.md`)

Document setup and testing process for v3.0:

**Sections** (v3.0 Updated):
1. Prerequisites (Docker, Docker Compose, 32GB RAM, RTX 4090 for Tier 2)
2. Installation (clone repo, run docker-compose up with new services)
3. **LiteLLM Setup**: Deploy LiteLLM service, configure model groups, test API
4. **Budget Pool Initialization**: Run setup-budget-pools.sh, configure monthly limits
5. Import workflows into n8n (all 8 workflows including new v3.0 workflows)
6. Configure credentials (API keys for Tier 1/3/4 providers, Helicone, LangSmith)
7. **Test pre-budget check**: Submit query with exhausted budget, verify block
8. **Test tier routing**: Submit simple query (expect Tier 0), complex query (expect Tier 3)
9. Test ingestion workflow (upload sample docs, verify batch routing for >50 docs)
10. Test query workflow (send test query, verify response + tier + cost)
11. **Test architect/executor**: Submit multi-step coding task, verify cost breakdown
12. View metrics and logs (n8n executions, Helicone dashboard, LangSmith traces, OpenTelemetry Jaeger)
13. **View cost analytics**: Budget pool balances, tier distribution, savings vs baseline
14. Troubleshooting common issues (Tier 4 cold start failures, budget exhaustion, tier routing errors)

**Output**: `quickstart.md` with step-by-step instructions for v3.0 setup

### 4. Agent Context Update

Run update script to add new technologies to agent context:

```bash
.specify/scripts/bash/update-agent-context.sh claude
```

**Technologies to add** (v3.0 Updated):
- n8n v1.x
- Qdrant v1.7+
- **LiteLLM (replaces aisuite from v2.0)**
- RouteLLM (with 5-tier routing)
- Ollama (llama3.1:8b for Tier 0, llama3.2-vision for Tier 2, nomic-embed-text)
- Helicone (cost proxy, caching)
- OpenTelemetry (distributed tracing)
- LangSmith or Langfuse (LLM monitoring)
- MCPcat (agent monitoring)
- Fireworks.ai, Together.ai (Tier 1 providers)
- RunPod, Salad, CloudRift (Tier 4 providers)
- Docker Compose (multi-service orchestration)

**Output**: Updated `.specify/memory/agent-context.md` or similar agent-specific file

---

## Next Steps

After implementation plan completion:

1. ✅ **03-research_v3.0.md** created with all 19 technology decisions (including 11 new v3.0 topics)
2. ✅ **data-model.md** created with entity schemas (including 5 new v3.0 entities)
3. ✅ **contracts/** folder with 8 workflow JSONs (including 3 new v3.0 workflows)
4. ✅ **quickstart.md** created with v3.0 setup instructions (including LiteLLM, budget pools, tier routing)
5. ✅ Agent context updated with v3.0 technologies (LiteLLM, 5-tier providers)

**Ready for**: `/speckit.tasks` to generate actionable v3.0 task breakdown with:
- Phase 0: Infrastructure Setup (LiteLLM, budget pools, Tier 4 providers)
- Phase 1: Core RAG (with tier routing, pre-budget checks)
- Phase 2: Cost Optimization (architect/executor, prompt compression, batch routing)
- Phase 3: Observability (cost analytics dashboard, budget monitoring)

---

**Plan Status**: v3.0 architecture design complete. Phase 0 research topics defined. Phase 1 contracts defined. Implementation tasks ready for generation.

**Cost Projection**: $30/month LLM costs (60-70% reduction vs naive routing) with budget pools: Hourly VRAM $100, Per-Token $50, Premium $30, Local VPS $75.

**Performance Target**: 70%+ queries on Tier 0/1 (low cost), <5s response time, 100% budget exhaustion prevention via pre-checks.
