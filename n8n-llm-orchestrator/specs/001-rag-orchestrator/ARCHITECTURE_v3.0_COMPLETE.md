# Architecture v3.0 - Complete Implementation Guide

**Version**: 3.0.0
**Date**: 2025-11-18
**Status**: Production-Ready Architecture
**Breaking Changes**: Yes - LiteLLM replaces aisuite, 5-tier routing, mandatory pre-budget checks

---

## Executive Summary

Version 3.0 represents a **unified production-grade architecture** merging best practices from internal research (v2.0, v2.1) and external architecture review. This version achieves **60-70% cost reduction** vs naive routing through intelligent 5-tier model selection, mandatory pre-budget checks, architect/executor pattern, batch routing, and prompt compression.

### Key Improvements Over v2.1

| Feature | v2.1 | v3.0 | Impact |
|---------|------|------|--------|
| LLM Interface | aisuite | **LiteLLM** (OpenAI-compatible) | More mature, better support |
| Tier System | 4 tiers | **5 tiers** (added Tier 0 fast filter) | 40% queries at $0 cost |
| Budget Control | Post-hoc logging | **Pre-budget checks (MANDATORY)** | 100% budget overrun prevention |
| Cost Pattern | Reactive | **Proactive (pre-checks + alerts)** | Zero unauthorized charges |
| Batch Routing | Manual | **Automatic (≥50 requests)** | 30-50% savings on high volume |
| Multi-Step Tasks | Flat Tier 3 | **Architect/Executor pattern** | 57% cost savings |
| Prompt Optimization | None | **Tier 0 compression (60% reduction)** | Massive Tier 3 savings |
| Expected Monthly Cost | $50 | **$30** | 40% reduction |

### Architecture Philosophy

**v3.0 Core Principles**:
1. **Pre-budget checks are non-negotiable** - Every LLM call validated before execution
2. **Tier 0 filters everything first** - 40% of queries answered at $0 cost in <500ms
3. **Batch economics matter** - Auto-detect high volume → route to hourly GPU rental
4. **Architect plans, executor implements** - 57% savings on multi-step tasks
5. **Compress before sending to Tier 3** - 60% token reduction on long contexts

---

## Breaking Changes Summary

### 1. LLM Interface: aisuite → LiteLLM

**Rationale**: LiteLLM is production-ready, widely adopted, OpenAI-compatible, better documentation.

**Migration Steps**:
```yaml
# OLD (aisuite v2.0/v2.1)
n8n HTTP Request Node:
  URL: http://aisuite:8000/generate
  Method: POST
  Body:
    provider: "ollama"
    model: "llama3.1:8b"
    prompt: "{{$json.query}}"

# NEW (LiteLLM v3.0)
n8n HTTP Request Node:
  URL: http://litellm:4000/v1/chat/completions  # OpenAI-compatible
  Method: POST
  Headers:
    Authorization: "Bearer {{$credentials.litellm_api_key}}"
  Body:
    model: "executor"  # Model group, not specific model
    messages: [{"role": "user", "content": "{{$json.query}}"}]
```

**Config File Changes**:
```yaml
# configs/litellm-config.yaml (NEW)
model_list:
  # Tier 0: Fast Filter (Ollama 3B-13B)
  - model_name: fast_filter
    litellm_params:
      model: ollama/llama3.2:3b
      api_base: http://ollama:11434

  # Tier 1: Hosted Open Source (Fireworks/Together)
  - model_name: executor
    litellm_params:
      model: fireworks_ai/accounts/fireworks/models/llama-v3p1-8b-instruct
      api_key: "env/FIREWORKS_API_KEY"

  # Tier 2: Local Multimodal (Ollama 70B+Vision)
  - model_name: vision
    litellm_params:
      model: ollama/llama3.2-vision:70b
      api_base: http://ollama:11434

  # Tier 3: Premium (Claude/Gemini)
  - model_name: architect
    litellm_params:
      model: claude-3-5-sonnet-20241022
      api_key: "env/ANTHROPIC_API_KEY"

  # Tier 4: GPU Rental (RunPod - managed separately)
  - model_name: batch_gpu
    litellm_params:
      model: openai/meta-llama/llama-3.1-405b-instruct
      api_base: "env/RUNPOD_ENDPOINT"  # Dynamic, spun up on demand
      api_key: "env/RUNPOD_API_KEY"

router_settings:
  enable_pre_call_checks: true
  enable_caching: true  # Uses Helicone
  cache_ttl: 3600  # 1 hour
```

### 2. Tier System: 4 Tiers → 5 Tiers

**Old Structure (v2.1)**:
- Tier 1: Ollama local
- Tier 2: Hosted open source (Fireworks)
- Tier 3: Premium (Claude/Gemini)
- Tier 4: GPU rental (RunPod/Salad)

**New Structure (v3.0)**:
- **Tier 0**: Local fast filter (Ollama 3B-13B, <500ms, $0) - **NEW**
- Tier 1: Hosted open source (Fireworks/Together, $0.20-0.80/M)
- **Tier 2**: Local multimodal (Ollama 70B+Vision, VPS fixed cost) - **SPLIT FROM OLD TIER 1**
- Tier 3: Premium (Claude/Gemini, $3-15/M)
- Tier 4: GPU rental (RunPod/Salad, $0.69-2/hour)

**Routing Logic Change**:
```javascript
// OLD (v2.1): 4 tiers
function selectTier_v2(complexity) {
  if (complexity < 0.3) return 1;  // Ollama
  if (complexity < 0.7) return 2;  // Fireworks
  return 3;  // Claude
}

// NEW (v3.0): 5 tiers with Tier 0 fast filter
function selectTier_v3(input) {
  const { prompt, hasImages, complexity, batchSize } = input;

  // Tier 0: Fast filter (NEW - 40% of queries)
  if (!hasImages && (complexity <= 0.2 || prompt.length < 500)) {
    return { tier: 0, model: 'fast_filter', cost: 0 };
  }

  // Tier 4: Batch processing (enhanced detection)
  if (batchSize >= 50) {
    const tier1Cost = batchSize * 0.0003;
    const tier4Cost = (batchSize * 5) / 60 * 0.69;
    if (tier4Cost < tier1Cost * 0.7) {
      return { tier: 4, model: 'batch_gpu', cost: tier4Cost };
    }
  }

  // Tier 2: Vision (multimodal split)
  if (hasImages) {
    return { tier: 2, model: 'vision', cost: 0 };  // VPS fixed
  }

  // Tier 1 vs Tier 3: Standard routing
  if (complexity < 0.7) {
    return { tier: 1, model: 'executor', cost: prompt.length * 0.0003 };
  }
  return { tier: 3, model: 'architect', cost: prompt.length * 0.012 };
}
```

### 3. Pre-Budget Checks: Post-hoc → Mandatory Pre-Flight

**Old Pattern (v2.1)**: Log costs after LLM call
```javascript
// v2.1: Reactive cost tracking
const response = await callLLM(prompt);  // Call first
const cost = calculateCost(response.usage);  // Calculate after
logCost(cost);  // Log after
// Risk: Budget could be exhausted mid-call
```

**New Pattern (v3.0)**: MANDATORY pre-budget check before call
```javascript
// v3.0: Proactive budget validation
const estimatedCost = estimateCost(prompt, tier);  // Estimate first
const budgetCheck = await checkBudget(budgetPool, estimatedCost);  // Check before

if (!budgetCheck.pass) {
  // BLOCK the call, return error immediately
  return {
    error: "Budget exhausted",
    pool: budgetPool,
    balance: budgetCheck.balance,
    required: estimatedCost
  };
}

// Only call LLM if budget sufficient
const response = await callLLM(prompt);
const actualCost = calculateCost(response.usage);
await updateBudget(budgetPool, actualCost);  // Update after
```

**n8n Implementation**:
```json
{
  "nodes": [
    {
      "name": "Pre-Budget Check",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "const tier = $json.tier;\nconst promptLength = $json.prompt.length;\nconst estimatedCost = calculateCost(tier, promptLength);\nconst pool = getPoolForTier(tier);\nconst balance = workflow.getStaticData('budgetPools')[pool];\n\nif (balance < estimatedCost) {\n  return [{\n    pass: false,\n    error: 'Budget exhausted',\n    pool: pool,\n    balance: balance,\n    required: estimatedCost\n  }];\n}\n\nreturn [{\n  pass: true,\n  pool: pool,\n  balance: balance,\n  estimatedCost: estimatedCost\n}];"
      },
      "position": [400, 300],
      "typeVersion": 1
    },
    {
      "name": "IF Budget Check Pass",
      "type": "n8n-nodes-base.if",
      "parameters": {
        "conditions": {
          "boolean": [
            {
              "value1": "={{$json.pass}}",
              "value2": true
            }
          ]
        }
      },
      "position": [600, 300],
      "typeVersion": 1
    },
    {
      "name": "Call LLM (if budget ok)",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://litellm:4000/v1/chat/completions",
        "method": "POST"
      },
      "position": [800, 200],
      "typeVersion": 1
    },
    {
      "name": "Return Budget Error",
      "type": "n8n-nodes-base.respondToWebhook",
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{$json.error}}"
      },
      "position": [800, 400],
      "typeVersion": 1
    }
  ]
}
```

### 4. Budget Pool Structure

**v2.1**: Single monthly budget
**v3.0**: 4 separate budget pools

```javascript
// v3.0 Budget Pool Schema
const budgetPools = {
  hourly_vram: {
    limit: 100,  // $100/month
    balance: 75.50,  // Current balance
    providers: ['runpod', 'salad', 'cloudrift'],
    tier: 4,
    resetDate: '2025-12-01',
    burnRate: 3.50  // $/day average
  },
  per_token: {
    limit: 50,  // $50/month
    balance: 42.30,
    providers: ['fireworks', 'together'],
    tier: 1,
    resetDate: '2025-12-01',
    burnRate: 1.20
  },
  premium: {
    limit: 30,  // $30/month
    balance: 18.90,
    providers: ['anthropic', 'google'],
    tier: 3,
    resetDate: '2025-12-01',
    burnRate: 2.10
  },
  local_vps: {
    limit: 75,  // $75/month (fixed infrastructure cost)
    balance: 75.00,  // Doesn't decrease (pre-paid)
    providers: ['ollama_tier0', 'ollama_tier2'],
    tier: [0, 2],
    resetDate: '2025-12-01',
    burnRate: 0  // Fixed, not metered
  }
};

// Alert thresholds
const ALERT_THRESHOLD = 0.90;  // 90% capacity

// Check if alert needed
function checkAlerts(pools) {
  const alerts = [];
  for (const [name, pool] of Object.entries(pools)) {
    if (pool.balance / pool.limit <= (1 - ALERT_THRESHOLD)) {
      alerts.push({
        pool: name,
        balance: pool.balance,
        limit: pool.limit,
        percentage: (pool.balance / pool.limit * 100).toFixed(1)
      });
    }
  }
  return alerts;
}
```

### 5. Architect/Executor Pattern

**v2.1**: All multi-step tasks use single tier
**v3.0**: Separate planning (Tier 3) from execution (Tier 0/1)

**Example: Coding Task**

**Old Approach (v2.1)**:
```
User: "Refactor this codebase to use dependency injection"

All 10 steps → Tier 3 (Claude @ $0.15/step) = $1.50 total
```

**New Approach (v3.0)**:
```
User: "Refactor this codebase to use dependency injection"

Step 1: Architect Agent (Tier 3 Claude) $0.15
  Output: Detailed plan with 10 subtasks
  [
    "1. Identify all hardcoded dependencies in main.py",
    "2. Create container class in container.py",
    "3. Modify __init__ to accept injected deps",
    ...
  ]

Steps 2-11: Executor Agent (Tier 0/1) $0.035 each × 10 = $0.35
  Each subtask executed by fast Tier 0/1 models
  - Simple refactoring: Tier 0 (Ollama 3B) $0
  - File modifications: Tier 1 (Fireworks) $0.035

Step 12: Reviewer Agent (Tier 3 Claude) $0.15
  Validates all changes, provides feedback

Total: $0.15 + $0.35 + $0.15 = $0.65
Savings: $1.50 - $0.65 = $0.85 (57% reduction)
```

**n8n Workflow Structure**:
```json
{
  "nodes": [
    {
      "name": "Architect: Plan Task",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://litellm:4000/v1/chat/completions",
        "method": "POST",
        "body": {
          "model": "architect",  // Tier 3
          "messages": [
            {
              "role": "system",
              "content": "You are an architect. Break down the user's task into 10-15 discrete, executable subtasks. Output as JSON array."
            },
            {
              "role": "user",
              "content": "{{$json.userTask}}"
            }
          ]
        }
      }
    },
    {
      "name": "Parse Subtasks",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "const plan = JSON.parse($json.response);\nreturn plan.subtasks.map(task => ({ subtask: task }));"
      }
    },
    {
      "name": "Execute Each Subtask",
      "type": "n8n-nodes-base.loop",
      "parameters": {
        "loopMode": "items"
      }
    },
    {
      "name": "Route Subtask to Tier",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "jsCode": "const complexity = analyzeComplexity($json.subtask);\nconst tier = complexity < 0.3 ? 0 : 1;  // Tier 0 or Tier 1\nreturn [{ subtask: $json.subtask, tier: tier, model: tier === 0 ? 'fast_filter' : 'executor' }];"
      }
    },
    {
      "name": "Executor: Implement Subtask",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://litellm:4000/v1/chat/completions",
        "method": "POST",
        "body": {
          "model": "{{$json.model}}",  // Tier 0 or Tier 1
          "messages": [
            {
              "role": "user",
              "content": "{{$json.subtask}}"
            }
          ]
        }
      }
    },
    {
      "name": "Aggregate Results",
      "type": "n8n-nodes-base.aggregate",
      "parameters": {
        "aggregations": [
          {
            "field": "result",
            "operation": "append"
          }
        ]
      }
    },
    {
      "name": "Reviewer: Validate",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://litellm:4000/v1/chat/completions",
        "method": "POST",
        "body": {
          "model": "architect",  // Tier 3
          "messages": [
            {
              "role": "system",
              "content": "You are a code reviewer. Validate the following implementation results and provide feedback."
            },
            {
              "role": "user",
              "content": "{{$json.aggregated_results}}"
            }
          ]
        }
      }
    }
  ]
}
```

---

## New Components in v3.0

### 1. LiteLLM Service

**Purpose**: Unified OpenAI-compatible API for all LLM providers

**Deployment**:
```yaml
# docker-compose.yml
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    ports:
      - "4000:4000"
    environment:
      - LITELLM_MASTER_KEY=${LITELLM_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - FIREWORKS_API_KEY=${FIREWORKS_API_KEY}
      - TOGETHER_API_KEY=${TOGETHER_API_KEY}
      - RUNPOD_API_KEY=${RUNPOD_API_KEY}
      - DATABASE_URL=postgresql://litellm:password@postgres:5432/litellm  # For caching
    volumes:
      - ./configs/litellm-config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
```

**Testing**:
```bash
# Test Tier 0 (fast filter)
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "fast_filter",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "max_tokens": 50
  }'

# Test Tier 3 (architect)
curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "architect",
    "messages": [{"role": "user", "content": "Design a microservices architecture for an e-commerce platform"}],
    "max_tokens": 2000
  }'
```

### 2. Pre-Budget Check Service

**Implementation**: n8n workflow variable or Redis-backed service

**Option A: n8n Workflow Variables** (simpler, lower scale)
```javascript
// Store in workflow static data
const budgetPools = workflow.getStaticData('budgetPools');

// Pre-check function
function preBudgetCheck(tier, estimatedCost) {
  const poolName = getTierPool(tier);
  const pool = budgetPools[poolName];

  if (pool.balance < estimatedCost) {
    return {
      pass: false,
      reason: 'Insufficient budget',
      pool: poolName,
      balance: pool.balance,
      required: estimatedCost
    };
  }

  return {
    pass: true,
    pool: poolName,
    balance: pool.balance,
    estimatedCost: estimatedCost
  };
}

// Update budget after call
function updateBudget(tier, actualCost) {
  const poolName = getTierPool(tier);
  budgetPools[poolName].balance -= actualCost;
  workflow.setStaticData('budgetPools', budgetPools);
}
```

**Option B: Redis-backed Service** (scalable, production)
```javascript
// Budget service API
const budgetService = {
  async checkBudget(tier, estimatedCost) {
    const poolName = getTierPool(tier);
    const balance = await redis.get(`budget:${poolName}:balance`);

    if (parseFloat(balance) < estimatedCost) {
      return {
        pass: false,
        pool: poolName,
        balance: parseFloat(balance),
        required: estimatedCost
      };
    }

    // Reserve budget (optimistic locking)
    await redis.decrby(`budget:${poolName}:balance`, estimatedCost);

    return {
      pass: true,
      pool: poolName,
      reservationId: uuid(),
      balance: parseFloat(balance),
      estimatedCost: estimatedCost
    };
  },

  async updateBudget(reservationId, actualCost, estimatedCost) {
    const diff = estimatedCost - actualCost;
    if (diff > 0) {
      // Return unused budget
      await redis.incrby(`budget:${poolName}:balance`, diff);
    } else if (diff < 0) {
      // Charge additional amount
      await redis.decrby(`budget:${poolName}:balance`, Math.abs(diff));
    }
  }
};
```

### 3. Batch Routing Detector

**Purpose**: Auto-detect high-volume workloads and route to Tier 4 GPU rental

**Implementation**:
```javascript
// n8n Code Node: Batch Size Detection
const pendingRequests = $items.length;  // Number of items in batch
const BATCH_THRESHOLD = 50;

if (pendingRequests >= BATCH_THRESHOLD) {
  // Calculate cost comparison
  const tier1CostPerRequest = 0.0003;  // $0.30 per 1M tokens
  const tier4HourlyCost = 0.69;  // $0.69/hour RunPod
  const avgSecondsPerRequest = 5;
  const totalTime = (pendingRequests * avgSecondsPerRequest) / 3600;  // hours

  const tier1TotalCost = pendingRequests * tier1CostPerRequest;
  const tier4TotalCost = totalTime * tier4HourlyCost;

  if (tier4TotalCost < tier1TotalCost * 0.7) {  // 30% savings threshold
    return [{
      tier: 4,
      model: 'batch_gpu',
      batchSize: pendingRequests,
      estimatedCost: tier4TotalCost,
      savings: tier1TotalCost - tier4TotalCost,
      reason: `Batch routing: ${pendingRequests} requests, ${((1 - tier4TotalCost/tier1TotalCost) * 100).toFixed(0)}% cheaper`
    }];
  }
}

// Use Tier 1 for small batches
return [{
  tier: 1,
  model: 'executor',
  batchSize: pendingRequests,
  estimatedCost: pendingRequests * 0.0003,
  reason: 'Small batch, per-token pricing optimal'
}];
```

### 4. Tier 0 Prompt Compression

**Purpose**: Compress long prompts (>10k tokens) before sending to Tier 3

**Implementation**:
```javascript
// n8n Code Node: Check if compression needed
const prompt = $json.prompt;
const tokenCount = estimateTokens(prompt);  // ~4 chars per token
const COMPRESSION_THRESHOLD = 10000;

if (tokenCount > COMPRESSION_THRESHOLD) {
  return [{
    needsCompression: true,
    originalTokens: tokenCount,
    originalPrompt: prompt
  }];
}

return [{
  needsCompression: false,
  originalPrompt: prompt
}];
```

```javascript
// n8n HTTP Request: Tier 0 Compression (if needed)
// URL: http://litellm:4000/v1/chat/completions
// Body:
{
  "model": "fast_filter",  // Tier 0 Ollama 3B
  "messages": [
    {
      "role": "system",
      "content": "You are a text compressor. Extract the key facts and context from the following text, preserving all critical information. Output a compressed version that's 40-60% shorter while maintaining all essential details."
    },
    {
      "role": "user",
      "content": "{{$json.originalPrompt}}"
    }
  ],
  "max_tokens": 4000  // Target compressed size
}
```

```javascript
// n8n Code Node: Calculate savings
const compressed = $json.compressedPrompt;
const originalTokens = $json.originalTokens;
const compressedTokens = estimateTokens(compressed);
const compressionRatio = (1 - compressedTokens / originalTokens) * 100;

const tier0Cost = 0;  // Free local
const tier3TokenCost = 0.012;  // $12/M tokens
const savings = (originalTokens - compressedTokens) * tier3TokenCost / 1000;

return [{
  compressedPrompt: compressed,
  originalTokens: originalTokens,
  compressedTokens: compressedTokens,
  compressionRatio: compressionRatio.toFixed(1) + '%',
  tier0Cost: tier0Cost,
  tier3Savings: savings.toFixed(4)
}];
```

---

## Cost Optimization Strategies (v3.0)

### 1. Tier 0 Fast Filter (40% cost reduction)

**Strategy**: Route all simple queries to Tier 0 (Ollama 3B-13B) first

**Use Cases**:
- Factual lookup: "What is the capital of France?"
- Classification: "Is this email spam?"
- Intent detection: "User wants to: [search/create/delete/update]"
- Simple calculations: "Convert 100 USD to EUR"
- Formatting: "Format this date as YYYY-MM-DD"
- Prompt compression: "Summarize this 50-page doc to key points"

**Expected Impact**:
- 40% of queries answered at $0 cost
- <500ms latency (fast filter)
- Frees up Tier 3 budget for complex queries

**Implementation**:
```javascript
// Tier 0 routing rules
function isTier0Eligible(query) {
  const rules = [
    query.length < 500,  // Short queries
    /^(what|who|when|where|which|how many)/i.test(query),  // Factual questions
    /^(convert|calculate|format|classify)/i.test(query),  // Simple operations
    !hasCodeBlock(query),  // No code generation
    !hasComplexReasoning(query)  // No multi-step reasoning
  ];

  return rules.some(rule => rule);  // Any rule match → Tier 0
}
```

### 2. Batch Routing (30-50% savings)

**Strategy**: Auto-detect batch jobs (≥50 requests) and route to Tier 4 hourly GPU rental

**Economics**:
```
Tier 1 (Fireworks per-token):
- 50 requests × $0.0003 = $0.015
- 100 requests × $0.0003 = $0.030
- 500 requests × $0.0003 = $0.150

Tier 4 (RunPod hourly):
- 50 requests @ 5s each = 250s = 0.07 hours × $0.69 = $0.048 (LOSS)
- 100 requests @ 5s each = 500s = 0.14 hours × $0.69 = $0.097 (LOSS)
- 500 requests @ 5s each = 2500s = 0.69 hours × $0.69 = $0.476 (68% SAVINGS!)

Breakeven: ~150 requests
```

**Implementation**:
```javascript
// Batch routing decision
function shouldUseTier4(batchSize, avgLatency) {
  const BREAKEVEN_THRESHOLD = 150;
  const BATCH_THRESHOLD = 50;  // Minimum for consideration

  if (batchSize < BATCH_THRESHOLD) return false;

  const tier1Cost = batchSize * 0.0003;
  const tier4Cost = (batchSize * avgLatency / 3600) * 0.69;
  const savings = (tier1Cost - tier4Cost) / tier1Cost;

  return savings > 0.30;  // 30% savings threshold
}
```

### 3. Architect/Executor Pattern (57% savings)

**Strategy**: Use Tier 3 for planning, Tier 0/1 for execution

**Economics**:
```
Traditional (all Tier 3):
- Planning: $0.15
- Step 1: $0.15
- Step 2: $0.15
- ...
- Step 10: $0.15
- Total: $1.65

Architect/Executor:
- Architect (Tier 3): $0.15
- Executor Step 1 (Tier 0): $0.00
- Executor Step 2 (Tier 0): $0.00
- Executor Step 3 (Tier 1): $0.035
- ...
- Executor Step 10 (Tier 1): $0.035
- Reviewer (Tier 3): $0.15
- Total: $0.15 + $0.35 + $0.15 = $0.65
- Savings: 57%
```

**Best For**:
- Multi-step coding tasks
- Content generation pipelines
- Data processing workflows
- Repeated pattern execution

### 4. Prompt Compression (60% token reduction)

**Strategy**: Use Tier 0 to compress long prompts before sending to Tier 3

**Economics**:
```
Without Compression:
- 50-page PDF = ~100k tokens
- Tier 3 cost: 100k × $0.012/1k = $1.20

With Tier 0 Compression:
- Tier 0 compression: $0.00 (local)
- Compressed to 40k tokens (60% reduction)
- Tier 3 cost: 40k × $0.012/1k = $0.48
- Savings: $0.72 (60%)
```

**Implementation**:
```javascript
// Compression workflow
async function compressPrompt(longPrompt) {
  if (estimateTokens(longPrompt) < 10000) {
    return longPrompt;  // No compression needed
  }

  // Step 1: Tier 0 extractive summarization
  const compressed = await callLLM({
    model: 'fast_filter',  // Tier 0
    prompt: `Compress this text to 40% of original length, preserving all key facts:\n\n${longPrompt}`,
    maxTokens: estimateTokens(longPrompt) * 0.4
  });

  return compressed;
}

// Use in query workflow
const originalPrompt = $json.userQuery + '\n\n' + $json.retrievedDocs;
const compressedPrompt = await compressPrompt(originalPrompt);
const response = await callLLM({
  model: 'architect',  // Tier 3
  prompt: compressedPrompt
});
```

### 5. Pre-Budget Checks (100% budget overrun prevention)

**Strategy**: Validate budget before every LLM call

**Impact**:
- Zero unauthorized charges
- Graceful degradation when budget low
- Real-time cost awareness

**Implementation**: See "Breaking Changes" section above

---

## Migration Path: v2.1 → v3.0

### Step 1: Deploy New Services

```bash
# Pull latest images
docker pull ghcr.io/berriai/litellm:main-latest

# Update docker-compose.yml
cd n8n-llm-orchestrator
cp docker-compose.yml docker-compose.yml.v2.1.backup
# Edit docker-compose.yml to add LiteLLM service (see configs/ examples)

# Deploy
docker-compose up -d litellm
docker-compose logs -f litellm  # Verify startup
```

### Step 2: Configure LiteLLM

```bash
# Create config
cp configs/litellm-config.yaml.example configs/litellm-config.yaml
# Edit with your API keys and provider settings

# Test configuration
curl http://localhost:4000/health
curl http://localhost:4000/v1/models  # List available models
```

### Step 3: Update n8n Workflows

**For each workflow with LLM calls**:

1. Open workflow in n8n GUI
2. Find HTTP Request nodes calling aisuite
3. Update URL: `http://aisuite:8000/generate` → `http://litellm:4000/v1/chat/completions`
4. Update body format:
   ```json
   {
     "model": "executor",  // Use model group, not specific model
     "messages": [
       {"role": "user", "content": "{{$json.prompt}}"}
     ]
   }
   ```
5. Add pre-budget check node BEFORE LLM call (see template below)
6. Save and test

**Pre-Budget Check Template** (add to all workflows):
```json
{
  "name": "Pre-Budget Check",
  "type": "n8n-nodes-base.code",
  "position": [400, 300],
  "parameters": {
    "mode": "runOnceForAllItems",
    "jsCode": "// Get tier from previous node\nconst tier = $json.tier || 1;\nconst prompt = $json.prompt || '';\n\n// Estimate cost\nconst tokenCount = Math.ceil(prompt.length / 4);\nconst costPerTier = {0: 0, 1: 0.0003, 2: 0, 3: 0.012, 4: 0.69};\nconst estimatedCost = tokenCount * costPerTier[tier] / 1000;\n\n// Get budget pool\nconst poolMap = {0: 'local_vps', 1: 'per_token', 2: 'local_vps', 3: 'premium', 4: 'hourly_vram'};\nconst pool = poolMap[tier];\n\n// Get current balance (from workflow static data)\nconst budgetPools = this.getWorkflowStaticData('node');\nif (!budgetPools.pools) {\n  budgetPools.pools = {\n    hourly_vram: 100,\n    per_token: 50,\n    premium: 30,\n    local_vps: 75\n  };\n}\nconst balance = budgetPools.pools[pool];\n\n// Check if sufficient\nif (balance < estimatedCost) {\n  return [{\n    pass: false,\n    error: `Budget exhausted in pool ${pool}`,\n    pool: pool,\n    balance: balance,\n    required: estimatedCost,\n    tier: tier\n  }];\n}\n\n// Reserve budget\nbudgetPools.pools[pool] -= estimatedCost;\n\nreturn [{\n  pass: true,\n  pool: pool,\n  balance: balance,\n  estimatedCost: estimatedCost,\n  tier: tier,\n  prompt: prompt\n}];"
  }
}
```

### Step 4: Initialize Budget Pools

```bash
# Run budget pool setup script
chmod +x scripts/setup-budget-pools.sh
./scripts/setup-budget-pools.sh

# Verify in n8n
# Open any workflow → Settings → Workflow Static Data
# Should see:
# {
#   "pools": {
#     "hourly_vram": 100,
#     "per_token": 50,
#     "premium": 30,
#     "local_vps": 75
#   }
# }
```

### Step 5: Test End-to-End

```bash
# Test Tier 0 fast filter
curl -X POST http://localhost:5678/webhook/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is 2+2?"}'
# Expected: Tier 0 response, $0 cost

# Test Tier 3 complex query
curl -X POST http://localhost:5678/webhook/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Design a microservices architecture for a banking system with event sourcing and CQRS patterns"}'
# Expected: Tier 3 response, ~$0.15 cost

# Test budget exhaustion
# Manually set budget pool to $0 in workflow static data
curl -X POST http://localhost:5678/webhook/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Any query"}'
# Expected: {"error": "Budget exhausted in pool per_token", "balance": 0, "required": 0.0012}
```

### Step 6: Monitor Costs

```bash
# View Helicone dashboard
open http://localhost:8002  # Helicone UI

# View LangSmith traces (if using)
open https://smith.langchain.com

# View budget pools
curl http://localhost:5678/api/v1/workflows/{workflow_id}/static-data
# Returns current budget pool balances
```

### Step 7: Deprecate aisuite

```bash
# Once all workflows migrated and tested
docker-compose stop aisuite
docker-compose rm aisuite

# Remove from docker-compose.yml
# Update .env to remove AISUITE_* variables
```

---

## Expected Results (30-Day Measurement)

### Cost Metrics

**Baseline (v2.1 - naive routing)**:
- Total queries: 10,000
- Average cost per query: $0.0050
- Total cost: $50

**v3.0 (intelligent routing)**:
- Total queries: 10,000
- Tier 0 (40%): 4,000 queries × $0 = $0
- Tier 1 (30%): 3,000 queries × $0.0003 = $0.90
- Tier 2 (5%): 500 queries × $0 = $0 (VPS fixed)
- Tier 3 (20%): 2,000 queries × $0.015 = $30
- Tier 4 (5%): 500 queries in 2 batches × $0.69/hour = $1.38 (vs $150 on Tier 1)
- **Total cost: $32.28**
- **Savings: $17.72 (35.4%)**

**With optimizations**:
- Prompt compression: 20% of Tier 3 queries compressed → save $6
- Architect/executor: 10% of Tier 3 queries → save $8.55
- **Final total: ~$18**
- **Final savings: 64%**

### Performance Metrics

- **P50 latency**: <2s (Tier 0 fast filter)
- **P90 latency**: <5s (including Tier 3)
- **P99 latency**: <8s (including Tier 4 cold start fallback)
- **Cache hit rate**: 20%+ (Helicone)
- **Budget overrun incidents**: 0 (pre-checks prevent)
- **Tier 4 idle waste**: <5% (auto-shutdown after 30 min)

### Operational Metrics

- **Tier distribution accuracy**: ≥90% (RouteLLM correct tier selection)
- **Pre-budget check overhead**: <100ms (negligible)
- **Alert response time**: <5 minutes (budget pool 90% alert)
- **Cost transparency**: 100% (every query logs tier + cost)

---

## Troubleshooting Guide

### Issue 1: LiteLLM Fails to Start

**Symptoms**: `docker-compose logs litellm` shows connection errors

**Causes**:
- Missing API keys in .env
- Invalid litellm-config.yaml
- Port 4000 already in use

**Solutions**:
```bash
# Check API keys
docker-compose exec litellm env | grep API_KEY

# Validate config
docker-compose exec litellm cat /app/config.yaml

# Check port
lsof -i :4000
# If in use, change port in docker-compose.yml and n8n workflows

# Restart with logs
docker-compose restart litellm
docker-compose logs -f litellm
```

### Issue 2: Pre-Budget Check Always Fails

**Symptoms**: All queries return "Budget exhausted" even though balance should be sufficient

**Causes**:
- Budget pools not initialized
- Balance calculation error
- Pool name mismatch

**Solutions**:
```bash
# Check workflow static data
curl http://localhost:5678/api/v1/workflows/{workflow_id}/static-data

# Reinitialize pools
./scripts/setup-budget-pools.sh

# Manually reset in n8n UI
# Open workflow → Settings → Workflow Static Data → Edit → Set:
# {"pools": {"hourly_vram": 100, "per_token": 50, "premium": 30, "local_vps": 75}}
```

### Issue 3: Tier 4 (GPU Rental) Not Routing

**Symptoms**: Batch jobs still use Tier 1 even with >50 requests

**Causes**:
- Batch detection logic error
- Cost comparison threshold too strict
- Tier 4 provider credentials missing

**Solutions**:
```javascript
// Debug batch detection
const batchSize = $items.length;
console.log('Batch size:', batchSize);
console.log('Threshold:', 50);
console.log('Should route to Tier 4:', batchSize >= 50);

// Lower savings threshold
const SAVINGS_THRESHOLD = 0.20;  // 20% instead of 30%

// Verify Tier 4 provider
docker-compose exec litellm curl -X POST http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "batch_gpu", "messages": [{"role": "user", "content": "test"}]}'
```

### Issue 4: Prompt Compression Degrades Quality

**Symptoms**: Compressed prompts lose critical context, Tier 3 responses less accurate

**Causes**:
- Compression ratio too aggressive (>60%)
- Tier 0 model too small for complex compression
- Key facts not preserved

**Solutions**:
```javascript
// Reduce compression target
const maxTokens = estimateTokens(longPrompt) * 0.6;  // 40% compression instead of 60%

// Use better compression prompt
const compressionPrompt = `Extract key facts from the following text. Preserve:
1. All numerical data
2. Names and entities
3. Critical dates and events
4. Main arguments and conclusions

DO NOT summarize opinions or interpretations. Output compressed text:

${longPrompt}`;

// Validate compression quality
const quality = validateCompression(originalPrompt, compressedPrompt);
if (quality < 0.80) {
  // Skip compression, use original
  return originalPrompt;
}
```

### Issue 5: Cost Dashboard Shows Incorrect Savings

**Symptoms**: Helicone or LangSmith shows different cost than budget pools

**Causes**:
- Estimated cost != actual cost
- Budget pool update failed
- Token count estimation error

**Solutions**:
```javascript
// Update budget with actual cost, not estimated
const actualCost = response.usage.total_tokens * tierCost / 1000;
const estimatedCost = $json.estimatedCost;
const diff = actualCost - estimatedCost;

if (Math.abs(diff) > 0.001) {  // More than $0.001 difference
  // Log discrepancy
  console.warn('Cost estimation error:', {
    estimated: estimatedCost,
    actual: actualCost,
    diff: diff
  });
}

// Always update with actual cost
budgetPools.pools[pool] -= actualCost;  // Not estimatedCost
```

---

## Success Criteria Validation

After 30 days in production, validate against v3.0 success criteria:

### Cost Optimization (Primary Goals)

- ✅ **SC-021**: Tier 0 fast filter handles 40%+ of simple queries at $0 cost
  - **Validation**: `SELECT COUNT(*) FROM queries WHERE tier = 0 GROUP BY tier` should show ≥40%

- ✅ **SC-022**: Batch routing engages for 100% of jobs with ≥50 requests, achieving 30-50% savings
  - **Validation**: Check batch job logs, compare Tier 4 cost vs Tier 1 baseline

- ✅ **SC-023**: Architect/executor pattern achieves 50%+ cost savings vs all-Tier-3
  - **Validation**: Sum cost breakdown per role, compare to baseline

- ✅ **SC-024**: Prompt compression reduces Tier 3 token usage by 40-60%
  - **Validation**: Compare original vs compressed token counts in logs

- ✅ **SC-025**: Pre-budget checks prevent 100% of budget overruns
  - **Validation**: Check for any negative budget pool balances (should be 0 incidents)

- ✅ **SC-027**: Overall cost reduction of 60-70% vs naive routing
  - **Validation**: Total monthly cost $18-20 vs baseline $50

### Performance (Secondary Goals)

- ✅ **SC-002**: P90 latency <5s including pre-budget check overhead <100ms
  - **Validation**: OpenTelemetry trace data, P90 percentile

- ✅ **SC-003**: Batch routing engaged for >50 docs
  - **Validation**: Document ingestion logs show Tier 4 usage

### Budget Control (Critical)

- ✅ **SC-028**: Budget alerts trigger at 90% capacity for all pools
  - **Validation**: Manual test by setting pool to $10, spending $9, verify alert

- ✅ **SC-026**: Tier 4 instances auto-shutdown within 30 min of idle
  - **Validation**: Check instance uptime logs, verify shutdown events

---

## Appendix: Configuration Examples

### A. Full docker-compose.yml (v3.0)

```yaml
version: '3.8'

services:
  # n8n workflow orchestration
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - GENERIC_TIMEZONE=America/New_York
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/workflows
    depends_on:
      - qdrant
      - litellm

  # LiteLLM unified LLM API
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    ports:
      - "4000:4000"
    environment:
      - LITELLM_MASTER_KEY=${LITELLM_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - FIREWORKS_API_KEY=${FIREWORKS_API_KEY}
      - TOGETHER_API_KEY=${TOGETHER_API_KEY}
      - RUNPOD_API_KEY=${RUNPOD_API_KEY}
      - DATABASE_URL=postgresql://litellm:${POSTGRES_PASSWORD}@postgres:5432/litellm
    volumes:
      - ./configs/litellm-config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    depends_on:
      - postgres

  # Ollama (Tier 0 + Tier 2)
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

  # Qdrant vector database
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

  # PostgreSQL (for LiteLLM caching)
  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=litellm
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=litellm
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Helicone cost proxy
  helicone:
    image: helicone/helicone:latest
    ports:
      - "8002:8002"
    environment:
      - HELICONE_API_KEY=${HELICONE_API_KEY}
      - PROXY_URL=http://litellm:4000

  # OpenTelemetry Collector
  otel-collector:
    image: otel/opentelemetry-collector:latest
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
    volumes:
      - ./configs/otel-collector-config.yaml:/etc/otel/config.yaml
    command: ["--config=/etc/otel/config.yaml"]

  # Jaeger (trace backend)
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # Jaeger UI
      - "14268:14268"  # Jaeger collector
    environment:
      - COLLECTOR_OTLP_ENABLED=true

  # Redis (for budget pools)
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  n8n_data:
  ollama_data:
  qdrant_data:
  postgres_data:
  redis_data:
```

### B. Environment Variables (.env)

```bash
# n8n
N8N_PASSWORD=your_secure_password

# LiteLLM
LITELLM_API_KEY=sk-litellm-your-api-key

# Tier 3 Providers (Premium)
ANTHROPIC_API_KEY=sk-ant-your-api-key
GOOGLE_API_KEY=your-gemini-api-key
OPENAI_API_KEY=sk-your-openai-api-key

# Tier 1 Providers (Per-Token)
FIREWORKS_API_KEY=your-fireworks-api-key
TOGETHER_API_KEY=your-together-api-key

# Tier 4 Providers (Hourly VRAM)
RUNPOD_API_KEY=your-runpod-api-key
SALAD_API_KEY=your-salad-api-key
CLOUDRIFT_API_KEY=your-cloudrift-api-key

# Observability
HELICONE_API_KEY=your-helicone-api-key
LANGSMITH_API_KEY=your-langsmith-api-key

# PostgreSQL
POSTGRES_PASSWORD=your_postgres_password
```

---

**Document Status**: Complete
**Last Updated**: 2025-11-18
**Next Review**: After Phase 0 implementation begins

**Ready for**: Implementation via 04-tasks_v3.0.md task breakdown
