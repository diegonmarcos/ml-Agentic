# Multi-Agent RAG Orchestrator v4.2 - Specification

**Version**: 4.2.0
**Date**: 2025-11-18
**Status**: Active
**Related Documents**:
- [0.constitution_v4.2.md](0.constitution_v4.2.md)
- [v4.2-ENHANCEMENT-PLAN.md](v4.2-ENHANCEMENT-PLAN.md)
- [v4.2-REPOSITORY-LEARNINGS.md](v4.2-REPOSITORY-LEARNINGS.md)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [User Personas](#user-personas)
3. [User Stories](#user-stories)
4. [Functional Requirements](#functional-requirements)
5. [Non-Functional Requirements](#non-functional-requirements)
6. [Acceptance Criteria](#acceptance-criteria)
7. [Success Metrics](#success-metrics)

---

## Executive Summary

The **Multi-Agent RAG Workflow Orchestrator v4.2** is a production-grade system that enables natural language querying over document knowledge bases with guaranteed accuracy, privacy compliance, and cost efficiency.

### Key Capabilities

**For End Users**:
- Natural language Q&A with source citations
- Privacy mode for sensitive data (100% local processing)
- Cost transparency with real-time spending dashboard
- Multi-modal capabilities (text + vision)

**For Developers**:
- Visual workflow design with n8n
- Provider-agnostic LLM integration
- 99.9% uptime SLA with automatic failover
- LLMOps observability and A/B testing

**For Enterprises**:
- GDPR/HIPAA compliance via privacy mode
- Predictable costs with hard budget limits
- Production-grade reliability
- Open-source first (80% execution on local models)

### What's New in v4.2

Based on analysis of 8 production systems (56k+ GitHub stars combined), v4.2 adds:

- **40-60% Better RAG Accuracy**: Hybrid search + reranking + semantic chunking
- **3-5x Faster Web Agents**: LLM-driven autonomous browsing with stealth mode
- **100% Privacy Compliance**: MCP servers + Jan integration + local-only audit logs
- **99.9% Uptime**: Provider abstraction + health checks + automatic failover
- **25-40% Cost Reduction**: Streaming + early termination + hard budget limits
- **Production Observability**: LLMOps feedback loop with PostgreSQL logging

---

## User Personas

### Persona 1: Data Analyst (Primary)
**Name**: Sarah Chen
**Role**: Data Analyst at Healthcare Provider
**Goals**:
- Query internal medical research documents for evidence-based answers
- Maintain HIPAA compliance (no data leaving premises)
- Track costs to stay within department budget

**Pain Points**:
- Current tools require manual document review (hours per query)
- Cloud AI tools violate HIPAA compliance
- No visibility into how answers are generated

**v4.2 Solution**:
- Privacy mode ensures 100% local processing
- RAG with citations shows source documents
- Cost dashboard tracks spending in real-time

---

### Persona 2: DevOps Engineer (Secondary)
**Name**: Marcus Rodriguez
**Role**: Senior DevOps Engineer at Tech Startup
**Goals**:
- Deploy reliable AI systems with 99.9% uptime
- Minimize costs while maintaining quality
- Troubleshoot issues quickly with detailed logs

**Pain Points**:
- OpenAI outages break production systems
- Unpredictable API costs (bills spike unexpectedly)
- Black-box LLM failures are hard to debug

**v4.2 Solution**:
- Provider failover ensures uptime even if Anthropic/OpenAI is down
- Hard budget limits prevent cost surprises
- LLMOps dashboard shows every LLM call with full context

---

### Persona 3: AI Product Manager (Secondary)
**Name**: Emily Thompson
**Role**: AI Product Manager at Enterprise SaaS
**Goals**:
- Optimize LLM costs without sacrificing quality
- Validate improvements with A/B testing
- Balance privacy vs performance for different customers

**Pain Points**:
- No data on which LLM tier is optimal for which tasks
- Manual prompt engineering without metrics
- Can't offer privacy mode due to technical limitations

**v4.2 Solution**:
- LLMOps analytics show tier performance by task type
- A/B testing framework validates prompt changes
- Privacy mode toggle enables compliance-sensitive deployments

---

## User Stories

### Epic 1: Intelligent Document Q&A

#### US-1.1: Basic Knowledge Base Query
**As a** data analyst
**I want to** ask natural language questions about my document corpus
**So that** I can find information quickly without manual document review

**Acceptance Criteria**:
- User submits query via web UI or API
- System returns answer within 5 seconds (p95)
- Answer includes source citations (doc name, page, chunk ID)
- Confidence score is displayed (0-100%)
- If confidence <60%, system says "I don't know" instead of guessing

**Priority**: P0 (Critical)

---

#### US-1.2: Privacy Mode for Sensitive Data
**As a** healthcare analyst
**I want to** enable privacy mode for HIPAA-compliant queries
**So that** no patient data leaves our on-premises servers

**Acceptance Criteria**:
- Privacy mode toggle is clearly visible in UI
- When enabled, ALL queries route to Tier 0/2 (local models only)
- System blocks external API calls (Tier 1/3/4)
- Audit log records all operations locally (encrypted, append-only)
- UI shows "Privacy Mode Active" badge with green indicator
- Performance degradation is acceptable (<30% slower vs non-privacy)

**Priority**: P0 (Critical)

---

#### US-1.3: Cost-Aware Query Processing
**As a** budget-conscious user
**I want to** see estimated and actual costs before and after queries
**So that** I can stay within my monthly budget

**Acceptance Criteria**:
- Web UI shows estimated cost BEFORE submitting query
- Real-time cost counter updates during streaming response
- Final cost is displayed after completion
- Daily/weekly/monthly spending summary is accessible
- Budget utilization bar shows remaining capacity (green/yellow/red)
- System blocks queries that would exceed daily budget limit

**Priority**: P1 (High)

---

### Epic 2: Enhanced RAG Accuracy

#### US-2.1: Hybrid Search for Better Retrieval
**As a** system operator
**I want** the RAG pipeline to use both semantic and keyword search
**So that** retrieval accuracy improves by 40-60%

**Acceptance Criteria**:
- Hybrid search combines semantic (70%) + keyword (30%) scores
- BM25 index is created alongside Qdrant vector index
- Retrieval includes both exact keyword matches and semantic similar docs
- A/B test shows ≥30% precision improvement over semantic-only
- Configuration allows tuning semantic:keyword weight ratio

**Priority**: P0 (Critical)

---

#### US-2.2: Semantic Chunking to Prevent Context Fragmentation
**As a** system operator
**I want** documents chunked by semantic similarity instead of fixed token count
**So that** related sentences stay together and reduce hallucination

**Acceptance Criteria**:
- Chunking uses spaCy sentence embeddings + cosine similarity
- Chunks are created when similarity <0.7 threshold
- Document type detection applies specialized chunking (code, markdown, JSON)
- Hallucination rate decreases by ≥25% in A/B test
- Average chunk size is 300-600 tokens (adaptive, not fixed)

**Priority**: P1 (High)

---

#### US-2.3: Reranking for Top-K Precision
**As a** system operator
**I want** a two-stage retrieval pipeline with cross-encoder reranking
**So that** the top-5 results have ≥15% better precision

**Acceptance Criteria**:
- Initial retrieval fetches 20 candidates (over-fetch)
- Cross-encoder reranks to select best 5
- Reranking is adaptive: always for Tier 3, conditional for Tier 0/1
- A/B test shows ≥15% improvement in P@5 metric
- Reranking latency is <400ms

**Priority**: P1 (High)

---

### Epic 3: Production-Grade Reliability

#### US-3.1: Provider Failover for 99.9% Uptime
**As a** DevOps engineer
**I want** automatic failover to backup LLM providers
**So that** the system stays online even if Anthropic/OpenAI has outages

**Acceptance Criteria**:
- Health checks run every 5 minutes for all providers
- Failover triggers within 2 seconds of provider failure
- Fallback chain: Tier N → Tier N+1 → Tier 3
- Circuit breaker opens after 3 consecutive failures
- Uptime SLA is ≥99.9% (max 43 minutes downtime/month)
- Alerts are sent when failover occurs

**Priority**: P0 (Critical)

---

#### US-3.2: LLMOps Observability Dashboard
**As a** DevOps engineer
**I want** visibility into all LLM invocations with cost, latency, and success metrics
**So that** I can troubleshoot issues and optimize performance

**Acceptance Criteria**:
- PostgreSQL stores: tier, model, tokens, cost, latency, success, error
- Dashboard shows real-time metrics (last 24h)
- Historical analysis for 30 days of data
- Filters by: user, tier, model, task_type, success/failure
- Export functionality for external BI tools
- Alerting for: cost spikes, error rate >5%, latency p95 >10s

**Priority**: P0 (Critical)

---

### Epic 4: Privacy-First Web Agent

#### US-4.1: LLM-Driven Autonomous Browsing
**As a** research agent
**I want to** autonomously navigate websites based on LLM decisions
**So that** I can complete complex tasks without brittle static scripts

**Acceptance Criteria**:
- Action-perception loop: LLM observes page → decides action → Playwright executes
- Actions supported: navigate, click, type, extract, scroll, done
- Maximum 10 iterations per task
- Task success rate ≥90% on benchmark tasks
- Average task completion time: 12-15 seconds

**Priority**: P1 (High)

---

#### US-4.2: Privacy-Hardened Playwright
**As a** privacy-conscious user
**I want** web browsing that blocks trackers and randomizes fingerprints
**So that** my browsing activity remains private

**Acceptance Criteria**:
- Stealth mode prevents webdriver detection
- Random fingerprints: user agent, viewport, canvas noise
- Tracker blocking: Google Analytics, Facebook Pixel, etc.
- CAPTCHA encounter rate <5% of sessions
- Performance improvement: 30-40% faster than standard Playwright

**Priority**: P1 (High)

---

#### US-4.3: LLM-as-Judge for Task Validation
**As a** system operator
**I want** automated validation of web agent task success
**So that** I can monitor reliability without manual checks

**Acceptance Criteria**:
- After task completion, LLM judges success (binary + reasoning)
- Judgment prompt includes: original task, final state, extracted data
- Success rate is logged for analytics
- Failed tasks trigger alerts if failure rate >10%

**Priority**: P2 (Medium)

---

### Epic 5: Cost Optimization

#### US-5.1: Hard Budget Limits
**As a** finance manager
**I want** enforceable budget limits per user/team/period
**So that** spending never exceeds approved amounts

**Acceptance Criteria**:
- Redis budget pools track: daily, weekly, monthly spending
- Pre-flight checks reject requests that would exceed limit
- Utilization alerts at 80%, 90%, 95%
- Budget resets automatically (daily at midnight, weekly on Monday, etc.)
- Per-user and per-team budget configuration
- Grace period of 5% overage allowed (with warnings)

**Priority**: P0 (Critical)

---

#### US-5.2: Streaming with Early Termination
**As a** system operator
**I want** LLM responses to stream and terminate early when task is complete
**So that** we save 15-30% on unnecessary token generation

**Acceptance Criteria**:
- All LLM calls stream by default
- Early termination detects: "DONE", "Task completed", code block closures
- Streaming updates UI in real-time
- Cost savings of ≥15% in A/B test
- Termination is logged with reason

**Priority**: P1 (High)

---

### Epic 6: Multi-Agent Coordination

#### US-6.1: Message-Driven Agent Architecture
**As a** system architect
**I want** agents to communicate via events instead of synchronous calls
**So that** 10+ agents can run concurrently without blocking

**Acceptance Criteria**:
- EventEmitter-based coordinator with message queue
- Broadcast and direct message routing
- Message persistence for replay/debugging
- Throughput: ≥1000 messages/sec
- Coordination latency: <100ms per hop
- Supports 10+ concurrent agents (vs 3-4 with sync)

**Priority**: P1 (High)

---

#### US-6.2: Agent Workbench with Tool Composition
**As a** developer
**I want** agents to dynamically compose tools from registry + MCP servers
**So that** I can extend capabilities without hardcoding dependencies

**Acceptance Criteria**:
- Workbench registration API for tools and MCP servers
- Automatic capability discovery from MCP servers
- Privacy filtering (exclude external tools in privacy mode)
- Tool usage analytics (frequency, cost, latency)
- Tool dependency resolution
- Hot-reload for new tool registrations

**Priority**: P1 (High)

---

## Functional Requirements

### Category: Core RAG Pipeline

#### FR-1: Document Ingestion (P0)
System MUST accept PDF, Markdown, TXT, DOCX documents for indexing.

#### FR-2: Text Extraction (P0)
System MUST extract text from documents preserving structure (headings, lists, tables).

#### FR-3: Hybrid Chunking (P0)
System MUST chunk documents using semantic similarity with configurable threshold (default: 0.7).

#### FR-4: Embedding Generation (P0)
System MUST generate embeddings using Tier 0 models (nomic-embed-text or equivalent).

#### FR-5: Vector Storage (P0)
System MUST store embeddings in Qdrant with metadata (doc_name, page, chunk_id, doc_type, created_at).

#### FR-6: Hybrid Search (P0)
System MUST combine semantic (Qdrant) + keyword (BM25) search with configurable weights.

#### FR-7: Reranking (P1)
System MUST rerank top-20 candidates to select best top-5 using cross-encoder.

#### FR-8: Metadata Filtering (P2)
System MUST support pre-retrieval filtering on: doc_type, date_range, source, privacy_level.

#### FR-9: Context Compression (P0)
System MUST compress context to <8k tokens before Tier 3 calls using Tier 0 summarization.

#### FR-10: Citation Tracking (P0)
System MUST return source citations with every answer (doc_name, page, chunk_id, score).

---

### Category: LLM Orchestration

#### FR-11: Provider Abstraction (P0)
System MUST support pluggable LLM providers: Ollama, Fireworks, Together, Anthropic, OpenAI, Jan.

#### FR-12: Tier-Based Routing (P0)
System MUST route queries based on complexity:
- Tier 0 (45%): Simple tasks, privacy mode
- Tier 1 (35%): Medium complexity
- Tier 2 (5%): Vision tasks
- Tier 3 (13%): Planning, review, complex reasoning
- Tier 4 (2%): Batch operations ≥50 items

#### FR-13: Health Monitoring (P0)
System MUST check provider health every 5 minutes with 5-minute cache.

#### FR-14: Automatic Failover (P0)
System MUST failover to backup provider within 2 seconds of failure detection.

#### FR-15: Circuit Breaker (P0)
System MUST open circuit after 3 consecutive failures, retry after 30 seconds.

#### FR-16: Retry Logic (P0)
System MUST retry failed calls with exponential backoff: 2s, 4s, 8s, 16s (max 4 attempts).

#### FR-17: Timeout Enforcement (P0)
System MUST enforce timeouts: Tier 0/1 (10s), Tier 2 (30s), Tier 3 (60s), Tier 4 (300s).

#### FR-18: Streaming Support (P1)
System MUST stream LLM responses by default with early termination detection.

---

### Category: Privacy & Compliance

#### FR-19: Privacy Mode Toggle (P0)
System MUST provide per-session privacy mode toggle in web UI.

#### FR-20: Privacy Routing (P0)
System MUST block Tier 1/3/4 calls when privacy mode is enabled (only Tier 0/2 allowed).

#### FR-21: MCP Filesystem Server (P0)
System MUST deploy MCP filesystem server with path whitelisting and operation filtering.

#### FR-22: MCP Git Server (P0)
System MUST deploy MCP git server for local repository access (read, search, log only).

#### FR-23: MCP Memory Server (P0)
System MUST deploy MCP memory server for in-process knowledge graph (local persistence).

#### FR-24: Jan Integration (P1)
System MUST integrate Jan on localhost:1337 as OpenAI-compatible local API.

#### FR-25: Audit Logging (P0)
System MUST log all tool invocations in privacy mode to local encrypted append-only log.

#### FR-26: Data Residency (P0)
System MUST guarantee no data exfiltration in privacy mode (all processing local).

#### FR-27: Privacy Indicator (P0)
System MUST display clear "Privacy Mode Active" badge in UI when enabled.

---

### Category: Observability & LLMOps

#### FR-28: Invocation Logging (P0)
System MUST log ALL LLM invocations to PostgreSQL with: trace_id, timestamp, user_id, tier, model, prompt_tokens, completion_tokens, cost, latency_ms, success, error, task_type, privacy_mode.

#### FR-29: Real-Time Cost Tracking (P0)
System MUST track costs in Redis with real-time updates per tier and user.

#### FR-30: Cost Dashboard (P0)
System MUST provide dashboard showing: daily/weekly/monthly spending, per-tier breakdown, per-user attribution.

#### FR-31: Historical Analysis (P1)
System MUST enable historical analysis of 30 days of invocation data.

#### FR-32: Tier Optimization (P1)
System MUST recommend optimal tier per task_type based on historical success_rate and cost.

#### FR-33: A/B Testing Framework (P2)
System MUST support A/B testing of workflow versions with sample size and statistical significance.

#### FR-34: Alerting (P0)
System MUST alert on: cost spike (>2x daily average), error rate >5%, latency p95 >10s, provider failure.

---

### Category: Cost Management

#### FR-35: Budget Pool Creation (P0)
System MUST allow creation of budget pools: user_id + period (daily/weekly/monthly) + limit (USD).

#### FR-36: Budget Enforcement (P0)
System MUST reject requests that would exceed budget limit with clear error message.

#### FR-37: Budget Alerts (P0)
System MUST send alerts at 80%, 90%, 95% budget utilization.

#### FR-38: Budget Reset (P0)
System MUST auto-reset budgets: daily (midnight UTC), weekly (Monday 00:00), monthly (1st 00:00).

#### FR-39: Cost Estimation (P1)
System MUST estimate cost before execution based on tier and input token count.

#### FR-40: Grace Period (P2)
System MUST allow 5% budget overage with warnings before hard block.

---

### Category: Web Agent

#### FR-41: Playwright Stealth (P1)
System MUST use Playwright with stealth plugin to prevent webdriver detection.

#### FR-42: Fingerprint Randomization (P1)
System MUST randomize: user agent, viewport dimensions, canvas fingerprint on every session.

#### FR-43: Tracker Blocking (P1)
System MUST block requests to: google-analytics.com, facebook.com/tr, doubleclick.net, googletagmanager.com.

#### FR-44: LLM Action-Perception Loop (P1)
System MUST implement autonomous browsing: observe page → LLM decides action → execute → repeat until done (max 10 iterations).

#### FR-45: LLM-as-Judge (P2)
System MUST validate task success using LLM judgment after completion.

#### FR-46: Session Persistence (P2)
System MUST persist cookies and auth state across browsing sessions.

---

### Category: Multi-Agent Coordination

#### FR-47: Message Coordinator (P1)
System MUST implement event-driven agent coordinator with broadcast and direct routing.

#### FR-48: Message Persistence (P2)
System MUST persist messages for replay and debugging.

#### FR-49: Agent Workbench (P1)
System MUST provide workbench API for dynamic tool registration.

#### FR-50: MCP Auto-Discovery (P1)
System MUST automatically discover and register MCP server capabilities as tools.

#### FR-51: Tool Registry (P1)
System MUST maintain centralized tool registry with: id, name, description, category, privacy_compatible, requires (dependencies).

#### FR-52: Privacy Filtering (P1)
System MUST filter tools based on privacy mode (exclude external APIs when privacy=true).

---

### Category: UI/UX

#### FR-53: Web Chat Interface (P0)
System MUST provide web-based chat interface for Q&A.

#### FR-54: Privacy Mode Toggle (P0)
System MUST provide prominent privacy mode toggle with visual feedback.

#### FR-55: Cost Display (P0)
System MUST display: estimated cost (pre-query), real-time cost (streaming), final cost (post-query).

#### FR-56: Budget Dashboard (P0)
System MUST display: current spend, budget limit, remaining balance, utilization bar (green/yellow/red).

#### FR-57: Source Citations (P0)
System MUST display clickable source citations with document preview.

#### FR-58: Confidence Score (P0)
System MUST display answer confidence (0-100%) with visual indicator.

#### FR-59: Streaming Response (P1)
System MUST stream LLM responses in real-time with typewriter effect.

#### FR-60: Error Messages (P0)
System MUST provide clear, actionable error messages (e.g., "Budget exceeded. Please increase limit or wait until tomorrow.").

---

### v4.2 Enhanced Requirements (FR-166 to FR-225)

*[From v4.2 Enhancement Plan - 60 additional requirements organized by category]*

#### Category: LLMOps Observability (FR-166 to FR-177)

**FR-166**: PostgreSQL database for LLM invocation history with 30-day retention policy.

**FR-167**: Real-time cost aggregation via Redis counters per tier and user.

**FR-168**: Automated tier recommendation based on historical performance (success_rate, avg_cost, avg_latency).

**FR-169**: Weekly cost/performance reports via email or webhook.

**FR-170**: Centralized tool registry with metadata: id, name, description, category, privacy_compatible, requires, cost_tier.

**FR-171**: Privacy mode MUST automatically filter non-compatible tools from agent availability.

**FR-172**: Dynamic tool loading based on agent type and execution context.

**FR-173**: Tool usage analytics: frequency, cost attribution, latency percentiles.

**FR-174**: Version control for n8n workflows stored in PostgreSQL with change tracking.

**FR-175**: A/B testing framework with configurable sample sizes (default: 100).

**FR-176**: Statistical significance calculation (p-value) for A/B test results.

**FR-177**: Automated rollout of winning workflow versions when p < 0.05 and improvement >5%.

---

#### Category: RAG Pipeline Enhancements (FR-178 to FR-193)

**FR-178**: BM25 keyword search index created alongside Qdrant semantic index.

**FR-179**: Configurable semantic:keyword weight per query type (default: 70:30).

**FR-180**: Hybrid search endpoint exposed in n8n workflow nodes.

**FR-181**: A/B testing of semantic-only vs hybrid search with accuracy metrics.

**FR-182**: Semantic chunking using spaCy sentence embeddings and cosine similarity.

**FR-183**: Document type detection: code, markdown, JSON, plain text with specialized handlers.

**FR-184**: Specialized chunking strategies per document type (code: by function, markdown: by heading, JSON: by object).

**FR-185**: Configurable similarity threshold per Qdrant collection (default: 0.7).

**FR-186**: Cross-encoder reranking for high-value queries (Tier 3).

**FR-187**: Adaptive reranking: always for Tier 3, conditional for Tier 0/1 based on score variance.

**FR-188**: Reranking performance metrics in LLMOps dashboard (latency, precision@k improvement).

**FR-189**: Cost tracking for reranking operations (model inference time × cost rate).

**FR-190**: Document metadata schema: doc_type, created_at, updated_at, source, privacy_level, tags.

**FR-191**: Pre-retrieval filtering UI in web chat with dropdown/autocomplete.

**FR-192**: Autocomplete suggestions for filter values based on collection metadata.

**FR-193**: Filter analytics: most common filter combinations, impact on result quality.

---

#### Category: Privacy Mode Enhancements (FR-194 to FR-205)

**FR-194**: MCP server deployment: filesystem (port 3001), git (port 3002), memory (port 3003).

**FR-195**: Sandboxed path whitelisting for filesystem MCP server (configurable via YAML).

**FR-196**: Local-only audit logging for privacy compliance: /var/log/mcp-audit.jsonl (encrypted, append-only).

**FR-197**: Encrypted MCP memory persistence with AES-256 encryption at rest.

**FR-198**: Jan deployment on localhost:1337 with model download management.

**FR-199**: OpenAI-compatible API wrapper for Jan integrated with n8n.

**FR-200**: Privacy mode enforcement: block external API calls if Jan is selected as provider.

**FR-201**: Local model download management via Jan UI for Tier 0/2 models.

**FR-202**: Privacy-hardened Playwright with puppeteer-extra-plugin-stealth.

**FR-203**: Fingerprint randomization: user agent rotation (3+ agents), viewport randomization (1920-2120 × 1080-1180), canvas noise injection.

**FR-204**: Tracker blocking via route interception: google-analytics.com, facebook.com/tr, doubleclick.net, googletagmanager.com.

**FR-205**: LLM-as-judge for autonomous browser task validation with success binary + reasoning text.

---

#### Category: Multi-Agent Coordination (FR-206 to FR-213)

**FR-206**: Event-driven agent coordinator using Node.js EventEmitter or equivalent.

**FR-207**: Broadcast and direct message routing with message queue persistence.

**FR-208**: Message persistence in PostgreSQL for replay/debugging (7-day retention).

**FR-209**: Agent lifecycle management: start, stop, restart, health check endpoints.

**FR-210**: Agent workbench with composable tool registration API.

**FR-211**: Automatic MCP capability discovery and registration as tools.

**FR-212**: Privacy-aware tool filtering per agent based on privacy mode state.

**FR-213**: Tool usage analytics: per-tool frequency, cost attribution, latency percentiles.

---

#### Category: Cost Optimization (FR-214 to FR-225)

**FR-214**: Provider abstraction layer with pluggable implementations (Ollama, Fireworks, Anthropic, OpenAI, Jan).

**FR-215**: Health check monitoring with automatic failover (<2s latency).

**FR-216**: Provider-specific cost calculation per invocation (input_tokens × rate + output_tokens × rate).

**FR-217**: Provider performance analytics: latency percentiles, success rate, cost per task.

**FR-218**: Streaming by default for all LLM calls with SSE protocol.

**FR-219**: Early termination detection: "DONE", "Task completed", "```\n\n---" (code block + separator).

**FR-220**: Real-time UI updates during streaming with WebSocket or SSE.

**FR-221**: Streaming usage tracking: tokens_streamed, termination_reason, cost_saved.

**FR-222**: Redis budget pool tracking with atomic operations (MULTI/EXEC).

**FR-223**: Hard limit enforcement: reject requests if current_spend + estimated_cost > limit.

**FR-224**: Budget utilization alerts at 80%, 90%, 95% via email, Slack, or webhook.

**FR-225**: Per-user and per-team budget management with hierarchical limits.

---

## Non-Functional Requirements

### Performance

**NFR-1**: Query Response Time (p95) ≤ 5 seconds from submission to first answer token.

**NFR-2**: RAG Retrieval Latency (p95) ≤ 2 seconds for hybrid search + reranking.

**NFR-3**: Web Agent Task Duration (average) ≤ 15 seconds for standard tasks.

**NFR-4**: Multi-Agent Coordination Latency ≤ 100ms per message hop.

**NFR-5**: LLM Invocation Logging ≤ 10ms overhead per call.

**NFR-6**: Dashboard Load Time ≤ 2 seconds for 30-day historical view.

---

### Reliability

**NFR-7**: System Uptime ≥ 99.9% (max 43 minutes downtime per month).

**NFR-8**: Provider Failover Time ≤ 2 seconds from failure detection to backup provider.

**NFR-9**: Data Persistence: Zero data loss for committed transactions (PostgreSQL, Qdrant).

**NFR-10**: Error Rate ≤ 0.5% for successful queries (excluding user errors).

---

### Scalability

**NFR-11**: Concurrent Users: Support 100+ concurrent users per instance.

**NFR-12**: Concurrent Agents: Support 10+ concurrent agents per workflow.

**NFR-13**: Message Throughput: ≥1000 messages/sec for agent coordinator.

**NFR-14**: Document Corpus Size: Support ≥1 million documents per Qdrant collection.

**NFR-15**: Budget Pool Operations: ≥10,000 budget checks/sec via Redis.

---

### Security

**NFR-16**: Privacy Mode Enforcement: 100% blocking of external APIs when enabled (no bypasses).

**NFR-17**: Audit Logging: Tamper-proof append-only logs with cryptographic signatures.

**NFR-18**: Credential Storage: Encrypted at rest (AES-256) with key rotation every 90 days.

**NFR-19**: MCP Sandboxing: Filesystem access limited to whitelisted paths (no directory traversal).

**NFR-20**: Input Validation: Sanitize all user inputs to prevent injection attacks (SQL, XSS, command).

---

### Compliance

**NFR-21**: GDPR Compliance: Support data subject access requests (DSAR) within 30 days.

**NFR-22**: HIPAA Compliance: Privacy mode meets Safe Harbor provisions for PHI processing.

**NFR-23**: SOC 2 Type II: Audit trail for all data access and modifications.

**NFR-24**: Data Retention: Configurable retention policies (default: 30 days for logs, indefinite for documents).

---

### Maintainability

**NFR-25**: Code Coverage: ≥80% for critical paths (RAG, LLM routing, privacy enforcement).

**NFR-26**: Documentation: All public APIs documented with OpenAPI 3.0 specification.

**NFR-27**: Deployment Time: Zero-downtime blue-green deployments with automated rollback.

**NFR-28**: Monitoring: Prometheus metrics exported for all critical components.

---

### Usability

**NFR-29**: Onboarding Time: New users can submit first query within 5 minutes of account creation.

**NFR-30**: Error Messages: All errors include actionable remediation steps.

**NFR-31**: Accessibility: Web UI meets WCAG 2.1 Level AA standards.

**NFR-32**: Mobile Support: Responsive design for tablets (landscape) and desktops.

---

## Acceptance Criteria

### Phase 1: Critical Foundations (Week 1-2)

**AC-1.1**: LLMOps observability dashboard displays real-time metrics for last 24 hours.

**AC-1.2**: Hybrid search A/B test shows ≥30% precision@5 improvement vs semantic-only baseline.

**AC-1.3**: MCP filesystem server blocks unauthorized path access (test with ../../../etc/passwd).

**AC-1.4**: Privacy mode blocks 100% of Tier 1/3/4 API calls (zero external requests in network capture).

**AC-1.5**: Provider failover completes within 2 seconds when primary provider is killed.

**AC-1.6**: Budget enforcement rejects requests when daily limit would be exceeded.

---

### Phase 2: Enhanced Intelligence (Week 3-4)

**AC-2.1**: Tool registry dynamically loads MCP server capabilities on startup.

**AC-2.2**: Semantic chunking reduces hallucination rate by ≥25% in blind evaluation.

**AC-2.3**: Reranking improves precision@5 by ≥15% for complex queries.

**AC-2.4**: Jan integration passes OpenAI API compatibility test suite.

**AC-2.5**: Message-driven agents handle 10 concurrent workflows without blocking.

**AC-2.6**: Streaming responses terminate early when "DONE" marker is detected (cost savings logged).

---

### Phase 3: Advanced Features (Week 5-6)

**AC-3.1**: Workflow A/B test shows statistical significance (p < 0.05) after 100 samples.

**AC-3.2**: Metadata filtering reduces search space by ≥50% for filtered queries.

**AC-3.3**: Provider analytics dashboard shows latency percentiles and success rates per provider.

---

### Phase 4: Production Readiness (Week 7-8)

**AC-4.1**: System maintains 99.9% uptime during 7-day load test (1000 queries/hour).

**AC-4.2**: Migration script successfully upgrades v4.1 data to v4.2 schema without data loss.

**AC-4.3**: User acceptance testing (UAT) with 10 users shows ≥4.5/5 satisfaction score.

**AC-4.4**: Security audit finds zero critical vulnerabilities.

---

## Success Metrics

### Accuracy Metrics

| Metric | v4.1 Baseline | v4.2 Target | Measurement |
|--------|--------------|-------------|-------------|
| RAG Precision@5 | 65% | ≥85% | Manual evaluation on 100 test queries |
| RAG Recall@10 | 75% | ≥90% | Manual evaluation on 100 test queries |
| Hallucination Rate | 15% | ≤5% | Blind evaluation by domain experts |
| Web Agent Success | 60% | ≥90% | Automated benchmark task suite |
| Citation Accuracy | 80% | ≥95% | Manual verification of source links |

---

### Performance Metrics

| Metric | v4.1 Baseline | v4.2 Target | Measurement |
|--------|--------------|-------------|-------------|
| Query Latency (p95) | 6.5s | ≤5s | Prometheus histogram |
| RAG Retrieval (p95) | 3.2s | ≤2s | Prometheus histogram |
| Web Agent Duration (avg) | 45s | ≤15s | Automated benchmark |
| Multi-Agent Latency | 8s (sync) | ≤3s (async) | Prometheus histogram |
| Dashboard Load Time | 4s | ≤2s | Lighthouse performance audit |

---

### Cost Metrics

| Metric | v4.1 Baseline | v4.2 Target | Measurement |
|--------|--------------|-------------|-------------|
| Cost per 100 queries | $15.10 | ≤$12.00 | LLMOps cost tracking |
| Privacy mode cost | N/A | $0 API + $75 VPS | Cost dashboard |
| Budget overrun rate | 15% | ≤1% | Audit logs |
| Cost savings (streaming) | 0% | ≥15% | A/B test comparison |

---

### Reliability Metrics

| Metric | v4.1 Baseline | v4.2 Target | Measurement |
|--------|--------------|-------------|-------------|
| System Uptime | 95% | ≥99.9% | Uptime monitoring |
| Error Rate | 2% | ≤0.5% | Error logs aggregation |
| Failover Time | N/A | ≤2s | Synthetic monitoring |
| Provider Availability | 98% | ≥99.5% | Health check logs |

---

### User Satisfaction Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| User Satisfaction (NPS) | ≥50 | Quarterly survey |
| Feature Adoption (Privacy Mode) | ≥30% | Analytics tracking |
| Support Tickets | ≤10/month | Ticketing system |
| Onboarding Completion | ≥80% | Analytics funnel |

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 4.0.0 | 2024-11-15 | Initial specification | Architecture Team |
| 4.1.0 | 2024-11-17 | Added privacy mode, RAG optimization | Architecture Team |
| 4.2.0 | 2025-11-18 | Comprehensive revision based on 8 production systems; added 60 new FRs (FR-166 to FR-225), enhanced NFRs, detailed acceptance criteria | Architecture Team |

---

**Document Status**: ✅ Active
**Next Review**: 2026-11-18
**Stakeholders**: Architecture Team, Product Management, DevOps, Security
**Approval**: Pending
