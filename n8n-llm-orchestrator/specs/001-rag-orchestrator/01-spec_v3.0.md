# Feature Specification: Multi-Agent RAG Workflow Orchestrator

**Feature Branch**: `001-rag-orchestrator`
**Version**: 3.0.0
**Created**: 2025-10-30
**Last Updated**: 2025-11-18
**Status**: Active Development
**Input**: "Multi-agent RAG workflow orchestration with n8n, Ollama, and Qdrant with production-grade cost optimization"

---

## Version History

- **v3.0.0** (2025-11-18): LiteLLM integration, 5-tier routing, architect/executor pattern, pre-budget checks, batch routing
- **v2.1.0** (2025-11-17): Web agent capabilities, multi-tier cost orchestration, hourly VRAM providers
- **v2.0.0** (2025-11-15): aisuite integration, RouteLLM, observability stack, intelligent routing
- **v1.0.0** (2025-10-30): Initial specification with basic RAG workflow

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Document Knowledge Base Query (Priority: P1)

A user submits a natural language question via webhook and receives an accurate answer generated from relevant documents retrieved from the knowledge base, with intelligent cost-optimized model selection.

**Why this priority**: This is the core value proposition - enabling users to query their documents using natural language with production-grade cost efficiency. Without this, the system has no primary purpose.

**Independent Test**: Can be fully tested by indexing 10 sample documents, sending a question via HTTP POST, and verifying the response includes relevant information with source citations AND routing decision was cost-optimal (e.g., simple factual query routed to Tier 0/1, complex reasoning to Tier 3). Delivers immediate value as a working Q&A system with 60-70% cost savings.

**Acceptance Scenarios**:

1. **Given** 100 documents are indexed in Qdrant, **When** user submits question "How do I install Qdrant?", **Then** system returns answer with 3-5 relevant document chunks and source citations, routed to Tier 0/1 (simple factual query)
2. **Given** knowledge base contains technical documentation, **When** user asks a question with answer in docs, **Then** response time is under 5 seconds AND system logs which tier was used (0-4) and actual cost
3. **Given** user asks question not covered in documents, **When** no relevant chunks found (score < 0.6), **Then** system responds "I don't have that information in the available documents" via Tier 0 fast filter (minimal cost)
4. **Given** multiple relevant documents exist, **When** user submits query, **Then** response includes citations with document names, relevance scores, AND routing decision rationale (complexity score, tier selected, estimated cost)
5. **Given** user submits complex multi-step coding request, **When** architect/executor pattern is triggered, **Then** Tier 3 (Claude) plans the task and Tier 0/1 executes subtasks, achieving 57% cost savings vs all-Tier-3

---

### User Story 2 - Document Ingestion and Indexing (Priority: P1)

A system administrator uploads documents (PDF, Markdown, TXT) which are automatically processed, chunked, embedded, and indexed into the vector database, with intelligent batch routing for high-volume ingestion.

**Why this priority**: Without indexed documents, the query system has no knowledge base to search. This is a prerequisite for P1 query functionality but equally critical. Batch routing optimization ensures cost-effective processing of large document sets.

**Independent Test**: Can be tested by uploading a folder of 50+ documents, verifying batch size detection triggers Tier 4 GPU rental for embeddings when >50 docs, and confirming chunks are searchable with proper metadata. Delivers value as a cost-optimized document indexing pipeline.

**Acceptance Scenarios**:

1. **Given** a folder containing 50+ PDF files, **When** ingestion workflow is triggered, **Then** system detects batch size >50 and routes embedding generation to Tier 4 (RunPod GPU rental at $0.69/hour) for 30-50% cost savings vs per-token providers
2. **Given** a document is 5000 characters long, **When** document is processed, **Then** it's split into chunks of 800±200 characters with 200-character overlap
3. **Given** chunks are created, **When** embeddings are generated, **Then** each chunk includes metadata (source file, chunk ID, timestamp, page number if PDF) and batch job logs total cost vs per-request cost comparison
4. **Given** document already exists in Qdrant, **When** same document is re-indexed, **Then** old version is replaced (upsert operation)
5. **Given** only 10 documents to ingest, **When** batch size <50, **Then** system uses per-token Tier 1 providers (no GPU rental overhead)

---

### User Story 3 - Multi-Agent Workflow with Tool Calling (Priority: P2)

Users can query the system and trigger multi-step agent workflows where agents decide whether to retrieve additional context, call external tools, or generate final responses, with architect/executor pattern for cost optimization.

**Why this priority**: Enhances the basic Q&A system with intelligent agent behavior (ReAct pattern + architect/executor), enabling more complex multi-step reasoning while maintaining cost efficiency. Not required for MVP but significantly improves answer quality and reduces costs for complex tasks.

**Independent Test**: Can be tested by creating a workflow where Architect Agent (Tier 3 Claude) plans a multi-step coding task, Executor Agents (Tier 0/1) implement each subtask, and Review Agent (Tier 3) validates results. Measure 50%+ cost savings vs all-Tier-3 execution. Delivers value as an intelligent cost-optimized agent system with decision-making capability.

**Acceptance Scenarios**:

1. **Given** user asks "What are the latest features in version 2.0?", **When** Parse Agent (Tier 0) determines metadata filtering needed, **Then** agent routes to Tier 1 for search execution before generating answer
2. **Given** user requests complex code refactoring, **When** architect/executor pattern is triggered, **Then** Architect (Tier 3 Claude $0.15) plans 10 subtasks → Executors (Tier 0/1 $0.35 total) implement → Reviewer (Tier 3 $0.15) validates = $0.65 total (57% savings vs $1.50 all-Tier-3)
3. **Given** agent workflow executing, **When** maximum 5 iterations reached, **Then** workflow terminates gracefully with partial results and total cost breakdown
4. **Given** tool call fails (timeout/error), **When** agent retries 3 times unsuccessfully, **Then** fallback response provided with error explanation and downgraded to lower-cost tier for retry

---

### User Story 4 - LLM Provider Fallback Chain (Priority: P1 - Updated)

When primary LLM provider (Ollama Tier 0) is unavailable or slow, the system automatically falls back through tier chain (Tier 1 → Tier 2 → Tier 3) based on query requirements, with pre-budget checks preventing cost overruns.

**Why this priority**: **UPGRADED TO P1** - Critical for production reliability AND cost control. Pre-budget checks are mandatory in v3.0 to prevent budget exhaustion. Most development/testing happens locally with Ollama, and tiered fallback ensures both availability and cost optimization.

**Independent Test**: Can be tested by stopping Ollama service, submitting query, and verifying system automatically switches to Tier 1 (Fireworks) after pre-budget check confirms sufficient budget. Test budget exhaustion scenario where pre-check blocks Tier 3 call and forces Tier 0/1. Delivers value as a highly available cost-controlled system.

**Acceptance Scenarios**:

1. **Given** Ollama (Tier 0) is offline, **When** user submits query, **Then** system checks budget AND automatically routes to Tier 1 (Fireworks) within 2 seconds if budget allows
2. **Given** Tier 1 provider times out after 30 seconds, **When** timeout occurs, **Then** pre-budget check runs → if budget allows, retry with Tier 2 (local multimodal) or Tier 3 (Claude)
3. **Given** monthly budget is at 95% capacity, **When** query requires Tier 3, **Then** pre-budget check BLOCKS call and forces routing to Tier 0/1 OR returns "budget exhausted" error
4. **Given** fallback provider is used, **When** query completes successfully, **Then** response includes metadata (tier used, cost, budget remaining, routing reason)
5. **Given** all providers fail, **When** no LLM available, **Then** user receives clear error message with retry suggestion and no cost incurred

---

### User Story 5 - Observable Workflow Execution with Cost Analytics (Priority: P2 - Updated)

Administrators can view detailed logs and metrics for all workflow executions, including LLM prompts, retrieved chunks, token usage, tier routing decisions, and real-time cost tracking with budget alerts.

**Why this priority**: Essential for production cost control and debugging. V3.0 emphasizes cost observability with pre-budget checks, tier selection rationale, and budget pool monitoring. Can be added after core features are working but critical before production deployment.

**Independent Test**: Can be tested by executing a workflow and verifying all steps are logged with timestamps, prompts, responses, tier selections, costs, and budget impacts. Verify budget alert triggers at 90% capacity. Delivers value as a cost-transparent debuggable system.

**Acceptance Scenarios**:

1. **Given** workflow executes, **When** execution completes, **Then** n8n execution log shows all node outputs including LLM prompts, responses, tier used (0-4), cost per call, and cumulative cost
2. **Given** RAG retrieval occurs, **When** chunks are retrieved, **Then** log includes relevance scores, source documents, chunk count, AND whether Qdrant or PageIndex was used (with cost breakdown)
3. **Given** workflow runs for 1 month, **When** administrator views cost dashboard, **Then** shows total queries per tier, cost per tier, budget pool status (hourly VRAM $100/month, per-token $50/month, premium $30/month), and cost savings vs naive routing (target: 60-70%)
4. **Given** hourly VRAM instance (Tier 4) has been idle >30 minutes, **When** shutdown timer triggers, **Then** alert sent to admin and instance auto-shutdown to prevent waste
5. **Given** any budget pool reaches 90% capacity, **When** threshold crossed, **Then** alert sent to admin and routing preferences shift to lower tiers

---

### Edge Cases (v3.0 Enhanced)

- What happens when user uploads a 500-page PDF? (System detects batch size >50, routes to Tier 4 GPU rental, tracks cost vs Tier 1 baseline, processes in batches with progress tracking)
- How does system handle duplicate questions within short time window? (Tier 0 fast filter checks Helicone cache with 1-hour TTL, returns cached result at $0 cost)
- What if Qdrant vector database is down? (Workflow fails gracefully, checks if PageIndex MCP can handle query as fallback, returns error with retry logic)
- How does system behave with malicious input (SQL injection, prompt injection)? (Input sanitization before LLM prompts, Qdrant queries protected by parameterization, Tier 0 filter detects malicious patterns and blocks before expensive Tier 3 calls)
- What happens when embedding model changes? (All documents must be re-indexed, batch routing automatically engages for >50 docs, cost comparison logged)
- How does system handle documents in multiple languages? (Tier 0 detects language, routes to appropriate provider - nomic-embed-text for English, multilingual models for others)
- What if monthly budget is exhausted mid-query? (Pre-budget check blocks call BEFORE sending to provider, returns "budget exhausted" error, suggests retry with lower tier or next month)
- What happens when Tier 4 GPU rental instance fails to start? (Cold start timeout after 3 minutes triggers fallback to Tier 1 per-token providers, cost delta logged)
- How does prompt compression work for long contexts? (Tier 0 Ollama 3B compresses 10k-token context to 4k tokens using extractive summarization before sending to Tier 3, achieving 60% token reduction and cost savings)

---

## Requirements *(mandatory)*

### Functional Requirements

#### Document Ingestion

- **FR-001**: System MUST accept document uploads in PDF, Markdown (.md), and plain text (.txt) formats
- **FR-002**: System MUST automatically extract text from PDF files including multi-page documents
- **FR-003**: System MUST chunk documents into 800-character segments with 200-character overlap
- **FR-004**: System MUST generate vector embeddings using consistent embedding model (nomic-embed-text, 768 dimensions)
- **FR-005**: System MUST store chunks in Qdrant with metadata: source filename, chunk ID, timestamp, page number (if PDF)
- **FR-006**: System MUST support batch ingestion of multiple documents (minimum 50 documents per batch)
- **FR-007**: System MUST deduplicate documents by filename and timestamp before re-indexing
- **FR-056**: System MUST detect batch size during ingestion and route to Tier 4 GPU rental when count >50 documents for cost optimization (NEW v3.0)
- **FR-057**: System MUST log batch processing cost comparison (Tier 4 hourly vs Tier 1 per-token baseline) for transparency (NEW v3.0)

#### Query and Retrieval

- **FR-008**: System MUST accept natural language queries via HTTP webhook (POST request)
- **FR-009**: System MUST convert user query to vector embedding using same model as document indexing
- **FR-010**: System MUST perform similarity search in Qdrant and retrieve top 3-5 most relevant chunks
- **FR-011**: System MUST filter retrieved chunks by minimum relevance score (threshold: 0.6)
- **FR-012**: System MUST augment LLM prompt with retrieved chunks and original query
- **FR-013**: System MUST generate answer using configured LLM provider via LiteLLM unified interface (Tier 0-4)
- **FR-014**: System MUST include source citations in response (document name, relevance score)
- **FR-015**: System MUST return "I don't have that information" when no chunks meet relevance threshold, using Tier 0 fast filter for minimal cost (NEW v3.0)
- **FR-058**: System MUST use Tier 0 (Ollama 3B-13B) for fast query classification (<500ms) before expensive tier routing (NEW v3.0)
- **FR-059**: System MUST compress long prompts (>10k tokens) using Tier 0 extractive summarization before sending to Tier 3, achieving 60% token reduction (NEW v3.0)

#### Multi-Agent Orchestration

- **FR-016**: System MUST implement Parse Agent that analyzes queries and determines retrieval strategy
- **FR-017**: System MUST support conditional routing based on agent decisions (use tool vs generate directly)
- **FR-018**: System MUST limit agent iteration loops to maximum 5 iterations per query
- **FR-019**: System MUST pass agent state explicitly between n8n nodes (no hidden global state)
- **FR-020**: System MUST support parallel agent execution when agents are independent (e.g., multi-domain search)
- **FR-060**: System MUST implement Architect/Executor pattern for multi-step tasks: Architect (Tier 3 Claude) plans → Executors (Tier 0/1) implement → Reviewer (Tier 3) validates (NEW v3.0)
- **FR-061**: System MUST track cost breakdown per agent role (architect, executor, reviewer) and log savings vs all-Tier-3 baseline (target: 50%+ savings) (NEW v3.0)

#### Error Handling and Resilience

- **FR-021**: System MUST implement automatic retry with exponential backoff for LLM API calls (max 3 retries)
- **FR-022**: System MUST timeout LLM requests after 30 seconds
- **FR-023**: System MUST return meaningful error messages to users (not technical stack traces)
- **FR-024**: System MUST continue workflow execution when non-critical errors occur (e.g., optional tool call fails)
- **FR-025**: System MUST log all errors with full context (query, retrieved chunks, LLM prompt, tier attempted, cost incurred)
- **FR-062**: System MUST downgrade to lower tier on provider failure (Tier 3 fails → retry Tier 2 → retry Tier 1 → retry Tier 0) after pre-budget check (NEW v3.0)

#### LLM Provider Management (v3.0: LiteLLM 5-Tier System)

- **FR-026**: System MUST support multiple LLM providers: Ollama (local), Anthropic Claude, Google Gemini, OpenAI GPT, Fireworks.ai, Together.ai, RunPod, Salad, CloudRift
- **FR-027**: System MUST route ALL LLM calls through **LiteLLM** unified interface (no direct provider calls from n8n) (CHANGED from aisuite in v2.0)
- **FR-028**: System MUST allow per-workflow LLM provider configuration via LiteLLM model groups (architect, executor, vision)
- **FR-029**: System MUST implement provider fallback chain via LiteLLM (e.g., Tier 0 → Tier 1 → Tier 2 → Tier 3)
- **FR-030**: System MUST track token usage per query and provider via Helicone proxy
- **FR-031**: System MUST cache identical queries via Helicone with 1-hour TTL to reduce costs
- **FR-032**: LiteLLM service MUST expose OpenAI-compatible HTTP API that n8n can call via HTTP Request nodes
- **FR-063**: System MUST implement 5-tier model routing system (CHANGED from 4-tier in v2.0):
  - **Tier 0**: Local fast filter (Ollama 3B-13B, <500ms, $0)
  - **Tier 1**: Hosted open source (Fireworks/Together, $0.20-0.80/M tokens)
  - **Tier 2**: Local multimodal (Ollama 70B+Vision, VPS fixed cost ~$75/month)
  - **Tier 3**: Premium APIs (Claude/Gemini, $3-15/M tokens)
  - **Tier 4**: GPU rental (RunPod/Salad/CloudRift, $0.69-2/hour)
- **FR-064**: System MUST support provider aliasing (model groups) to abstract tier selection from workflows (NEW v3.0)
- **FR-065**: LiteLLM config MUST define fallback chains per tier with automatic failover (NEW v3.0)

#### Pre-Budget Checks and Cost Control (NEW v3.0)

- **FR-066**: System MUST perform pre-budget check BEFORE every LLM API call (MANDATORY, blocking operation)
- **FR-067**: Pre-budget check MUST validate sufficient budget remaining in relevant pool (hourly VRAM, per-token, premium, local VPS)
- **FR-068**: System MUST block API call if budget insufficient and return "budget exhausted" error to user
- **FR-069**: System MUST calculate estimated cost for query based on tier, average token count, and provider pricing before call
- **FR-070**: System MUST update budget pool balances in real-time after each LLM call (not batch)
- **FR-071**: System MUST maintain separate budget pools:
  - Hourly VRAM: $100/month (RunPod, Salad, CloudRift)
  - Per-Token: $50/month (Fireworks, Together.ai)
  - Premium APIs: $30/month (Claude, Gemini, GPT-4)
  - Local VPS: $75/month (Ollama fixed infrastructure cost)
- **FR-072**: System MUST send alert when any budget pool reaches 90% capacity
- **FR-073**: System MUST auto-shutdown idle Tier 4 instances after 30 minutes to prevent waste
- **FR-074**: System MUST log all budget decisions (pre-check pass/fail, pool balances, estimated vs actual cost)

#### Batch Size Routing (NEW v3.0)

- **FR-075**: System MUST detect batch size for embedding generation, document processing, and bulk queries
- **FR-076**: System MUST route to Tier 4 GPU rental when batch size ≥50 requests (amortize hourly cost)
- **FR-077**: System MUST route to Tier 1 per-token when batch size <50 requests (avoid GPU rental overhead)
- **FR-078**: System MUST calculate cost comparison (Tier 4 hourly vs Tier 1 per-token) and log decision rationale
- **FR-079**: System MUST spin up Tier 4 GPU instance with 1-3 minute cold start, fallback to Tier 1 during startup
- **FR-080**: System MUST keep Tier 4 instance warm when batch jobs are queued (shutdown only after 30 min idle)

#### Intelligent Routing (v3.0: RouteLLM with 5 Tiers)

- **FR-040**: System MUST analyze query complexity using RouteLLM before model selection
- **FR-041**: Simple queries (factual lookup, formatting, <500 chars) MUST route to Tier 0 (Ollama 3B-13B, <500ms, $0)
- **FR-042**: Light queries (standard text generation, API responses) MUST route to Tier 1 (Fireworks/Together, $0.20-0.80/M tokens)
- **FR-081**: Image analysis queries MUST route to Tier 2 (Ollama 70B+Vision, VPS fixed cost) (NEW v3.0)
- **FR-082**: Complex queries (advanced reasoning, architecture planning) MUST route to Tier 3 (Claude/Gemini, $3-15/M tokens) (CHANGED from FR-043)
- **FR-083**: Batch processing (>50 requests) MUST route to Tier 4 (RunPod/Salad, $0.69-2/hour) (NEW v3.0)
- **FR-044**: System MUST log routing decisions with complexity scores for auditability
- **FR-045**: Manual model override MUST be available via workflow configuration parameter

#### Prompt Compression (NEW v3.0)

- **FR-084**: System MUST detect long prompts (>10k tokens) before sending to Tier 3
- **FR-085**: System MUST use Tier 0 (Ollama 3B) for extractive summarization to compress prompts 40-60%
- **FR-086**: System MUST preserve critical context during compression (user query, top 3 chunks, source citations)
- **FR-087**: System MUST log compression ratio and token savings for cost analysis
- **FR-088**: Compressed prompts MUST maintain answer quality (measured by user feedback or eval dataset)

#### Web Content Extraction (from v2.0)

- **FR-046**: System MUST use Firecrawl for extracting content from web URLs
- **FR-047**: Extracted web content MUST be in LLM-friendly structured format (Markdown or JSON)
- **FR-048**: Firecrawl MUST handle JavaScript rendering for dynamic content
- **FR-049**: Web extraction errors MUST NOT crash workflows (fallback to simple HTTP fetch)
- **FR-050**: Extracted content MUST include metadata: URL, title, extraction timestamp

#### Vectorless RAG (Documentation) (from v2.0)

- **FR-051**: System MUST support PageIndex MCP for frequently-accessed documentation
- **FR-052**: PageIndex MCP MUST provide keyword-based retrieval without embedding costs
- **FR-053**: System MUST use PageIndex for API docs, technical references, and static content
- **FR-054**: PageIndex results MUST be combined with Qdrant vector results when both available
- **FR-055**: PageIndex failures MUST gracefully degrade to Qdrant-only retrieval

#### Observability (v3.0: Enhanced with Cost Analytics)

- **FR-033**: System MUST log all workflow executions with timestamps and status (success/failure)
- **FR-034**: System MUST capture LLM prompts and responses in LangSmith or Langfuse
- **FR-035**: System MUST track RAG retrieval metrics: chunks retrieved, relevance scores, source documents, retrieval method (Qdrant/PageIndex)
- **FR-036**: System MUST retain execution logs for minimum 30 days
- **FR-037**: System MUST expose metrics: total queries, average latency, error rate, token usage, **cost per tier, budget pool status** (ENHANCED)
- **FR-038**: System MUST implement distributed tracing with OpenTelemetry across all components
- **FR-039**: System MUST track tool calls and errors via MCPcat for agent monitoring
- **FR-089**: System MUST expose cost analytics dashboard showing: (NEW v3.0)
  - Cost per tier (0-4) over time
  - Budget pool balances and burn rate
  - Routing decision distribution (% queries per tier)
  - Architect/executor cost breakdown
  - Savings vs naive routing baseline (target: 60-70%)
  - Hourly VRAM instance uptime and idle time
  - Cache hit rate and cost savings from Helicone
- **FR-090**: System MUST log pre-budget check results (pass/fail, estimated cost, pool balance) for every LLM call (NEW v3.0)

### Key Entities (v3.0 Enhanced)

- **Document**: Represents uploaded file; attributes include filename, file type (PDF/MD/TXT), upload timestamp, size in bytes, processing status, batch job ID (if part of batch ingestion)
- **Chunk**: Represents segmented portion of document; attributes include text content (800 chars), source document reference, chunk ID (sequential), page number (if PDF), embedding vector (768 dimensions)
- **Query**: Represents user question; attributes include query text, timestamp, user ID (if auth implemented), embedding vector, execution ID for tracing, complexity score (from RouteLLM), **tier selected (0-4), estimated cost, actual cost** (NEW)
- **Retrieval Result**: Represents chunks returned from vector search; attributes include chunk reference, relevance score (0.0-1.0), source document, rank position (1-5), source type (Qdrant/PageIndex)
- **Workflow Execution**: Represents single n8n workflow run; attributes include execution ID, start time, end time, status (success/failure/timeout), error message, token usage, trace ID (OpenTelemetry), **total cost, cost per tier, budget impact** (NEW)
- **LLM Response**: Represents generated answer; attributes include answer text, source citations, LLM provider used (via LiteLLM), token count, generation latency, cache hit (from Helicone), **tier used (0-4), cost** (NEW)
- **Routing Decision**: Represents RouteLLM model selection; attributes include query ID, complexity score, selected tier (0-4), routing reason, manual override flag, **pre-budget check result** (NEW)
- **Web Content**: Represents extracted web page; attributes include source URL, extracted markdown, extraction method (Firecrawl/fallback), timestamp, metadata (title, author)
- **Trace**: Represents distributed trace; attributes include trace ID, span ID, service name (n8n/LiteLLM/provider), duration, parent span, tags (provider, model, cost, tier)
- **Budget Check** (NEW v3.0): Represents pre-flight budget validation; attributes include check timestamp, query ID, tier requested, estimated cost, budget pool, current balance, result (pass/fail), blocking reason
- **Batch Job** (NEW v3.0): Represents batch processing operation; attributes include job ID, batch size, tier selected (4 if size ≥50, else 1), start time, end time, total cost, cost comparison (Tier 4 vs Tier 1 baseline), instance uptime
- **Budget Pool** (NEW v3.0): Represents monthly budget allocation; attributes include pool name (hourly_vram/per_token/premium/local_vps), monthly limit ($100/$50/$30/$75), current balance, burn rate ($/day), alert threshold (90%), last reset date
- **Agent Task** (NEW v3.0): Represents architect/executor workflow task; attributes include task ID, role (architect/executor/reviewer), tier used, prompt tokens, completion tokens, cost, parent task ID (for subtask tracking), savings vs baseline
- **Prompt Compression** (NEW v3.0): Represents prompt optimization operation; attributes include original prompt, compressed prompt, original token count, compressed token count, compression ratio (%), tier 0 compression cost, tier 3 savings

---

## Success Criteria *(mandatory)*

### Measurable Outcomes (v3.0 Enhanced)

- **SC-001**: Users receive accurate answers to questions covered in indexed documents with 85%+ accuracy (measured by user feedback or evaluation dataset)
- **SC-002**: End-to-end query response time is under 5 seconds for 90% of queries (p90 latency), **including pre-budget check overhead <100ms** (ENHANCED)
- **SC-003**: Document ingestion processes at least 10 documents per minute, **with batch routing engaged automatically for >50 docs** (ENHANCED)
- **SC-004**: System successfully retrieves relevant chunks (score > 0.6) for 80% of queries
- **SC-005**: System handles minimum 5 concurrent query workflows without performance degradation
- **SC-006**: Error rate is below 5% for all workflow executions (excluding user errors like empty queries)
- **SC-007**: Users can identify source documents for every claim in generated answers (100% citation coverage)
- **SC-008**: LLM provider fallback succeeds within 2 seconds when primary provider fails, **after pre-budget check confirms budget availability** (ENHANCED)
- **SC-009**: Token usage per query is tracked and logged with 100% accuracy, **with real-time budget pool updates** (ENHANCED)
- **SC-010**: Administrators can debug failed workflows using execution logs within 10 minutes, **including cost breakdown per step** (ENHANCED)

### Cost Optimization Outcomes (v3.0)

- **SC-011**: RouteLLM routes 70%+ of queries to cost-optimized models (Tier 0/1) without quality degradation (from v2.0)
- **SC-012**: Helicone cache hit rate is 20%+ for duplicate queries within 1-hour window (from v2.0)
- **SC-013**: All LLM requests trace through OpenTelemetry with complete span coverage (100%) (from v2.0)
- **SC-021**: **Tier 0 fast filter handles 40%+ of simple queries (<500 chars) at $0 cost** (NEW v3.0)
- **SC-022**: **Batch routing engages for 100% of jobs with ≥50 requests, achieving 30-50% cost savings vs per-token baseline** (NEW v3.0)
- **SC-023**: **Architect/executor pattern achieves 50%+ cost savings vs all-Tier-3 baseline for multi-step tasks** (NEW v3.0)
- **SC-024**: **Prompt compression reduces Tier 3 token usage by 40-60% on long-context queries (>10k tokens)** (NEW v3.0)
- **SC-025**: **Pre-budget checks prevent 100% of budget overruns (0 unauthorized charges)** (NEW v3.0)
- **SC-026**: **Tier 4 hourly instances auto-shutdown within 30 minutes of idle, preventing waste** (NEW v3.0)
- **SC-027**: **Overall cost reduction of 60-70% vs naive all-Tier-3 routing measured over 30-day period** (NEW v3.0)
- **SC-028**: **Budget alerts trigger at 90% capacity for all pools with 0 false negatives** (NEW v3.0)

### Web & Observability Outcomes (from v2.0)

- **SC-014**: Web content extraction via Firecrawl succeeds for 95%+ of tested URLs
- **SC-015**: PageIndex MCP reduces embedding API calls by 40%+ for documentation queries
- **SC-016**: LangSmith/Langfuse captures all prompts and responses for audit trail (100% coverage)

### Business Outcomes (v3.0 Enhanced)

- **SC-017**: System reduces time to find information in documents by 70% compared to manual search
- **SC-018**: Users complete research tasks without external search engines for 80% of queries
- **SC-019**: Monthly LLM costs stay under **$30** (REDUCED from $50 in v2.0) for up to 10,000 queries via intelligent 5-tier routing, pre-budget checks, and prompt compression (ENHANCED)
- **SC-020**: Debugging time reduced by 60% with distributed tracing and visual workflow monitoring
- **SC-029**: **Cost transparency: 100% of queries include tier used, cost, and routing rationale in response metadata** (NEW v3.0)
- **SC-030**: **System maintains 99%+ availability despite budget constraints via intelligent tier fallback** (NEW v3.0)

---

## Assumptions (v3.0 Updated)

1. Documents are primarily English text (nomic-embed-text optimized for English)
2. Users have basic understanding of how to formulate search queries
3. n8n, Ollama, and Qdrant are pre-installed and running locally (setup not in scope)
4. Average document size is 5-20 pages (500-10,000 words)
5. Query volume is under 10,000 queries/month (small-to-medium scale)
6. No user authentication required initially (can be added in future iteration)
7. Documents do not contain highly sensitive PII requiring encryption at rest
8. Network latency between n8n and Qdrant is negligible (< 10ms local network)
9. **LiteLLM service runs as containerized HTTP service accessible to n8n** (NEW v3.0)
10. **Budget pools are reset monthly on 1st of month** (NEW v3.0)
11. **Tier 4 GPU rental providers (RunPod/Salad/CloudRift) have <3 minute cold start time** (NEW v3.0)
12. **VPS has sufficient resources for Ollama 70B+Vision (Tier 2): 48GB RAM, RTX 4090 or equivalent** (NEW v3.0)

---

## Out of Scope (v3.0 Updated)

- Real-time streaming responses (batch response only)
- Multi-tenant support with isolated knowledge bases per user
- Custom LLM fine-tuning on user documents
- Advanced document preprocessing (OCR for scanned PDFs, table extraction)
- Multi-modal support beyond vision (audio, video)
- User authentication and authorization
- API rate limiting and quotas (handled by pre-budget checks only)
- Mobile app or CLI interface (HTTP webhook only)
- Automated model retraining based on user feedback
- **Dynamic budget pool reallocation (fixed monthly limits)** (NEW v3.0)
- **Real-time cost optimization via reinforcement learning (static routing thresholds)** (NEW v3.0)
- **Cross-organization budget sharing** (NEW v3.0)

---

## Dependencies (v3.0)

### Required Services

1. **n8n** (workflow orchestration)
2. **LiteLLM** (unified LLM API, replaces aisuite from v2.0)
3. **RouteLLM** (query complexity analysis)
4. **Helicone** (cost proxy, caching, logging)
5. **Ollama** (Tier 0 fast filter, Tier 2 multimodal)
6. **Qdrant** (vector database)
7. **Redis** (n8n queue + caching)

### Observability Stack

8. **OpenTelemetry Collector** (distributed tracing)
9. **Jaeger or Zipkin** (trace backend)
10. **LangSmith or Langfuse** (LLM monitoring)
11. **MCPcat** (agent monitoring)

### External Providers

12. **Fireworks.ai / Together.ai** (Tier 1 per-token)
13. **Anthropic Claude / Google Gemini** (Tier 3 premium)
14. **RunPod / Salad / CloudRift** (Tier 4 hourly VRAM)
15. **Firecrawl** (web scraping, optional)
16. **PageIndex MCP** (vectorless RAG, optional)

### Infrastructure Requirements

- **VPS**: 48GB RAM, RTX 4090 or equivalent for Tier 2 (Ollama 70B+Vision)
- **Storage**: 500GB SSD for Qdrant, document storage, logs
- **Network**: 100 Mbps+ for API calls to external providers

---

## Migration Notes (v2.0 → v3.0)

### Breaking Changes

1. **aisuite replaced with LiteLLM** - All n8n HTTP Request nodes calling aisuite must update endpoint to LiteLLM OpenAI-compatible API
2. **4-tier system expanded to 5-tier** - Routing logic must update to include Tier 0 (fast filter) and separate Tier 4 (GPU rental)
3. **Pre-budget checks now MANDATORY** - All workflows must include pre-budget check node before LLM calls (blocking operation)
4. **Budget pool configuration required** - Must define monthly limits for 4 budget pools in environment variables
5. **Architect/executor pattern recommended** - Multi-step tasks should refactor to use tiered agent roles

### Upgrade Path

1. Deploy LiteLLM container with OpenAI-compatible API
2. Update n8n HTTP Request nodes to point to LiteLLM endpoint (e.g., `http://litellm:4000/v1/chat/completions`)
3. Configure LiteLLM model groups: `architect`, `executor`, `vision`, `fast_filter`, `batch_gpu`
4. Add pre-budget check JavaScript code node template to all workflows
5. Define budget pool limits in environment variables
6. Test tier routing with sample queries (simple → Tier 0, complex → Tier 3)
7. Implement architect/executor pattern for Coder Agent workflow
8. Configure batch size detection for document ingestion workflow
9. Enable Tier 4 GPU rental provider accounts (RunPod, Salad, or CloudRift)
10. Set up cost analytics dashboard with budget pool monitoring

---

**Document Version**: 3.0.0
**Last Updated**: 2025-11-18
**Next Review**: Before Phase 0 implementation (LiteLLM deployment)
