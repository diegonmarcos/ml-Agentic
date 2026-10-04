# Multi-Agent Orchestrator v4.1 - Quick Start

**Status**: ✅ Architecture v4.1 Complete - Open-Source First + Privacy Mode
**Version**: 4.1.0 (Updated from v4.0.0)
**Date**: 2025-11-18
**Cost Target**: 84-88% savings ($6-8/month) OR $0 API costs (Privacy Mode)

---

## 🆕 What's New in v4.1?

**v4.1 adds critical refinements** to the v4.0 multi-agent architecture:

1. **🔓 Open-Source First**: 80%+ execution on Tier 0/1 (local/cheap), premium APIs only as architects
2. **🔒 Privacy Mode**: Local-only option (GDPR/HIPAA compliant) - 0 external API calls
3. **🎯 RAG Context Optimization**: Anti-hallucination through context compression (84% savings per query)
4. **🌐 Web Agent Privacy**: Enhanced Playwright with fingerprint randomization, ad blocking
5. **💰 Cost Transparency UI**: Pre-prompt estimates, real-time tracking, cost analytics dashboard

**Cost Options**:
- **Privacy OFF**: $6-8/month (variable API costs + $75 VPS)
- **Privacy ON**: $75/month fixed (0 API costs, all local Tier 0/2)

**Key Document**: [v4.1-ARCHITECTURE-REFINEMENTS.md](./v4.1-ARCHITECTURE-REFINEMENTS.md) - Complete v4.1 changes

---

## 🎯 What Is This?

A **multi-agent orchestrator** that automates:
1. **Code tasks** - Modify codebases, commit changes, generate tests
2. **Web tasks** - Scrape websites, automate browsers, research competitors

Both agents use **intelligent 5-tier routing** to minimize costs while maintaining quality.

**v4.1 Priorities**:
- **Open-source models do the work** (80%+ execution on Tier 0/1)
- **Premium models guide the work** (5-15% on Tier 3 for planning/review only)
- **Privacy mode available** (All data stays local, GDPR/HIPAA compliant)
- **RAG context optimized** (No hallucination, compressed contexts)

---

## 📁 v4.1 Core Documents

### 1. **[v4.1-ARCHITECTURE-REFINEMENTS.md](./v4.1-ARCHITECTURE-REFINEMENTS.md)** - v4.1 Changes (NEW)
- Open-Source First strategy (80%+ on Tier 0/1)
- Privacy Mode implementation & routing
- RAG Context Optimization (anti-hallucination)
- Web Agent privacy hardening
- Cost Transparency UI specifications
- 45 new functional requirements (FR-121 to FR-165)

### 2. **[0.constitution_v4.0.md](./0.constitution_v4.0.md)** - Architecture Principles (UPDATED)
- **13 core principles** (added 3 new in v4.1):
  - Principle II: Open-Source First & LLM-Agnostic (updated)
  - Principle X: RAG Context Optimization (new)
  - Principle XI: Privacy Mode & Data Sovereignty (new)
  - Principle XII: Agent Specialization (was X)
  - Principle XIII: Web Chat UI/UX Requirements (new)
- **Coder Agent**: File I/O, git automation, AST parsing, RAG code search with context compression
- **Web Agent**: Privacy-hardened Playwright, Firecrawl scraping, local vision analysis
- Shared: 5-tier routing, pre-budget checks, architect/executor pattern, privacy mode
- 1,450+ lines of architectural governance

### 3. **[01-spec_v4.0.md](./01-spec_v4.0.md)** - Feature Specification
- 10 user stories (5 per agent type)
- **165 functional requirements** (120 from v4.0 + 45 new in v4.1)
- New v4.1 requirements: Privacy mode, RAG optimization, UI cost tracking
- New entities: Agent, CoderTask, WebTask, GitCommit, BrowserSession, PrivacyMode
- 36 success criteria (cost, performance, reliability, privacy compliance)
- Expected 84-88% cost savings (privacy mode: 100% API cost elimination)

### 4. **Implementation Files** (CREATED)
- ✅ `cli/n8n-agent-cli.sh` - CLI tool for both agents
- ✅ `playwright/service.js` - Privacy-hardened browser automation service
- ✅ `workflows/001-master-orchestrator.json` - Agent routing workflow
- ✅ `workflows/002-coder-agent.json` - Coder Agent with architect/executor
- ✅ `workflows/003-web-agent.json` - Web Agent with browser automation
- ✅ `workflows/004-budget-check.json` - Pre-budget validation workflow
- ✅ `workflows/005-tier-routing.json` - Intelligent tier selection workflow

### 5. **Pending Implementation Files**
- `02-plan_v4.1.md` - v4.1 Implementation plan
- `flowise/cost-tracking-ui/` - Cost transparency UI components
- `rag/llamaindex-service/` - Context optimization service
- `workflows/006-privacy-mode-routing.json` - Privacy mode enforcement
- `litellm-config.yaml` - LiteLLM configuration with all tiers

---

## ⚡ Quick Start

### Use Cases

**Coder Agent** (Privacy OFF):
```bash
# CLI
./cli/n8n-agent-cli.sh coder /path/to/my-app "Refactor auth to use JWT"

# Web Chat
User: "Refactor authentication in /home/user/my-app to use JWT tokens"
Agent: [Architect plans (Tier 3), Executors code (Tier 1), Review validates (Tier 3)]
       [Creates branch, modifies files, commits] ✅ Done!
       Cost: $0.65 (Architect $0.15, Executor $0.35, Review $0.15)
```

**Coder Agent** (Privacy ON):
```bash
# Web Chat (Privacy Mode Enabled 🔒)
User: "Refactor authentication in /home/user/my-app to use JWT tokens"
Agent: [All processing on local Tier 0 (Ollama 70B)]
       [Creates branch, modifies files, commits] ✅ Done!
       Cost: $0 (100% local) - All data stayed on VPS
```

**Web Agent** (Privacy OFF):
```bash
# CLI
./cli/n8n-agent-cli.sh web https://competitor.com/pricing "Research pricing"

# Web Chat
User: "Research competitor pricing from https://competitor.com/pricing"
Agent: [Architect plans (Tier 3), Navigates (Playwright), Extracts (Firecrawl), Analyzes (Tier 1)]
       [Saves report] ✅ Done! Cost: $0.25
```

**Web Agent** (Privacy ON):
```bash
# Web Chat (Privacy Mode Enabled 🔒)
User: "Research competitor pricing from https://competitor.com/pricing"
Agent: [Planning (Tier 0 local), Navigates (Playwright), Extracts (local), Analyzes (Tier 0)]
       [Saves report] ✅ Done!
       Cost: $0 (100% local) - Privacy-hardened browser, no tracking
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│              USER INTERFACES                             │
│  ┌──────────────────┐       ┌──────────────────┐       │
│  │  Web Chat        │       │   CLI Tool       │       │
│  │  (Flowise)       │       │ (curl wrapper)   │       │
│  └────────┬─────────┘       └────────┬─────────┘       │
└───────────┼──────────────────────────┼──────────────────┘
            │                          │
            └──────────┬───────────────┘
                       │ HTTP Webhook
                       ▼
┌──────────────────────────────────────────────────────────┐
│           n8n MASTER ORCHESTRATOR                        │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. Parse Request                                  │   │
│  │ 2. Select Agent (coder | web)                    │   │
│  │ 3. Pre-Budget Check                              │   │
│  └──────────────────┬──────────────────────────────┘   │
│                     │                                    │
│           ┌─────────┴─────────┐                         │
│           ▼                   ▼                          │
│  ┌────────────────┐  ┌────────────────┐                │
│  │ CODER AGENT    │  │  WEB AGENT     │                │
│  │                │  │                │                │
│  │ • File I/O     │  │ • Playwright   │                │
│  │ • Git ops      │  │ • Firecrawl    │                │
│  │ • RAG search   │  │ • Vision       │                │
│  │ • AST parse    │  │ • Batch scrape │                │
│  └────────────────┘  └────────────────┘                │
└──────────────────────────────────────────────────────────┘
```

---

## 💰 5-Tier Cost System (v4.1 - Open-Source First)

| Tier | Models | Cost | v4.1 Usage | Privacy Mode | Example |
|------|--------|------|------------|--------------|---------|
| **0** | Ollama 3B-70B | **$0** | **45%** ⬆️ | ✅ Allowed | "Find auth files", Planning (privacy ON) |
| **1** | Fireworks, Together | $0.20-0.80/M | **35%** ⬆️ | ❌ Blocked | "Generate function" (privacy OFF only) |
| **2** | Ollama Vision 70B | **$0** (VPS) | **5%** | ✅ Allowed | "Extract pricing from screenshot" |
| **3** | Claude, Gemini | $3-15/M | **13%** ⬇️ | ❌ Blocked | Planning/Review ONLY (privacy OFF) |
| **4** | RunPod, Salad | $0.69-2/hr | **2%** | ❌ Blocked | Batch >50 ops (configurable if self-hosted) |

**v4.1 Key Changes**:
- Tier 0 increased from 40% → **45%** (more local execution)
- Tier 1 increased from 30% → **35%** (open-source API execution)
- Tier 3 decreased from 20% → **13%** (premium only for architect/advisor roles)
- **Privacy Mode**: Routes Tier 1/3/4 → Tier 0 (100% local)

---

## 🎨 Cost Optimization Patterns

### 1. **Architect/Executor Pattern** (57% savings)
```
Traditional: Planning + 10 steps × Tier 3 = $1.65
v4.0:        Architect (T3) + Executors (T1) + Review (T3) = $0.65
```

### 2. **Batch Routing** (30-50% savings)
```
50 files to index:
- Tier 1 per-file: 50 × $0.0006 = $0.03
- Tier 4 hourly:   $0.69/hr for 5 min = $0.058
→ Use Tier 1 (cheaper for this batch)

500 files to index:
- Tier 1 per-file: 500 × $0.0006 = $0.30
- Tier 4 hourly:   $0.69/hr for 15 min = $0.17
→ Use Tier 4 (43% savings!)
```

### 3. **Tier 0 Fast Filter** (45% of queries free in v4.1)
```
Simple queries route to local Ollama 3B-13B:
- "What does this function do?" → Tier 0 → $0
- "Find auth files" → Tier 0 → $0
- "Is this a GET or POST endpoint?" → Tier 0 → $0
```

### 4. **Privacy Mode** (100% local, v4.1 NEW)
```
Privacy Mode routes ALL queries to Tier 0 (local only):
- Complex planning → Tier 0 (70B local) → $0
- Code execution → Tier 0 (13B local) → $0
- Review → Tier 0 (70B local) → $0
- Total API cost: $0
- Fixed VPS cost: $75/month

Benefits: GDPR/HIPAA compliant, fixed cost, home hardware ready
Trade-off: 10-15% quality reduction for complex tasks
```

### 5. **RAG Context Compression** (84% savings per query, v4.1 NEW)
```
Without Compression:
- Context: 50k tokens → Tier 3 Claude ($0.15 input) → Total $0.21

With Tier 0 Compression:
- Step 1: 50k tokens → Tier 0 compress ($0) → 8k tokens
- Step 2: 8k tokens → Tier 3 Claude ($0.024 input) → Total $0.034
- Savings: 84% per complex query with RAG

Prevents hallucination + optimizes for Claude/Gemini context windows
```

---

## 📊 Expected Results (100 tasks/month)

**Baseline (All Tier 3)**:
- 100 tasks × $0.50 = $50/month

**v4.0 (Intelligent Routing)**:
```
Tier 0 (40%): 40 tasks × $0      = $0.00
Tier 1 (35%): 35 tasks × $0.10   = $3.50
Tier 2 (5%):   5 tasks × $0      = $0.00
Tier 3 (18%): 18 tasks × $0.50   = $9.00
Tier 4 (2%):   2 tasks × $0.30   = $0.60
                        Subtotal = $13.10

With optimizations:
- Prompt compression: -$2.00
- Architect/executor: -$4.00
- Helicone cache:     -$1.00
                FINAL = $6-8/month
```

**Savings: 84-88%** 🎉

---

## 🚀 What's Different from v3.0?

| Aspect | v3.0 | v4.0 |
|--------|------|------|
| **Purpose** | Document Q&A RAG | Multi-Agent Orchestrator |
| **Agents** | None (single RAG) | **Coder + Web** |
| **Input** | Documents (PDF/MD/TXT) | **Codebases + Websites** |
| **Output** | Text answers | **Code commits + Reports** |
| **Interface** | HTTP webhook | **Web chat + CLI** |
| **Git Integration** | ❌ No | **✅ Auto-commit** |
| **Browser Automation** | ❌ No | **✅ Playwright** |
| **Cost Target** | $18/month | **$6-8/month** |
| **Savings** | 64% | **84-88%** |

---

## 🛠️ Key Features

### Coder Agent
- ✅ Read/write code files
- ✅ Search codebase with RAG
- ✅ Auto-create git branches
- ✅ Auto-commit changes
- ✅ Generate tests and docs
- ✅ Refactor code
- ✅ AST-based code analysis

### Web Agent
- ✅ Playwright browser automation
- ✅ Firecrawl web scraping
- ✅ Screenshot analysis (vision)
- ✅ Multi-page scraping
- ✅ Form automation
- ✅ Research reports (auto-commit)
- ✅ Batch web operations

### Shared Framework
- ✅ 5-tier cost optimization
- ✅ Mandatory pre-budget checks
- ✅ Architect/executor pattern
- ✅ Prompt compression
- ✅ Batch routing
- ✅ Full observability (OpenTelemetry, LangSmith, Helicone)

---

## 📦 Components

### Core Services
- **n8n**: Workflow orchestration
- **LiteLLM**: Unified LLM API (5 tiers)
- **Qdrant**: Vector DB (code + web content)
- **Ollama**: Local models (Tier 0/2)
- **Redis**: Budget pool state

### Coder Agent Tools
- **Git**: Version control
- **tree-sitter**: AST parsing (optional)
- **File I/O**: n8n Code nodes

### Web Agent Tools
- **Playwright**: Browser automation
- **Firecrawl**: Web scraping API
- **Ollama Vision**: Screenshot analysis

### Interfaces
- **Flowise**: Web chat UI
- **CLI**: Bash script (curl wrapper)

### Observability
- **OpenTelemetry + Jaeger**: Distributed tracing
- **LangSmith/Langfuse**: LLM monitoring
- **Helicone**: Cost tracking + caching
- **MCPcat**: Tool call monitoring

---

## 🎯 Success Criteria (30-Day Validation)

After 30 days:
- ✅ **SC-005**: Overall 80%+ cost reduction vs all-Tier-3
- ✅ **SC-006**: Monthly cost <$10 for 100 tasks
- ✅ **SC-009**: Git commits 100% properly formatted
- ✅ **SC-016**: Browser cleanup 100% successful (no orphans)
- ✅ **SC-027**: Tier routing 90%+ accuracy
- ✅ **SC-033**: Coder Agent 70% faster than manual coding
- ✅ **SC-034**: Web Agent 80% faster than manual research

---

## 🔧 Implementation Status

### ✅ Completed
- [x] Constitution v4.0 (10 principles, agent specialization)
- [x] Specification v4.0 (120 FRs, 10 user stories, 36 success criteria)
- [x] README v4.0 (this file)

### 🚧 In Progress
- [ ] Implementation Plan v4.0
- [ ] Architecture Guide v4.0
- [ ] CLI tool script
- [ ] Playwright service
- [ ] Flowise integration
- [ ] n8n workflow templates

---

## 📖 Next Steps

1. **Read** [0.constitution_v4.0.md](./0.constitution_v4.0.md) for architectural principles
2. **Read** [01-spec_v4.0.md](./01-spec_v4.0.md) for detailed requirements
3. **Wait for** remaining implementation files (in progress)
4. **Deploy** services (n8n, LiteLLM, Playwright, etc.)
5. **Test** with sample codebase and website
6. **Validate** costs after 30 days

---

## 💡 Example Tasks

**Coder Agent**:
- "Refactor authentication to use JWT tokens"
- "Add logging to all API routes"
- "Write unit tests for user service"
- "Find and fix all ESLint errors"
- "Generate JSDoc comments for utils/"

**Web Agent**:
- "Research competitor pricing from their website"
- "Extract all product data from this catalog"
- "Monitor this page daily for price changes"
- "Analyze this screenshot and extract pricing tiers"
- "Scrape all blog posts from this site"

---

## 🤝 Contributing

This is an evolving architecture. Feedback welcome on:
- Cost optimization strategies
- Agent capabilities
- Tool integrations
- Workflow improvements

---

**Document Version**: 1.0
**Last Updated**: 2025-11-18
**Status**: Complete - Architecture Defined, Implementation Pending
**Contact**: See repository maintainers
