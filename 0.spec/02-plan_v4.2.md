# Multi-Agent RAG Orchestrator v4.2 - Technical Plan

**Version**: 4.2.0
**Date**: 2025-11-18
**Status**: Active
**Related Documents**:
- [0.constitution_v4.2.md](0.constitution_v4.2.md)
- [01-spec_v4.2.md](01-spec_v4.2.md)
- [v4.2-ENHANCEMENT-PLAN.md](v4.2-ENHANCEMENT-PLAN.md)

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Technology Stack](#technology-stack)
3. [Component Design](#component-design)
4. [Data Architecture](#data-architecture)
5. [Deployment Architecture](#deployment-architecture)
6. [Implementation Strategy](#implementation-strategy)
7. [Technical Decisions](#technical-decisions)

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           USER LAYER                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  Web Chat UI │  │  API Client  │  │  n8n Visual Workflow UI  │  │
│  └───────┬──────┘  └──────┬───────┘  └──────────┬───────────────┘  │
└──────────┼─────────────────┼──────────────────────┼──────────────────┘
           │                 │                      │
┌──────────▼─────────────────▼──────────────────────▼──────────────────┐
│                      ORCHESTRATION LAYER                              │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │             n8n Workflow Engine (Visual Orchestrator)          │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐│   │
│  │  │ Query        │ │ Document     │ │ Multi-Agent            ││   │
│  │  │ Processing   │ │ Ingestion    │ │ Orchestration          ││   │
│  │  └──────────────┘ └──────────────┘ └────────────────────────┘│   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │          Provider Router (Health Check + Failover)             │   │
│  │  Ollama | Fireworks | Together | Anthropic | OpenAI | Jan     │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                        │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │              Agent Coordinator (Message-Driven)                │   │
│  │  EventEmitter → Message Queue → Agent Workbenches              │   │
│  └───────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
           │                 │                      │
┌──────────▼─────────────────▼──────────────────────▼──────────────────┐
│                       INTELLIGENCE LAYER                              │
│                                                                        │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Tier 0: Ollama 70B  │    │  Tier 1: Fireworks/Together      │   │
│  │  (Local, $0)         │    │  ($0.20-0.80/M)                  │   │
│  │  • llama3.1:70b      │    │  • llama-v3p1-8b-instruct        │   │
│  │  • llama3.2:3b       │    │  • qwen2.5-72b-instruct          │   │
│  └──────────────────────┘    └──────────────────────────────────┘   │
│                                                                        │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Tier 2: Ollama Vision│   │  Tier 3: Claude/Gemini           │   │
│  │  (VPS, $0 API)       │    │  ($3-15/M)                       │   │
│  │  • llama3.2-vision   │    │  • claude-3-5-sonnet-20241022    │   │
│  └──────────────────────┘    │  • gemini-2.0-flash-exp          │   │
│                               └──────────────────────────────────┘   │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Tier 4: RunPod/Salad│    │  Jan: Local OpenAI API           │   │
│  │  ($0.69-2/hr)        │    │  (localhost:1337, Privacy Mode)  │   │
│  └──────────────────────┘    └──────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
           │                 │                      │
┌──────────▼─────────────────▼──────────────────────▼──────────────────┐
│                         DATA LAYER                                    │
│                                                                        │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Qdrant Vector DB    │    │  PostgreSQL (LLMOps + Metadata)   │   │
│  │  • Semantic search   │    │  • llm_invocations (30 days)      │   │
│  │  • Hybrid + BM25     │    │  • workflow_versions              │   │
│  │  • Metadata filtering│    │  • agent_messages (7 days)        │   │
│  └──────────────────────┘    └──────────────────────────────────┘   │
│                                                                        │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Redis (State)       │    │  MCP Servers (Privacy Tools)      │   │
│  │  • Budget pools      │    │  • Filesystem (localhost:3001)    │   │
│  │  • Cost tracking     │    │  • Git (localhost:3002)           │   │
│  │  • Provider health   │    │  • Memory (localhost:3003)        │   │
│  └──────────────────────┘    └──────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
           │                 │
┌──────────▼─────────────────▼──────────────────────────────────────────┐
│                       OBSERVABILITY LAYER                              │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐   │
│  │  Prometheus Metrics  │    │  Grafana Dashboards               │   │
│  │  • Latency           │    │  • LLMOps Dashboard               │   │
│  │  • Cost              │    │  • Cost Tracking                  │   │
│  │  • Success Rate      │    │  • Provider Health                │   │
│  └──────────────────────┘    └──────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

---

### RAG Pipeline Architecture (v4.2 Enhanced)

```
INPUT: User Query
       │
       ▼
┌──────────────────────────────────────────────┐
│  1. QUERY PREPROCESSING                      │
│  • Normalize whitespace                      │
│  • Extract metadata filters (if any)         │
│  • Privacy mode check                        │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  2. EMBEDDING GENERATION                     │
│  • Tier 0: nomic-embed-text (Ollama)         │
│  • 768-dim vector                            │
│  • Latency: ~50ms                            │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  3. HYBRID SEARCH (NEW in v4.2)              │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ Semantic Search │  │ Keyword Search   │  │
│  │ (Qdrant)        │  │ (BM25)           │  │
│  │ Top-20          │  │ Scores           │  │
│  └────────┬────────┘  └────────┬─────────┘  │
│           │                    │             │
│           └────────┬───────────┘             │
│                    ▼                         │
│           ┌─────────────────┐                │
│           │ Score Combiner  │                │
│           │ 70% semantic +  │                │
│           │ 30% keyword     │                │
│           └────────┬────────┘                │
└────────────────────┼──────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────┐
│  4. METADATA FILTERING (PRE-RETRIEVAL)       │
│  • doc_type filter                           │
│  • date_range filter                         │
│  • source filter                             │
│  • privacy_level filter                      │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  5. RERANKING (NEW in v4.2)                  │
│  • Input: Top-20 candidates                  │
│  • Cross-encoder: ms-marco-MiniLM-L-6-v2     │
│  • Output: Top-5 precise results             │
│  • Adaptive: Tier 3 always, Tier 0/1 if low │
│    confidence variance                       │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  6. CONTEXT COMPRESSION (FOR TIER 3)         │
│  • Input: Top-5 chunks (avg 4000 tokens)     │
│  • Tier 0 summarizes: "Extract relevant to  │
│    query: <query>"                           │
│  • Output: Compressed context (<8k tokens)   │
│  • Cost savings: 84% per RAG query           │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  7. PROMPT AUGMENTATION                      │
│  • System prompt + compressed context        │
│  • User query                                │
│  • Instructions: "Cite sources"              │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  8. LLM GENERATION (TIER ROUTING)            │
│  • Tier 0 (45%): Simple factual queries      │
│  • Tier 1 (35%): Medium complexity           │
│  • Tier 3 (13%): Complex reasoning           │
│  • Streaming with early termination          │
└─────────────┬────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────┐
│  9. RESPONSE FORMATTING                      │
│  • Extract answer                            │
│  • Attach citations (doc, page, chunk_id)    │
│  • Calculate confidence score                │
│  • Log cost and latency                      │
└─────────────┬────────────────────────────────┘
              │
              ▼
OUTPUT: Answer + Citations + Confidence + Cost
```

---

### Multi-Agent Coordination (v4.2 Message-Driven)

```
┌───────────────────────────────────────────────────────────────┐
│               Agent Coordinator (EventEmitter)                 │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Message Queue (Redis Streams)               │ │
│  │  • Broadcast messages: all agents                        │ │
│  │  • Direct messages: specific agent                       │ │
│  │  • Persistence: 7-day retention                          │ │
│  └─────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
         │                │                │                │
         ▼                ▼                ▼                ▼
┌────────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│ Planner Agent  │ │ Coder Agent    │ │ Reviewer Agent │ │ Web Agent      │
│ • Tier 3       │ │ • Tier 1       │ │ • Tier 0       │ │ • Tier 2       │
│ • Creates plan │ │ • Executes code│ │ • Validates    │ │ • Browser auto │
└───────┬────────┘ └───────┬────────┘ └───────┬────────┘ └───────┬────────┘
        │                  │                  │                  │
        ▼                  ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Agent Workbench (Per Agent)                     │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │ Tool Registry│  │ MCP Servers  │  │ Custom Tools       │    │
│  │ • Dynamic    │  │ • Filesystem │  │ • analyze_code()   │    │
│  │   loading    │  │ • Git        │  │ • web_search()     │    │
│  │ • Privacy    │  │ • Memory     │  │ • run_tests()      │    │
│  │   filtering  │  └──────────────┘  └────────────────────┘    │
│  └──────────────┘                                               │
└──────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Core Infrastructure

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **Orchestration** | n8n | 1.x | Visual workflow design, extensive integrations, self-hosted |
| **Container Runtime** | Docker | 24.x | Industry standard, Docker Compose for local dev |
| **Container Orchestration** | Docker Compose | 2.x | Simple multi-container management for self-hosted deployments |
| **Production Orchestration** | Kubernetes | 1.28+ | Scalable production deployments (optional) |

---

### LLM Providers & Inference

| Tier | Provider | Models | Cost | Use Case |
|------|----------|--------|------|----------|
| **0** | Ollama | llama3.1:70b, llama3.2:3b, nomic-embed-text | $0 | Local inference, privacy mode, embeddings |
| **1** | Fireworks AI | llama-v3p1-8b-instruct | $0.20/M | Cost-efficient external API |
| **1** | Together AI | qwen2.5-72b-instruct | $0.80/M | Larger context, higher quality |
| **2** | Ollama | llama3.2-vision:90b | $0 (VPS) | Vision tasks, screenshot analysis |
| **3** | Anthropic | claude-3-5-sonnet-20241022 | $3-15/M | Complex reasoning, planning, review |
| **3** | Google | gemini-2.0-flash-exp | $3-8/M | Large context (1M tokens), multimodal |
| **4** | RunPod | Custom models | $0.69-2/hr | Batch operations ≥50 items |
| **Privacy** | Jan | llama3.1:70b (local) | $0 API | 100% offline, OpenAI-compatible API |

**Abstraction Layer**: LiteLLM + Custom Provider Router (health checks, failover)

---

### Data Storage

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **Vector Database** | Qdrant | 1.7+ | Open-source, Docker-native, hybrid search support |
| **Relational Database** | PostgreSQL | 15.x | LLMOps logging, workflow versioning, agent messages |
| **Cache & State** | Redis | 7.x | Budget pools, cost tracking, provider health, n8n queue mode |
| **Keyword Search** | BM25 (rank_bm25) | Latest | Hybrid search with Qdrant semantic search |

---

### Observability & Monitoring

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **Metrics** | Prometheus | 2.x | Time-series metrics, alerting, industry standard |
| **Dashboards** | Grafana | 10.x | Rich visualizations, Prometheus integration |
| **Logging** | PostgreSQL | 15.x | Structured logging for LLMOps with SQL analytics |
| **Tracing** | OpenTelemetry | 1.x | Distributed tracing (optional for v4.2, planned for v4.3) |

---

### Privacy & Security

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **MCP Servers** | modelcontextprotocol/servers | Latest | Privacy-preserving tool access, sandboxed filesystem |
| **Local API** | Jan | Latest | 100% offline OpenAI-compatible API |
| **Encryption** | AES-256 | N/A | At-rest encryption for credentials, audit logs |
| **TLS** | Let's Encrypt | N/A | HTTPS for web UI and API endpoints |

---

### Web Agent

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| **Browser Automation** | Playwright | 1.40+ | Cross-browser support, modern API, async-first |
| **Stealth Plugin** | puppeteer-extra-plugin-stealth | Latest | Anti-detection, CAPTCHA avoidance |
| **Fingerprinting** | Custom implementation | N/A | Random user agent, viewport, canvas noise |

---

### Development & Deployment

| Component | Technology | Rationale |
|-----------|------------|-----------|
| **Language (n8n nodes)** | JavaScript/TypeScript | n8n native, widespread adoption |
| **Language (services)** | Python 3.11+ | Data science ecosystem, async support |
| **Package Manager (Python)** | uv | Faster than pip, lock file support |
| **Package Manager (Node)** | pnpm | Faster than npm, disk efficient |
| **CI/CD** | GitHub Actions | Free for public repos, native integration |
| **Infrastructure as Code** | Docker Compose | Simple self-hosted deployments |
| **Version Control** | Git + GitHub | Industry standard |

---

## Component Design

### 1. Provider Router (NEW in v4.2)

**Responsibility**: Abstract LLM providers, health monitoring, automatic failover

**Architecture**:
```python
class ProviderRouter:
    def __init__(self):
        self.providers = {}  # name → LLMProvider
        self.tier_mapping = {}  # tier → [provider_names]
        self.health_cache = {}  # provider → (healthy, timestamp)

    async def route_with_failover(self, tier, model, messages, **kwargs):
        providers = self.tier_mapping[tier]

        for provider_name in providers:
            if not await self.check_health(provider_name):
                continue

            try:
                return await self.providers[provider_name].chat(model, messages, **kwargs)
            except Exception as e:
                logger.warning(f"{provider_name} failed: {e}")
                continue

        # All providers failed, fallback to next tier
        if tier < 3:
            logger.error(f"Tier {tier} exhausted, falling back to Tier {tier+1}")
            return await self.route_with_failover(tier + 1, model, messages, **kwargs)

        raise AllProvidersFailedError(f"All providers for tier {tier} failed")

    async def check_health(self, provider_name):
        # Check cache (5-min TTL)
        if provider_name in self.health_cache:
            healthy, timestamp = self.health_cache[provider_name]
            if time.time() - timestamp < 300:
                return healthy

        # Run health check
        provider = self.providers[provider_name]
        healthy = await provider.health_check()

        # Update cache
        self.health_cache[provider_name] = (healthy, time.time())

        return healthy
```

**Interfaces**:
- `LLMProvider` (abstract base class)
  - `async chat_completion(model, messages, **kwargs) → Response`
  - `async health_check() → bool`
  - `get_cost(input_tokens, output_tokens) → float`

**Implementations**:
- `OllamaProvider`
- `FireworksProvider`
- `TogetherProvider`
- `AnthropicProvider`
- `OpenAIProvider`
- `JanProvider`

---

### 2. Hybrid Search Engine (NEW in v4.2)

**Responsibility**: Combine semantic + keyword search for 40-60% accuracy improvement

**Architecture**:
```python
class HybridSearchRAG:
    def __init__(self, qdrant_client, collection_name, semantic_weight=0.7):
        self.qdrant = qdrant_client
        self.collection = collection_name
        self.semantic_weight = semantic_weight
        self.bm25 = None
        self.documents = []

    def index_documents(self, documents):
        # Index for BM25 keyword search
        tokenized = [doc.split() for doc in documents]
        self.bm25 = BM25Okapi(tokenized)
        self.documents = documents

    async def search(self, query, top_k=10, filters=None):
        # 1. Semantic search (Qdrant)
        semantic_results = await self.qdrant.search(
            collection_name=self.collection,
            query_vector=self.embed(query),
            limit=top_k * 2,  # Over-fetch for reranking
            query_filter=filters
        )

        # 2. Keyword search (BM25)
        tokenized_query = query.split()
        bm25_scores = self.bm25.get_scores(tokenized_query)

        # 3. Combine scores
        combined = {}
        for result in semantic_results:
            doc_id = result.id
            semantic_score = result.score  # 0-1
            keyword_score = bm25_scores[doc_id] / max(bm25_scores) if max(bm25_scores) > 0 else 0

            combined[doc_id] = (
                self.semantic_weight * semantic_score +
                (1 - self.semantic_weight) * keyword_score
            )

        # 4. Sort and return
        ranked = sorted(combined.items(), key=lambda x: x[1], reverse=True)[:top_k]
        return [self.documents[doc_id] for doc_id, score in ranked]
```

---

### 3. Budget Enforcer (NEW in v4.2)

**Responsibility**: Hard budget limits with Redis atomic operations

**Architecture**:
```python
class BudgetEnforcer:
    def __init__(self, redis_client):
        self.redis = redis_client

    def create_budget(self, user_id, period, limit_usd):
        key = f"budget:{user_id}:{period}"
        self.redis.set(key, 0)
        self.redis.set(f"{key}:limit", limit_usd)

        # Set expiry
        if period == "daily":
            self.redis.expire(key, 86400)
        elif period == "weekly":
            self.redis.expire(key, 604800)
        elif period == "monthly":
            self.redis.expire(key, 2592000)

    async def check_budget(self, user_id, period, cost):
        key = f"budget:{user_id}:{period}"
        current = float(self.redis.get(key) or 0)
        limit = float(self.redis.get(f"{key}:limit") or 0)

        return (current + cost) <= limit

    async def deduct_budget(self, user_id, period, cost):
        key = f"budget:{user_id}:{period}"

        # Atomic check-and-deduct
        with self.redis.pipeline() as pipe:
            while True:
                try:
                    pipe.watch(key)
                    current = float(pipe.get(key) or 0)
                    limit = float(pipe.get(f"{key}:limit") or 0)

                    if current + cost > limit:
                        raise BudgetExceededError(
                            f"Budget exceeded: ${current:.4f} + ${cost:.4f} > ${limit:.4f}"
                        )

                    pipe.multi()
                    pipe.incrbyfloat(key, cost)
                    pipe.execute()
                    break
                except redis.WatchError:
                    continue  # Retry on concurrent modification
```

---

### 4. Agent Coordinator (NEW in v4.2)

**Responsibility**: Message-driven multi-agent coordination

**Architecture**:
```javascript
const EventEmitter = require('events');

class AgentCoordinator extends EventEmitter {
  constructor(redis) {
    super();
    this.agents = new Map();  // agent_id → agent instance
    this.redis = redis;
  }

  registerAgent(agent) {
    this.agents.set(agent.id, agent);

    // Subscribe to agent's messages
    this.on(`message:${agent.id}`, async (message) => {
      await agent.handleMessage(message);
    });
  }

  async routeMessage(message) {
    const { from, to, content, type, metadata } = message;

    // Log to PostgreSQL
    await this.logMessage(message);

    // Persist to Redis Streams (7-day retention)
    await this.redis.xadd(
      `messages:${to}`,
      'MAXLEN', '~', 10000,
      '*',
      'from', from,
      'content', JSON.stringify(content),
      'type', type
    );

    // Route via EventEmitter
    if (to === 'broadcast') {
      for (const [id, agent] of this.agents) {
        if (id !== from) {
          this.emit(`message:${id}`, message);
        }
      }
    } else {
      this.emit(`message:${to}`, message);
    }
  }

  async executeWorkflow(task, agents = ['planner', 'coder', 'reviewer']) {
    // 1. Send task to planner
    await this.routeMessage({
      from: 'orchestrator',
      to: 'planner',
      type: 'task',
      content: task,
      metadata: { timestamp: Date.now() }
    });

    // 2. Wait for plan completion
    const plan = await new Promise((resolve) => {
      this.once('plan:complete', resolve);
    });

    // 3. Route subtasks to executors (parallel)
    await Promise.all(
      plan.subtasks.map((subtask) =>
        this.routeMessage({
          from: 'planner',
          to: subtask.agent,
          type: 'subtask',
          content: subtask.description,
          metadata: { plan_id: plan.id }
        })
      )
    );

    // 4. Collect results
    const results = await this.collectResults(plan.id);

    // 5. Send to reviewer
    await this.routeMessage({
      from: 'orchestrator',
      to: 'reviewer',
      type: 'review',
      content: results,
      metadata: { plan_id: plan.id }
    });

    return await new Promise((resolve) => {
      this.once('review:complete', resolve);
    });
  }
}
```

---

## Data Architecture

### Database Schema: PostgreSQL

#### llm_invocations Table
```sql
CREATE TABLE llm_invocations (
    id BIGSERIAL PRIMARY KEY,
    trace_id UUID NOT NULL,
    timestamp TIMESTAMP DEFAULT NOW(),
    user_id VARCHAR(255),
    tier INTEGER NOT NULL,
    model VARCHAR(255) NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    cost DECIMAL(10, 6) NOT NULL,
    latency_ms INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    error TEXT,
    task_type VARCHAR(100),
    privacy_mode BOOLEAN DEFAULT FALSE,
    provider VARCHAR(100)
);

CREATE INDEX idx_trace ON llm_invocations(trace_id);
CREATE INDEX idx_user_tier ON llm_invocations(user_id, tier);
CREATE INDEX idx_timestamp ON llm_invocations(timestamp);
CREATE INDEX idx_task_type ON llm_invocations(task_type);
```

#### workflow_versions Table
```sql
CREATE TABLE workflow_versions (
    id UUID PRIMARY KEY,
    workflow_id VARCHAR(255) NOT NULL,
    version INTEGER NOT NULL,
    changes TEXT,
    creator VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    performance_metrics JSONB,
    status VARCHAR(50) DEFAULT 'draft'
);

CREATE INDEX idx_workflow ON workflow_versions(workflow_id, version);
```

#### agent_messages Table
```sql
CREATE TABLE agent_messages (
    id BIGSERIAL PRIMARY KEY,
    from_agent VARCHAR(255) NOT NULL,
    to_agent VARCHAR(255) NOT NULL,
    message_type VARCHAR(100) NOT NULL,
    content JSONB NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_agents ON agent_messages(from_agent, to_agent);
CREATE INDEX idx_timestamp ON agent_messages(timestamp);
```

---

### Vector Database Schema: Qdrant

#### Collection: knowledge_base
```json
{
  "vectors": {
    "size": 768,
    "distance": "Cosine"
  },
  "payload_schema": {
    "doc_name": "keyword",
    "doc_type": "keyword",
    "page": "integer",
    "chunk_id": "integer",
    "source": "keyword",
    "created_at": "datetime",
    "privacy_level": "keyword",
    "tags": "keyword[]"
  }
}
```

---

### Redis Key Patterns

| Key Pattern | Type | Purpose | TTL |
|-------------|------|---------|-----|
| `budget:{user_id}:{period}` | String (float) | Current spend | 24h / 7d / 30d |
| `budget:{user_id}:{period}:limit` | String (float) | Budget limit | Same as above |
| `cost:daily:{tier}` | String (float) | Daily cost per tier | 24h |
| `health:{provider}` | String (JSON) | Provider health status | 5 min |
| `messages:{agent_id}` | Stream | Agent message queue | 7 days |

---

## Deployment Architecture

### Development Environment (Docker Compose)

```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis
      - qdrant

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  qdrant:
    image: qdrant/qdrant:v1.7.4
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=orchestrator
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

  jan:
    image: janhq/jan:latest
    ports:
      - "1337:1337"
    volumes:
      - jan_data:/root/.jan

  mcp-filesystem:
    build: ./mcp-servers/filesystem
    ports:
      - "3001:3001"
    environment:
      - ALLOWED_PATHS=/data/projects,/tmp/workspace
    volumes:
      - ./data/projects:/data/projects

  mcp-git:
    build: ./mcp-servers/git
    ports:
      - "3002:3002"
    environment:
      - ALLOWED_REPOS=/data/repos/*

  mcp-memory:
    build: ./mcp-servers/memory
    ports:
      - "3003:3003"

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  n8n_data:
  ollama_data:
  qdrant_data:
  postgres_data:
  jan_data:
  prometheus_data:
  grafana_data:
```

---

### Production Environment (Kubernetes - Optional)

**High-Level Components**:
- **Ingress**: Nginx Ingress Controller with Let's Encrypt TLS
- **n8n**: StatefulSet with persistent volumes
- **Ollama**: DaemonSet on GPU nodes
- **Qdrant**: StatefulSet with persistent volumes
- **PostgreSQL**: Managed service (AWS RDS, Google Cloud SQL) or StatefulSet
- **Redis**: Managed service (AWS ElastiCache, Google Memorystore) or StatefulSet
- **Prometheus**: Prometheus Operator
- **Grafana**: Deployment with persistent volumes

**Scaling Strategy**:
- n8n: Horizontal scaling with queue mode (Redis)
- Ollama: Vertical scaling (GPU resources) + DaemonSet
- Qdrant: Horizontal sharding (collections)
- PostgreSQL: Read replicas
- Redis: Redis Cluster

---

## Implementation Strategy

### Phase 1: Critical Foundations (Week 1-2)

**Objectives**:
- Establish LLMOps observability
- Implement hybrid search RAG
- Deploy MCP servers for privacy mode
- Harden Playwright for web agents
- Build provider abstraction layer
- Enforce budget limits

**Deliverables**:
1. PostgreSQL schema deployed with llm_invocations table
2. Hybrid search (BM25 + Qdrant) with A/B test showing ≥30% improvement
3. MCP servers (filesystem, git, memory) deployed and tested
4. Playwright with stealth plugin and fingerprint randomization
5. Provider router with health checks and failover
6. Redis budget enforcement with 80/90/95% alerts

**Success Criteria**: AC-1.1 to AC-1.6 (see spec)

---

### Phase 2: Enhanced Intelligence (Week 3-4)

**Objectives**:
- Build tool registry
- Implement semantic chunking
- Add reranking pipeline
- Integrate Jan for privacy mode
- Create message-driven agent coordinator
- Build agent workbenches
- Enable streaming-first design

**Deliverables**:
1. Tool registry API with privacy filtering
2. Semantic chunking with spaCy embeddings
3. Cross-encoder reranking with adaptive logic
4. Jan on localhost:1337 with OpenAI compatibility
5. Agent coordinator with EventEmitter + Redis Streams
6. Agent workbench API with MCP auto-discovery
7. Streaming LLM responses with early termination

**Success Criteria**: AC-2.1 to AC-2.6

---

### Phase 3: Advanced Features (Week 5-6)

**Objectives**:
- Workflow versioning & A/B testing
- Metadata filtering for RAG
- Provider analytics dashboard

**Deliverables**:
1. Workflow version control in PostgreSQL
2. A/B testing framework with statistical significance
3. Metadata filtering UI with autocomplete
4. Provider analytics in Grafana

**Success Criteria**: AC-3.1 to AC-3.3

---

### Phase 4: Production Readiness (Week 7-8)

**Objectives**:
- Integration testing
- Performance optimization
- Security audit
- Documentation
- Migration scripts

**Deliverables**:
1. End-to-end test suite (80% coverage)
2. Load testing report (1000 queries/hour for 7 days)
3. Security audit report (zero critical vulnerabilities)
4. Migration guide v4.1 → v4.2
5. API documentation (OpenAPI 3.0)
6. User training materials

**Success Criteria**: AC-4.1 to AC-4.4

---

## Technical Decisions

### Decision 1: Hybrid Search (Semantic + Keyword)

**Context**: Pure semantic search misses exact keyword matches, reducing precision by 40% for technical queries.

**Options**:
1. **Semantic-only** (v4.1 baseline): Fast, simple, but misses keywords
2. **Hybrid** (v4.2 chosen): Combines semantic + keyword (BM25)
3. **Keyword-only**: Fast, but misses semantic similarity

**Decision**: Hybrid search with 70:30 semantic:keyword weight

**Rationale**:
- Verba production system shows 40-60% precision improvement
- BM25 is lightweight (no GPU required)
- Configurable weighting allows tuning per use case

**Trade-offs**:
- ✅ +40-60% precision improvement
- ✅ Captures both semantic and exact matches
- ❌ +200ms latency for BM25 indexing

---

### Decision 2: PostgreSQL for LLMOps (not Elasticsearch)

**Context**: Need to log all LLM invocations for analytics and cost tracking.

**Options**:
1. **PostgreSQL** (chosen): Relational, SQL analytics, low operational overhead
2. **Elasticsearch**: Full-text search, complex queries, high operational overhead
3. **ClickHouse**: Columnar, fast aggregations, high learning curve

**Decision**: PostgreSQL with 30-day retention

**Rationale**:
- Simple SQL queries for analytics (e.g., `AVG(cost) GROUP BY tier`)
- Low operational overhead (already deployed for n8n)
- JSONB support for flexible metadata
- Mature backup/restore ecosystem

**Trade-offs**:
- ✅ Simple operations and maintenance
- ✅ SQL analytics are straightforward
- ❌ Not ideal for >100M rows (but 30-day retention keeps it small)

---

### Decision 3: Message-Driven Agents (not Synchronous RPC)

**Context**: Synchronous agent calls don't scale beyond 3-4 agents.

**Options**:
1. **Synchronous RPC** (v4.1 baseline): Simple, blocking, doesn't scale
2. **Message-driven** (v4.2 chosen): Async, event-driven, scales to 10+ agents
3. **Actor model** (Akka, Orleans): Complex, high learning curve

**Decision**: EventEmitter + Redis Streams for message passing

**Rationale**:
- AutoGen production system uses message-driven architecture
- EventEmitter is Node.js native (no new dependencies)
- Redis Streams provides persistence and replay

**Trade-offs**:
- ✅ Scales to 10+ concurrent agents
- ✅ Loose coupling enables independent agent development
- ❌ +100ms coordination latency vs synchronous (acceptable)

---

### Decision 4: Jan for Privacy Mode (not only Ollama)

**Context**: Privacy mode requires 100% local execution with OpenAI-compatible API.

**Options**:
1. **Ollama-only** (v4.1 baseline): Direct integration, but non-standard API
2. **Jan** (v4.2 chosen): OpenAI-compatible API, better UX for model management
3. **LocalAI**: Similar to Jan, but less mature

**Decision**: Jan on localhost:1337 as primary privacy provider

**Rationale**:
- OpenAI-compatible API simplifies integration
- Better UI for model download management
- Active community (25k+ GitHub stars)

**Trade-offs**:
- ✅ OpenAI-compatible API (drop-in replacement)
- ✅ Better model management UX
- ❌ Additional service to deploy (+200MB RAM)

---

### Decision 5: Playwright with Stealth (not Puppeteer)

**Context**: Browser automation needs to avoid CAPTCHAs and fingerprinting.

**Options**:
1. **Selenium**: Legacy, slow, easily detected
2. **Puppeteer**: Chrome-only, Google-backed
3. **Playwright** (chosen): Cross-browser, modern API, stealth plugin

**Decision**: Playwright with puppeteer-extra-plugin-stealth

**Rationale**:
- Browser-Use production system uses Playwright
- Cross-browser support (Chromium, Firefox, WebKit)
- Modern async/await API
- Stealth plugin reduces CAPTCHA encounters by 30-40%

**Trade-offs**:
- ✅ Modern API with async/await
- ✅ Cross-browser support
- ✅ 30-40% CAPTCHA reduction
- ❌ Slightly larger binary than Puppeteer

---

## Next Steps

1. ✅ Review this plan with architecture team
2. ⏳ Begin Phase 1 implementation (Week 1-2)
3. ⏳ Set up CI/CD pipelines (GitHub Actions)
4. ⏳ Create development environment (Docker Compose)
5. ⏳ Initialize PostgreSQL schema
6. ⏳ Deploy MCP servers
7. ⏳ Implement provider router
8. ⏳ Build hybrid search prototype

---

**Document Status**: ✅ Active
**Next Review**: 2026-11-18
**Maintainers**: Architecture Team
**Last Updated**: 2025-11-18
