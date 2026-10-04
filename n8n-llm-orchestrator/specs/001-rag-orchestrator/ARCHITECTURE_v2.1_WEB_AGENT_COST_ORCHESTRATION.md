# Architecture v2.1: Multi-Modal Agent Orchestrator with Web Agent & Cost Orchestration

**Date**: 2025-11-17
**Previous Version**: v2.0 (RAG Orchestrator)
**New Capabilities**: Web Agent, Multi-Tier Cost Orchestration, Modality Routing

---

## Overview

Extension of v2.0 architecture to support:
1. **Web Agent Capabilities**: Browser automation, visual page understanding, multi-step web tasks
2. **Multi-Tier Cost Orchestration**: Dynamic routing across hourly-VRAM vs per-token providers
3. **Modality-Aware Routing**: Text-only, vision, multimodal model selection

---

## Constitution Updates: v2.0 → v2.1

### New Principle: VIII. Cost-Optimized Provider Selection

**Provider Orchestration MUST consider both model capability AND pricing model:**

#### Pricing Model Routing
- **Hourly VRAM Providers** (Salad, RunPod, CloudRift):
  - Use when: Query volume >100/hour (sustained load)
  - Use when: Batch processing (document ingestion, bulk analysis)
  - Use when: Instance already warm (avoid cold start costs)
  - Strategy: Keep instance running, maximize throughput

- **Per-Token Providers** (Fireworks.ai, Together.ai, Replicate):
  - Use when: Query volume <20/hour (bursty traffic)
  - Use when: Single queries, sporadic usage
  - Use when: Need instant response (no cold start)
  - Strategy: Pay-per-use, shutdown when idle

- **Native API Providers** (OpenAI, Anthropic, Google):
  - Use when: Highest quality required (complex reasoning)
  - Use when: Vision/multimodal required
  - Strategy: Reserve for top-tier queries only

#### Model Tier + Modality Matrix

| Use Case | Modality | Model Tier | Provider Options | Pricing Model |
|----------|----------|-----------|------------------|---------------|
| Simple text Q&A | Text-only | Tier 1 | Ollama (local), Gemini Flash | Free/Free |
| Web scraping | Text-only | Tier 1 | Fireworks (Llama 3.1) | Per-token |
| Document analysis | Text-only | Tier 2 | RunPod (Mixtral 8x22B) | Hourly VRAM (if batch) |
| Web page understanding | Vision | Tier 2 | Together.ai (Llama 3.2 Vision) | Per-token |
| Complex reasoning | Text-only | Tier 3 | Claude 3.5 Sonnet | Per-token |
| Web agent w/ screenshots | Vision + Actions | Tier 3 | Claude 3.5 Sonnet, GPT-4V | Per-token |
| Advanced coding | Text-only | Tier 4 | Claude 3 Opus | Per-token |
| Multimodal analysis | Multimodal | Tier 4 | Gemini 1.5 Pro | Per-token |

#### Dynamic Routing Logic

```python
# Pseudocode for cost orchestration
def select_provider(query, modality, complexity, current_load):
    # 1. Check modality requirements
    if modality == "vision":
        eligible_providers = [Together_Llama32V, Claude35, GPT4V, Gemini15Pro]
    elif modality == "text_only":
        eligible_providers = [Ollama, Fireworks_Llama31, RunPod_Mixtral, Claude35]

    # 2. Check complexity tier (from RouteLLM)
    if complexity < 0.3:  # Simple
        tier = [Ollama, Fireworks_Llama31, Gemini_Flash]
    elif complexity < 0.7:  # Medium
        tier = [RunPod_Mixtral, Together_Llama32V, Claude35]
    else:  # Complex
        tier = [Claude_Opus, GPT4_Turbo, Gemini15Pro]

    # 3. Check current load (queries/hour in last hour)
    if current_load > 100:  # High volume
        # Prefer hourly VRAM providers (amortize cost)
        prefer = [RunPod_Mixtral, Salad_Llama31]
        # Start instance if not running
        ensure_instance_warm(prefer[0])
    elif current_load < 20:  # Low volume
        # Prefer per-token providers (no idle cost)
        prefer = [Fireworks, Together_ai]
        # Shutdown hourly instances to save cost
        shutdown_idle_instances()
    else:  # Medium volume
        # Use hybrid: local + per-token
        prefer = [Ollama, Fireworks]

    # 4. Select from intersection of: eligible + tier + preferred
    selected = intersect(eligible_providers, tier, prefer)

    # 5. Fallback chain
    return selected[0] with fallback to selected[1:]
```

#### Cost Tracking & Budget Allocation

- **Budget Pools**:
  - Pool A: Hourly VRAM (fixed cost, pre-allocated hours)
  - Pool B: Per-Token (variable cost, metered usage)
  - Pool C: Premium APIs (reserved for high-value queries)

- **Monitoring**:
  - Track spend per pool in real-time via Helicone
  - Set alerts:
    - "Hourly VRAM instance idle >30min → shutdown"
    - "Per-token spend >$10/day → downgrade to local Ollama"
    - "Premium API spend >$20/month → route via RouteLLM more aggressively"

**Rationale**: Different pricing models require different optimization strategies. Hourly VRAM is cheaper for batch/sustained load, per-token is cheaper for sporadic queries. System MUST route intelligently based on current workload patterns.

---

## Model Provider Matrix (Expanded)

### Tier 1: Local & Free (Cost: $0)
- **Ollama** (local): Llama 3.1 8B, Mistral 7B (text-only)
- **Gemini Flash** (API): Free tier, fast, text-only
- **Use**: 70% of queries (simple factual, formatting)

### Tier 2: Cost-Optimized Hosting (Cost: $0.10-0.30/M tokens OR $0.30-0.80/hour)
- **Fireworks.ai**: Llama 3.1 70B ($0.20/M), Mixtral 8x7B ($0.15/M) - *per-token*
- **Together.ai**: Llama 3.2 Vision 11B ($0.18/M), Mixtral 8x22B ($0.30/M) - *per-token*
- **Replicate**: Various models, pay-per-run - *per-token*
- **RunPod**: Mixtral 8x22B ($0.59/hour for 24GB GPU) - *hourly VRAM*
- **Salad**: Llama 3.1 70B ($0.45/hour for 48GB GPU) - *hourly VRAM*
- **CloudRift**: Custom models ($0.35-1.20/hour depending on GPU) - *hourly VRAM*
- **Use**: 20% of queries (medium reasoning, vision)

### Tier 3: Premium APIs (Cost: $3-15/M tokens)
- **Claude 3.5 Sonnet**: $3/M input, $15/M output (best for reasoning)
- **GPT-4 Turbo**: $10/M input, $30/M output (good for coding)
- **Gemini 1.5 Pro**: $3.50/M input, $10.50/M output (multimodal, long context)
- **Use**: 8% of queries (complex reasoning, coding)

### Tier 4: Ultra-Premium (Cost: $15-75/M tokens)
- **Claude 3 Opus**: $15/M input, $75/M output (best quality)
- **GPT-4o**: $5/M input, $15/M output (multimodal)
- **Use**: 2% of queries (critical decisions, advanced analysis)

---

## Web Agent Architecture (NEW)

### Core Components

#### Browser Automation Layer
- **Browser-Use** (preferred) or **Playwright MCP**
  - Headless Chrome/Firefox via MCP protocol
  - Actions: navigate, click, type, select, submit, screenshot
  - State management: cookies, sessions, localStorage
  - n8n integration via HTTP Request to MCP server

#### Vision Understanding
- **Claude 3.5 Sonnet** or **GPT-4 Vision** (via aisuite)
  - Screenshot analysis: identify buttons, forms, links
  - Page layout understanding
  - Error detection and validation
  - Fallback: Together.ai Llama 3.2 Vision (cheaper for simple pages)

#### Action Planning
- **Multi-step workflow orchestration** (n8n visual workflows)
  - Decompose task: "Book flight NYC→SF" → [navigate, search, compare, select, checkout]
  - State persistence: Save progress between steps
  - Error recovery: Retry with alternative strategy

### Request Flow: Web Agent Task

```
User: "Find cheapest laptop under $1000 on Amazon and add to cart"
    ↓
n8n Workflow: Web Agent Task
    ↓
Task Decomposition (RouteLLM → Claude 3.5 Sonnet)
  - Step 1: Navigate to amazon.com
  - Step 2: Search "laptop under 1000"
  - Step 3: Sort by price (low to high)
  - Step 4: Analyze top 3 results (screenshot)
  - Step 5: Select cheapest with good reviews
  - Step 6: Add to cart
    ↓
Execution Loop (n8n + Browser-Use MCP + Vision LLM):
  For each step:
    - Browser-Use: Execute action (navigate, click, type)
    - Screenshot: Capture page state
    - Vision LLM (RouteLLM decides: Llama 3.2 Vision OR Claude 3.5):
      - Analyze page
      - Verify action succeeded
      - Identify next element (button/form)
    - If error: Retry or escalate to human
    - Log action to MCPcat + OpenTelemetry
    ↓
Return: Confirmation + screenshot + trace
```

### New Functional Requirements: Web Agent

#### Browser Control (FR-056 to FR-065)
- **FR-056**: System MUST support browser automation via Browser-Use or Playwright MCP
- **FR-057**: System MUST capture screenshots for visual page analysis
- **FR-058**: System MUST identify interactive elements (buttons, forms, links) via vision models
- **FR-059**: System MUST execute actions (click, type, select, submit) on web pages
- **FR-060**: System MUST handle navigation (forward, back, new tab, close tab)
- **FR-061**: System MUST manage browser state (cookies, session, localStorage)
- **FR-062**: System MUST support multi-step web workflows with state persistence between steps
- **FR-063**: System MUST handle CAPTCHAs with human escalation (no automated bypass)
- **FR-064**: System MUST log all browser actions to MCPcat for audit trail
- **FR-065**: Browser failures MUST NOT crash workflows (graceful degradation with retry)

#### Vision & Page Understanding (FR-066 to FR-070)
- **FR-066**: System MUST analyze page screenshots with vision-capable LLM (Claude/GPT-4V/Llama 3.2 Vision)
- **FR-067**: System MUST extract structured data from visual elements (tables, cards, product listings)
- **FR-068**: System MUST identify form fields and required inputs from page layout
- **FR-069**: System MUST detect error messages and validation failures visually
- **FR-070**: System MUST adapt to page layout changes (retry with alternative selectors)

#### Multi-Step Task Orchestration (FR-071 to FR-075)
- **FR-071**: System MUST decompose complex tasks into sequential steps via planning LLM
- **FR-072**: System MUST persist workflow state between steps (resume on failure)
- **FR-073**: System MUST implement retry logic with exponential backoff for failed actions
- **FR-074**: System MUST escalate to human when stuck (after 3 failed retries)
- **FR-075**: System MUST provide execution trace with screenshots for each step

#### Cost-Optimized Provider Selection (FR-076 to FR-085)
- **FR-076**: System MUST track query volume per hour to determine pricing model preference
- **FR-077**: System MUST route high-volume workloads (>100 queries/hour) to hourly VRAM providers
- **FR-078**: System MUST route low-volume workloads (<20 queries/hour) to per-token providers
- **FR-079**: System MUST start hourly VRAM instances only when cost-effective (volume threshold met)
- **FR-080**: System MUST shutdown idle hourly instances after 30 minutes of inactivity
- **FR-081**: System MUST maintain separate budget pools for hourly vs per-token providers
- **FR-082**: System MUST log provider selection rationale (pricing model, volume, cost projection)
- **FR-083**: System MUST support manual override for provider selection per workflow
- **FR-084**: System MUST implement cost alerts when budget thresholds exceeded (per pool)
- **FR-085**: System MUST select vision models based on modality requirements (text vs vision vs multimodal)

---

## Updated Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User Interface                               │
│  (Webhook API / n8n Web UI / Future: Web Dashboard)                 │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    n8n Visual Workflows                              │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐ │
│  │ Document RAG    │  │  Web Agent       │  │  Multi-Agent       │ │
│  │ Workflow        │  │  Workflow        │  │  Orchestration     │ │
│  └─────────────────┘  └──────────────────┘  └────────────────────┘ │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ↓                 ↓                 ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│  RouteLLM    │  │ Workload     │  │  Modality        │
│  Complexity  │  │ Analyzer     │  │  Detector        │
│  Scoring     │  │ (vol/hour)   │  │  (text/vision)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                         ↓
        ┌────────────────────────────────────┐
        │  Cost Orchestration Engine (NEW)   │
        │  - Pricing model selection         │
        │  - Budget pool management          │
        │  - Instance lifecycle control      │
        └────────────────┬───────────────────┘
                         │
                         ↓
                  ┌─────────────┐
                  │  aisuite    │
                  │  Unified    │
                  │  LLM API    │
                  └──────┬──────┘
                         │
                         ↓
                  ┌─────────────┐
                  │  Helicone   │
                  │  Proxy      │
                  │  (cache)    │
                  └──────┬──────┘
                         │
        ┌────────────────┼────────────────┬──────────────┬──────────────┐
        │                │                │              │              │
        ↓                ↓                ↓              ↓              ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────┐ ┌─────────┐
│ Local Ollama │ │ Hourly VRAM  │ │ Per-Token    │ │Premium  │ │ Ultra   │
│ (Tier 1)     │ │ Providers    │ │ Providers    │ │ APIs    │ │Premium  │
│              │ │ (Tier 2)     │ │ (Tier 2)     │ │(Tier 3) │ │(Tier 4) │
├──────────────┤ ├──────────────┤ ├──────────────┤ ├─────────┤ ├─────────┤
│ - Llama 3.1  │ │ - RunPod     │ │ - Fireworks  │ │- Claude │ │- Opus   │
│ - Mistral    │ │ - Salad      │ │ - Together   │ │  3.5    │ │- GPT-4o │
│              │ │ - CloudRift  │ │ - Replicate  │ │- GPT-4  │ │         │
│ $0/query     │ │ $0.30-1/hr   │ │ $0.10-0.30/M │ │$3-15/M  │ │$15-75/M │
└──────────────┘ └──────────────┘ └──────────────┘ └─────────┘ └─────────┘

        ┌────────────────────────────────────────────────────────┐
        │          Data & Retrieval Layer                        │
        ├──────────────┬──────────────────┬─────────────────────┤
        │ Qdrant       │ PageIndex MCP    │ Browser-Use MCP     │
        │ (vectors)    │ (vectorless RAG) │ (web automation)    │
        └──────────────┴──────────────────┴─────────────────────┘

        ┌────────────────────────────────────────────────────────┐
        │          Observability Stack                           │
        ├──────────────┬──────────────────┬─────────────────────┤
        │OpenTelemetry │ LangSmith/       │ MCPcat + Helicone   │
        │(traces)      │ Langfuse (logs)  │ (cost + metrics)    │
        └──────────────┴──────────────────┴─────────────────────┘
```

---

## Docker Compose Services (v2.1)

```yaml
version: '3.8'

services:
  # === Orchestration Layer ===
  n8n:
    image: n8nio/n8n:latest
    ports: ["5678:5678"]
    environment:
      - N8N_EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on: [redis]

  # === LLM Interface & Routing ===
  aisuite:
    image: aisuite/aisuite:latest
    ports: ["8000:8000"]
    env_file: .env
    volumes:
      - ./configs/aisuite-config.yaml:/config.yaml

  routellm:
    image: routellm/routellm:latest
    ports: ["8001:8001"]
    volumes:
      - ./configs/routellm-config.yaml:/config.yaml

  helicone:
    image: helicone/helicone:latest
    ports: ["8002:8002"]
    environment:
      - HELICONE_API_KEY=${HELICONE_API_KEY}

  # === Cost Orchestration Engine (NEW) ===
  cost-orchestrator:
    build: ./services/cost-orchestrator
    ports: ["8010:8010"]
    environment:
      - HOURLY_PROVIDERS=runpod,salad,cloudrift
      - TOKEN_PROVIDERS=fireworks,together,replicate
      - VOLUME_THRESHOLD_HIGH=100  # queries/hour
      - VOLUME_THRESHOLD_LOW=20
      - IDLE_SHUTDOWN_MINUTES=30
    volumes:
      - ./configs/provider-pricing.yaml:/pricing.yaml

  # === Hourly VRAM Provider Controllers (NEW) ===
  runpod-controller:
    image: runpod/sdk:latest
    environment:
      - RUNPOD_API_KEY=${RUNPOD_API_KEY}
      - GPU_TYPE=NVIDIA_A40
      - IMAGE=runpod/pytorch:2.0.1-py3.10-cuda11.8.0

  # === Local LLM ===
  ollama:
    image: ollama/ollama:latest
    ports: ["11434:11434"]
    volumes:
      - ollama_models:/root/.ollama

  # === Data & Retrieval ===
  qdrant:
    image: qdrant/qdrant:latest
    ports: ["6333:6333", "6334:6334"]
    volumes:
      - qdrant_storage:/qdrant/storage

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  # === Web Agent (NEW) ===
  browser-use-mcp:
    image: playwright:latest  # or browser-use specific image
    ports: ["8004:8004"]
    volumes:
      - /dev/shm:/dev/shm
    environment:
      - DISPLAY=:99
      - HEADLESS=true
    cap_add:
      - SYS_ADMIN

  # === Observability ===
  otel-collector:
    image: otel/opentelemetry-collector:latest
    ports: ["4317:4317", "4318:4318"]
    volumes:
      - ./configs/otel-config.yaml:/etc/otel/config.yaml

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports: ["16686:16686", "14268:14268"]

  langfuse:
    image: langfuse/langfuse:latest
    ports: ["3000:3000"]
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/langfuse
    depends_on: [postgres]

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=langfuse
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mcpcat:
    image: mcpcat/mcpcat:latest
    ports: ["8003:8003"]

volumes:
  n8n_data:
  ollama_models:
  qdrant_storage:
  postgres_data:
```

---

## Configuration: Provider Pricing Matrix

`configs/provider-pricing.yaml`:

```yaml
providers:
  # Local (free)
  ollama:
    type: local
    cost_per_query: 0
    modalities: [text]
    models:
      - llama3.1:8b
      - mistral:7b

  # Hourly VRAM Providers
  runpod:
    type: hourly_vram
    cost_per_hour: 0.59
    gpu: NVIDIA_A40_48GB
    modalities: [text, vision]
    models:
      - mixtral-8x22b
      - llama-3.1-70b
    startup_time_seconds: 180
    idle_shutdown_minutes: 30

  salad:
    type: hourly_vram
    cost_per_hour: 0.45
    gpu: NVIDIA_A100_40GB
    modalities: [text]
    models:
      - llama-3.1-70b
    startup_time_seconds: 120

  cloudrift:
    type: hourly_vram
    cost_per_hour: 0.89
    gpu: NVIDIA_A6000_48GB
    modalities: [text, vision]
    models:
      - custom_mixtral

  # Per-Token Providers
  fireworks:
    type: per_token
    cost_per_million_input: 0.20
    cost_per_million_output: 0.20
    modalities: [text]
    models:
      - llama-3.1-70b
      - mixtral-8x7b

  together:
    type: per_token
    cost_per_million_input: 0.18
    cost_per_million_output: 0.18
    modalities: [text, vision]
    models:
      - llama-3.2-vision-11b
      - mixtral-8x22b

  replicate:
    type: per_run
    cost_per_run: 0.001
    modalities: [text, vision]

  # Premium APIs
  anthropic:
    type: per_token
    cost_per_million_input: 3.00
    cost_per_million_output: 15.00
    modalities: [text, vision]
    models:
      - claude-3-5-sonnet
      - claude-3-opus

  openai:
    type: per_token
    cost_per_million_input: 10.00
    cost_per_million_output: 30.00
    modalities: [text, vision]
    models:
      - gpt-4-turbo
      - gpt-4o

  google:
    type: per_token
    cost_per_million_input: 3.50
    cost_per_million_output: 10.50
    modalities: [text, vision, multimodal]
    models:
      - gemini-1.5-pro
      - gemini-flash

# Routing Thresholds
routing:
  high_volume_threshold: 100  # queries/hour
  low_volume_threshold: 20
  hourly_warmup_threshold: 50  # Start instance if projected >50 queries in next hour

  # Budget pools (monthly)
  budget_pools:
    hourly_vram: 100.00  # $100/month for hourly instances
    per_token: 50.00     # $50/month for per-token APIs
    premium: 30.00       # $30/month for premium APIs

  # Alert thresholds
  alerts:
    hourly_idle_minutes: 30
    token_spend_daily: 10.00
    premium_spend_monthly: 25.00
```

---

## Implementation Phases (Updated)

### Phase 0: Infrastructure Setup (Week 1)
- Deploy aisuite, RouteLLM, Helicone (from v2.0)
- **NEW**: Deploy Cost Orchestration Engine
- **NEW**: Configure provider pricing matrix
- **NEW**: Set up RunPod/Salad/CloudRift API access
- **NEW**: Set up Fireworks/Together.ai accounts

### Phase 1: Observability Foundation (Week 2)
- OpenTelemetry, Jaeger, LangSmith/Langfuse (from v2.0)
- **NEW**: Extend MCPcat to track provider costs in real-time
- **NEW**: Dashboard for cost per provider per hour

### Phase 2-4: Core RAG (Week 3-5)
- Document ingestion, query processing (from v2.0)
- **NEW**: Integrate cost-aware routing for RAG queries

### Phase 5: Web Agent Foundation (Week 6) **NEW**
- Deploy Browser-Use or Playwright MCP server
- Test basic browser automation (navigate, click, screenshot)
- Integrate vision LLM for page analysis
- Create simple web agent workflow: "Navigate to URL, extract title"

### Phase 6: Web Agent Advanced (Week 7) **NEW**
- Multi-step task orchestration
- Form filling and submission
- Error handling and retry logic
- State persistence between steps
- Example workflow: "Search product on e-commerce site, compare prices"

### Phase 7: Cost Optimization (Week 8) **NEW**
- Implement workload analyzer (query volume tracking)
- Dynamic provider selection based on volume
- Hourly instance lifecycle management (start/stop)
- Budget pool monitoring and alerts
- Tune routing thresholds based on actual usage

### Phase 8: Polish & Production (Week 9)
- End-to-end testing (RAG + Web Agent)
- Performance optimization
- Security hardening
- Documentation

---

## Success Criteria (Extended)

### Web Agent (SC-021 to SC-030)
- **SC-021**: Web agent successfully completes 90%+ of single-step tasks (navigate, click, extract)
- **SC-022**: Web agent successfully completes 70%+ of multi-step tasks (search, compare, select)
- **SC-023**: Screenshot analysis correctly identifies interactive elements 85%+ of the time
- **SC-024**: Web agent handles page layout changes with retry 80%+ success rate
- **SC-025**: Browser failures trigger graceful degradation (no workflow crash) 100% of the time
- **SC-026**: Web agent execution time < 30 seconds for simple tasks (< 5 steps)
- **SC-027**: All browser actions logged to audit trail (100% coverage)
- **SC-028**: CAPTCHA detection triggers human escalation (no automated bypass)
- **SC-029**: Form filling accuracy 95%+ based on visual page analysis
- **SC-030**: Web agent state persistence enables resume after failure 100% of the time

### Cost Orchestration (SC-031 to SC-040)
- **SC-031**: High-volume workloads (>100 q/hr) route to hourly VRAM providers 90%+ of the time
- **SC-032**: Low-volume workloads (<20 q/hr) route to per-token providers 90%+ of the time
- **SC-033**: Hourly instances shutdown after 30 min idle 100% of the time (prevent waste)
- **SC-034**: Cost orchestrator correctly predicts provider cost within 10% margin
- **SC-035**: Budget alerts trigger before exceeding pool limits (95% threshold)
- **SC-036**: Provider selection rationale logged for 100% of queries (auditability)
- **SC-037**: Total monthly cost stays under $180 ($100 hourly + $50 token + $30 premium)
- **SC-038**: Hourly VRAM utilization >80% when instances running (maximize ROI)
- **SC-039**: Vision tasks route to cost-optimal vision models (Llama 3.2 Vision vs Claude 3.5)
- **SC-040**: Manual provider override works 100% of the time when specified

### Business Outcomes (Updated)
- **SC-041**: Web agent reduces manual task time by 80% for repetitive web workflows
- **SC-042**: Combined RAG + Web Agent handles 95% of knowledge work tasks autonomously
- **SC-043**: Cost orchestration reduces total LLM spend by 60% vs naive routing
- **SC-044**: System ROI positive within 3 months (time saved > infrastructure cost)

---

## Next Steps

1. **Update constitution.md** with Principle VIII (Cost-Optimized Provider Selection)
2. **Update spec.md** with new FRs (FR-056 to FR-085) and success criteria (SC-021 to SC-044)
3. **Create cost-orchestrator service** (new microservice for provider selection)
4. **Configure provider pricing matrix** (YAML config for all providers)
5. **Deploy Browser-Use MCP** for web agent capabilities
6. **Test cost routing logic** with simulated workloads

---

## Cost Projection (Monthly)

### Previous (v2.0): $20-30/month
- Mostly Ollama (free)
- Some Claude/GPT-4 for complex queries

### New (v2.1): $150-180/month MAXIMUM (but likely $80-120 actual)

**Budget Allocation**:
- **Hourly VRAM Pool**: $100/month
  - RunPod: ~$0.59/hour × 100 hours = $59 (batch processing)
  - Salad: ~$0.45/hour × 50 hours = $22.50 (sustained workloads)
  - CloudRift: ~$0.89/hour × 20 hours = $17.80 (vision tasks)
  - **Subtotal**: ~$99.30

- **Per-Token Pool**: $50/month
  - Fireworks: ~100K queries × $0.20/M = $20
  - Together.ai: ~50K queries × $0.18/M = $9
  - **Subtotal**: ~$29

- **Premium APIs Pool**: $30/month
  - Claude 3.5 Sonnet: ~500 queries × $0.03 = $15
  - GPT-4 Turbo: ~300 queries × $0.04 = $12
  - **Subtotal**: ~$27

**Grand Total**: ~$155/month (but only if hitting max usage)

**Actual Expected**: $80-120/month based on:
- 70% local Ollama (free)
- 20% hourly VRAM (cost-efficient for batches)
- 8% per-token (bursty traffic)
- 2% premium (critical queries)

**Cost per Query** (at 10K queries/month): **$0.008-0.012** (vs $0.05 without optimization)

---

## Summary

Architecture v2.1 adds:

1. **Web Agent Capabilities**: Full browser automation + vision understanding
2. **Multi-Tier Cost Orchestration**: Intelligent routing across hourly vs per-token providers
3. **Modality-Aware Routing**: Text-only, vision, multimodal model selection
4. **Workload-Based Provider Selection**: Dynamic switching based on query volume
5. **Budget Pool Management**: Separate pools for hourly, per-token, premium APIs
6. **Real-Time Cost Tracking**: Per-provider, per-query cost attribution

**Net Result**:
- **5x capability increase** (RAG + Web Agent)
- **60% cost reduction** vs naive routing
- **$0.01/query** total cost at scale
- **Production-ready observability** across all components

Ready to implement? 🚀
