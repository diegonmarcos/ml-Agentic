# Multi-Agent Orchestrator v4.0 - Quick Start

**Status**: ✅ Architecture Complete - Ready for Implementation
**Version**: 4.0.0
**Date**: 2025-11-18
**Cost Target**: 84-88% savings ($6-8/month vs $50 baseline)

---

## 🎯 What Is This?

A **multi-agent orchestrator** that automates:
1. **Code tasks** - Modify codebases, commit changes, generate tests
2. **Web tasks** - Scrape websites, automate browsers, research competitors

Both agents use **intelligent 5-tier routing** to minimize costs while maintaining quality.

---

## 📁 v4.0 Core Documents

### 1. **[0.constitution_v4.0.md](./0.constitution_v4.0.md)** - Architecture Principles
- 10 core principles (added Principle X: Agent Specialization)
- **Coder Agent**: File I/O, git automation, AST parsing, RAG code search
- **Web Agent**: Playwright automation, Firecrawl scraping, vision analysis
- Shared: 5-tier routing, pre-budget checks, architect/executor pattern
- 1,063 lines of architectural governance

### 2. **[01-spec_v4.0.md](./01-spec_v4.0.md)** - Feature Specification
- 10 user stories (5 per agent type)
- **120 functional requirements** covering both agents
- New entities: Agent, CoderTask, WebTask, GitCommit, BrowserSession
- 36 success criteria (cost, performance, reliability)
- Expected 84-88% cost savings

### 3. **Pending Implementation Files**
- `02-plan_v4.0.md` - Implementation plan
- `ARCHITECTURE_v4.0_COMPLETE.md` - Complete guide
- `cli/n8n-agent-cli.sh` - CLI tool
- `playwright/service.js` - Browser automation service
- `flowise/config.json` - Chat UI integration
- `workflows/*.json` - n8n workflow templates

---

## ⚡ Quick Start

### Use Cases

**Coder Agent**:
```bash
# CLI
./cli/n8n-agent-cli.sh coder /path/to/my-app "Refactor auth to use JWT"

# Web Chat
User: "Refactor authentication in /home/user/my-app to use JWT tokens"
Agent: [Creates branch, modifies files, commits] ✅ Done! Cost: $0.65
```

**Web Agent**:
```bash
# CLI
./cli/n8n-agent-cli.sh web https://competitor.com/pricing "Research pricing"

# Web Chat
User: "Research competitor pricing from https://competitor.com/pricing"
Agent: [Navigates, extracts, analyzes, saves report] ✅ Done! Cost: $0.25
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

## 💰 5-Tier Cost System

| Tier | Models | Cost | Use When | Example |
|------|--------|------|----------|---------|
| **0** | Ollama 3B-13B | **$0** | Simple queries, classification | "Find all API endpoints" |
| **1** | Fireworks, Together | $0.20-0.80/M | Standard execution | "Generate utility function" |
| **2** | Ollama 70B+Vision | **$0** (VPS) | Screenshot analysis | "Extract pricing from image" |
| **3** | Claude, Gemini | $3-15/M | Planning, review | Task planning, code review |
| **4** | RunPod, Salad | $0.69-2/hr | Batch >50 ops | Index 100 files, scrape 100 pages |

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

### 3. **Tier 0 Fast Filter** (40% of queries free)
```
Simple queries route to local Ollama 3B:
- "What does this function do?" → Tier 0 → $0
- "Find auth files" → Tier 0 → $0
- "Is this a GET or POST endpoint?" → Tier 0 → $0
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
