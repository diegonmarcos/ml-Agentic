That's the perfect next step! LangGraph is the ideal framework for implementing a controlled, stateful agentic workflow like the one we designed. It allows you to define a clear flow of logic using a graph structure, which is much more robust than simple prompt chaining.

Here is the specification for the **Recipe Retriever** project, specifically implemented using **LangGraph** concepts.

---

# 🏗️ Agentic Project with $\text{Spec-Driven Development}$


## 📋 GitHub Spec Kit - Spec-Driven Development

### Overview

GitHub Spec Kit is a toolkit for **Spec-Driven Development (SDD)** that helps structure AI-powered development workflows. Instead of "vibe coding," it enables teams to outline concrete project requirements, motivations, and technical aspects before implementation.

**Repository**: `github/spec-kit`
**Installation**: `uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>`

### Core Workflow Commands

Use these slash commands in sequence for spec-driven development:

#### 1. Primary Commands (Sequential Flow)

| Command | Purpose | When to Use |
| :--- | :--- | :--- |
| `/speckit.constitution` | Establish project principles | First step - Define core values and constraints |
| `/speckit.specify` | Create baseline specification | After constitution - Document requirements and scope |
| `/speckit.plan` | Create implementation plan | After specification - Design technical approach |
| `/speckit.tasks` | Generate actionable tasks | After planning - Break down into concrete steps |
| `/speckit.implement` | Execute implementation | Final step - Build according to plan |

#### 2. Enhancement Commands (Optional)

| Command | Purpose | When to Use |
| :--- | :--- | :--- |
| `/speckit.clarify` | Ask structured questions to de-risk ambiguous areas | Before `/speckit.plan` - Resolve uncertainties |
| `/speckit.checklist` | Generate quality checklists for requirements validation | After `/speckit.plan` - Verify completeness |
| `/speckit.analyze` | Cross-artifact consistency & alignment report | After `/speckit.tasks`, before `/speckit.implement` |

### Project Structure

```
project/
├── .claude/              # Agent configuration (add to .gitignore)
├── constitution.md       # Project principles and values
├── specification.md      # Detailed requirements
├── plan.md              # Technical implementation plan
└── tasks.md             # Actionable task breakdown
```

### Security Note

The `.claude/` directory may contain credentials, auth tokens, or identifying artifacts. Always add it to `.gitignore` to prevent credential leakage.

---

## 📖 How to Use Spec Kit - Complete Guide

### Using Slash Commands

Spec Kit commands are invoked by **typing them directly in your Claude Code chat**. When in a Spec Kit initialized project directory, simply type the command and press enter.

**Example:**
```
/speckit.constitution
```

When you type a slash command:
1. Claude Code loads the command prompt from `.claude/commands/`
2. It guides you through creating/updating the respective document
3. Output is saved to your project directory
4. Related artifacts are kept in sync

---

### Step-by-Step Workflow

#### 1️⃣ Define Project Constitution

**Command:** `/speckit.constitution`

**Purpose:** Establish your project's core principles and values

**What it creates:** `.specify/memory/constitution.md`

**What you define:**
- **Core Principles** (3-7 recommended)
  - Example: "Visual-First Design", "LLM-Agnostic", "Test-Driven"
- **Non-negotiable rules**
  - Example: "All workflows must be representable in n8n"
- **Governance policies**
  - Example: "Constitution changes require team approval"
- **Development standards**
  - Example: "Error handling mandatory for all LLM calls"

**Example Constitution for n8n LLM Orchestrator:**

```markdown
# n8n LLM Orchestrator Constitution

## Core Principles

### I. Visual-First Design
All agent workflows must be representable in n8n's visual interface.
No hidden logic in external scripts unless absolutely necessary.

### II. LLM-Agnostic Architecture
Support OpenAI, Anthropic, and Ollama interchangeably.
Abstract LLM calls behind unified interface.

### III. Fail-Safe Operations
Graceful degradation, automatic retries with exponential backoff.
Never crash - always return meaningful error.

### IV. Cost Conscious
Monitor token usage, optimize prompts, cache when possible.
Track costs per workflow execution.

### V. Observable Flows
Structured logging, metrics, debugging traces.
Every agent step must be traceable.

## Governance

**Version**: 1.0.0 | **Ratified**: 2025-10-30 | **Last Amended**: 2025-10-30
```

**Template Placeholders Filled:**
- `[PROJECT_NAME]` → "n8n LLM Orchestrator"
- `[PRINCIPLE_X_NAME]` → Each principle's title
- `[PRINCIPLE_X_DESCRIPTION]` → Detailed explanation
- `[CONSTITUTION_VERSION]` → Semantic version (1.0.0)
- `[RATIFICATION_DATE]` → Today's date
- `[LAST_AMENDED_DATE]` → Today's date

---

#### 2️⃣ Create Specification

**Command:** `/speckit.specify`

**Purpose:** Write detailed requirements and scope

**What it creates:** `specification.md` (in project root)

**What you define:**
- **Project Scope**
  - What's included
  - What's explicitly excluded
  - Boundaries and constraints
- **Functional Requirements**
  - Features to implement
  - User interactions
  - System behaviors
- **Non-Functional Requirements**
  - Performance (response time, throughput)
  - Scalability (concurrent users, data volume)
  - Security (auth, encryption, compliance)
- **Architecture Overview**
  - High-level components
  - Integration points
  - Data flows
- **Success Criteria**
  - Measurable outcomes
  - Acceptance tests
  - Performance benchmarks

**Example Specification Sections:**

```markdown
# n8n LLM Orchestrator Specification

## Scope

### In Scope
- Multi-agent workflow orchestration using n8n
- Support for ReAct agent pattern with conditional loops
- Integration with Ollama for local LLM execution
- Parse → Tool → Generate workflow pattern
- Error handling and retry logic

### Out of Scope
- Custom LLM fine-tuning
- Multi-tenant support
- Real-time streaming responses

## Functional Requirements

### FR1: Parse Agent
- Extract structured data from user input
- Validate confidence score
- Trigger tool calls when needed

### FR2: Tool Integration
- Support Google Search API
- Handle API rate limits
- Cache results for 24 hours

### FR3: Generate Agent
- Create formatted output
- Support multiple output formats (JSON, Markdown, HTML)

## Non-Functional Requirements

### NFR1: Performance
- Parse agent response time < 2s
- Full workflow completion < 30s
- Support 10 concurrent workflows

### NFR2: Reliability
- 99% uptime
- Automatic retry on transient failures
- Graceful degradation when LLM unavailable
```

---

#### 3️⃣ Create Implementation Plan

**Command:** `/speckit.plan`

**Purpose:** Convert specification into technical plan

**What it creates:** `plan.md` (in project root)

**What you define:**
- **Architecture Decisions**
  - Technology choices and rationale
  - Design patterns
  - Trade-offs considered
- **Technology Stack**
  - Languages, frameworks, libraries
  - Infrastructure components
  - Third-party services
- **Module Breakdown**
  - Components and responsibilities
  - Interfaces between modules
  - Data models
- **Integration Strategy**
  - API contracts
  - Webhook configurations
  - Authentication flows
- **Risk Mitigation**
  - Potential issues
  - Contingency plans
  - Fallback strategies
- **Development Phases**
  - Iterative milestones
  - Dependencies between phases
  - MVP definition

**Example Implementation Plan:**

```markdown
# n8n LLM Orchestrator Implementation Plan

## Architecture Decisions

### Decision 1: n8n as Orchestration Engine
**Rationale:** Visual workflow builder, extensive integrations, built-in error handling
**Alternative Considered:** LangGraph (requires more coding, less accessible)

### Decision 2: Ollama for Local LLM
**Rationale:** Zero API costs, data privacy, low latency
**Alternative Considered:** OpenAI API (higher cost, external dependency)

## Technology Stack

- **Orchestration:** n8n (self-hosted via Docker)
- **LLM:** Ollama with llama3.1:8b
- **Storage:** SQLite for workflow state
- **Monitoring:** n8n built-in execution logs

## Module Breakdown

### Module 1: Parse Agent Workflow
- **Responsibility:** Extract and validate user input
- **Input:** Raw text from webhook
- **Output:** Structured JSON with ingredient + confidence
- **Implementation:** n8n HTTP Request → Ollama API

### Module 2: Tool Execution
- **Responsibility:** Fetch external data when needed
- **Input:** Tool call parameters from Parse Agent
- **Output:** Search results or API response
- **Implementation:** n8n HTTP Request → Google Search API

### Module 3: Generate Agent Workflow
- **Responsibility:** Create final output
- **Input:** Validated data from Parse Agent
- **Output:** Formatted recipe
- **Implementation:** n8n HTTP Request → Ollama API

## Development Phases

### Phase 1: Setup (Week 1)
- Install n8n and Ollama
- Configure basic webhook trigger
- Test connectivity

### Phase 2: Parse Agent (Week 2)
- Implement parse prompt template
- Add JSON validation
- Test with sample inputs

### Phase 3: Tool Integration (Week 3)
- Integrate Google Search API
- Add conditional routing logic
- Implement retry mechanism

### Phase 4: Generate Agent (Week 4)
- Create recipe generation prompt
- Format output
- End-to-end testing

### Phase 5: Production Hardening (Week 5)
- Add comprehensive error handling
- Implement monitoring
- Load testing
```

---

#### 4️⃣ Generate Tasks

**Command:** `/speckit.tasks`

**Purpose:** Break plan into actionable tasks

**What it creates:** `tasks.md` (in project root)

**What you define:**
- **Task List** organized by phase/module
- **Priority Levels** (Critical, High, Medium, Low)
- **Dependencies** between tasks
- **Acceptance Criteria** (definition of done)
- **Estimated Effort** (hours or story points)
- **Status Tracking** (Not Started, In Progress, Completed)

**Example Task Breakdown:**

```markdown
# n8n LLM Orchestrator Tasks

## Phase 1: Setup

### Task 1.1: Install n8n via Docker
- **Priority:** Critical
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] n8n running on localhost:5678
  - [ ] Can access web interface
  - [ ] Data persists after container restart
- **Estimated Effort:** 1 hour
- **Status:** Not Started

### Task 1.2: Install Ollama and Pull Model
- **Priority:** Critical
- **Dependencies:** None
- **Acceptance Criteria:**
  - [ ] Ollama installed and running
  - [ ] llama3.1:8b model downloaded
  - [ ] Can generate response via CLI
- **Estimated Effort:** 30 minutes
- **Status:** Not Started

### Task 1.3: Configure n8n HTTP Node for Ollama
- **Priority:** High
- **Dependencies:** Task 1.1, Task 1.2
- **Acceptance Criteria:**
  - [ ] HTTP Request node configured
  - [ ] Can call Ollama API successfully
  - [ ] Response properly parsed
- **Estimated Effort:** 2 hours
- **Status:** Not Started

## Phase 2: Parse Agent

### Task 2.1: Create Parse Prompt Template
- **Priority:** High
- **Dependencies:** Task 1.3
- **Acceptance Criteria:**
  - [ ] Prompt extracts ingredient accurately
  - [ ] Returns JSON with confidence score
  - [ ] Handles ambiguous inputs
- **Estimated Effort:** 3 hours
- **Status:** Not Started

### Task 2.2: Implement JSON Output Validation
- **Priority:** High
- **Dependencies:** Task 2.1
- **Acceptance Criteria:**
  - [ ] Validates JSON structure
  - [ ] Checks required fields present
  - [ ] Returns error for invalid JSON
- **Estimated Effort:** 2 hours
- **Status:** Not Started

### Task 2.3: Add Error Handling
- **Priority:** Medium
- **Dependencies:** Task 2.2
- **Acceptance Criteria:**
  - [ ] Handles Ollama API timeouts
  - [ ] Retries on transient errors
  - [ ] Logs error details
- **Estimated Effort:** 2 hours
- **Status:** Not Started

## Phase 3: Tool Integration

### Task 3.1: Integrate Google Search API
[... continues ...]
```

---

#### 5️⃣ Execute Implementation

**Command:** `/speckit.implement`

**Purpose:** Implement tasks one by one

**What it does:**
1. Reviews next pending task from `tasks.md`
2. Checks constitution compliance
3. Implements the feature/component
4. Validates against acceptance criteria
5. Marks task complete in `tasks.md`
6. Moves to next task

**Implementation Flow:**

```
1. Load tasks.md
2. Find next "Not Started" task
3. Mark as "In Progress"
4. Implement according to plan
5. Run tests (if applicable)
6. Verify acceptance criteria
7. Mark as "Completed"
8. Update tasks.md
9. Repeat
```

**What gets created:**
- Actual implementation files (Python, n8n workflows, configs)
- Updated `tasks.md` with status changes
- Test files (if TDD principle in constitution)

---

### Optional Enhancement Commands

#### `/speckit.clarify` - De-risk Ambiguities

**When to use:** Before `/speckit.plan`

**Purpose:** Identify and resolve unclear requirements

**What it does:**
- Scans specification for ambiguous language
- Generates structured questions
- Helps make informed decisions early
- Reduces rework later

**Example Questions:**

```markdown
## Clarification Questions

### Q1: LLM Provider Priority
Current spec says "support OpenAI, Anthropic, Ollama"
- Which should be the default?
- What's the fallback order if one fails?
- Should users be able to override per-workflow?

### Q2: Loop Iteration Limit
Spec mentions "ReAct loop" but doesn't specify max iterations
- What's the maximum number of loop iterations?
- What happens when limit is reached?
- Should limit be configurable?

### Q3: State Persistence
Not clear if agent state persists across workflow runs
- Should state be saved to database?
- How long should state be retained?
- Is state shared across workflow instances?
```

**Output:** Answers are incorporated into specification before planning

---

#### `/speckit.checklist` - Validate Requirements

**When to use:** After `/speckit.plan`

**Purpose:** Ensure completeness and consistency

**What it checks:**
- All functional requirements have acceptance criteria
- Non-functional requirements are measurable
- Error scenarios documented
- Security considerations addressed
- Performance benchmarks specified
- Dependencies identified

**Example Checklist:**

```markdown
## Requirements Quality Checklist

### Completeness
- ✅ All functional requirements defined
- ✅ Non-functional requirements specified
- ❌ Performance benchmarks missing
- ✅ Error scenarios documented
- ⚠️  Partial security requirements (auth missing)

### Consistency
- ✅ Terminology consistent across docs
- ✅ No conflicting requirements
- ✅ Constitution principles reflected

### Testability
- ✅ Acceptance criteria defined for each requirement
- ⚠️  Some criteria not measurable ("should be fast")
- ✅ Test scenarios outlined

### Action Items
1. Add performance benchmarks for each API call
2. Specify authentication mechanism
3. Make acceptance criteria measurable (define "fast")
```

---

#### `/speckit.analyze` - Check Consistency

**When to use:** After `/speckit.tasks`, before `/speckit.implement`

**Purpose:** Cross-artifact consistency validation

**What it validates:**
- Tasks map to plan items
- Plan items align with specification
- Specification respects constitution
- No orphaned requirements
- No contradictions

**Example Analysis Report:**

```markdown
## Consistency Analysis Report

### Constitution ↔ Specification
✅ Spec respects "Visual-First Design" principle
✅ "LLM-Agnostic" reflected in requirements
❌ Constitution requires "Test-First" but spec has no test requirements

### Specification ↔ Plan
✅ All functional requirements covered in plan
⚠️  NFR1 (performance) not addressed in architecture
✅ Technology choices align with constraints

### Plan ↔ Tasks
✅ All plan phases have corresponding tasks
❌ Task 3.2 references "PostgreSQL" but plan uses "SQLite"
✅ Dependencies properly sequenced

### Terminology Consistency
⚠️  "workflow" vs "agent" used interchangeably
⚠️  "response time" vs "latency" - standardize

### Recommendations
1. Add test tasks to comply with constitution
2. Add performance optimization phase to plan
3. Update Task 3.2 to use SQLite
4. Standardize terminology across all docs
```

---

## Project File Structure

```
n8n-llm-orchestrator/
├── .claude/
│   └── commands/               # Slash command definitions
│       ├── speckit.constitution.md
│       ├── speckit.specify.md
│       ├── speckit.plan.md
│       ├── speckit.tasks.md
│       ├── speckit.implement.md
│       ├── speckit.clarify.md
│       ├── speckit.checklist.md
│       └── speckit.analyze.md
├── .specify/
│   ├── memory/
│   │   └── constitution.md     # Filled template
│   ├── templates/              # Document templates
│   │   ├── spec-template.md
│   │   ├── plan-template.md
│   │   ├── tasks-template.md
│   │   └── checklist-template.md
│   └── scripts/bash/           # Helper scripts
├── .gitignore                  # Excludes .claude/
├── specification.md            # Created by /speckit.specify
├── plan.md                     # Created by /speckit.plan
├── tasks.md                    # Created by /speckit.tasks
└── [implementation files]      # Created by /speckit.implement
```

---

## Best Practices

### 1. Follow the Sequence
Don't skip steps - each builds on previous:
```
Constitution → Specify → Plan → Tasks → Implement
```

### 2. Keep Constitution Lightweight
- **3-7 principles** is ideal
- Make principles **testable** and **enforceable**
- Use "MUST" for requirements, "SHOULD" for recommendations
- Avoid vague language

### 3. Iterate on Specification
- Start high-level
- Refine as you learn
- Don't over-specify upfront

### 4. Break Tasks Small
- **1-4 hours** per task
- Clear acceptance criteria
- Explicit dependencies

### 5. Use Enhancement Commands Strategically
- `/speckit.clarify` when requirements vague
- `/speckit.checklist` after planning
- `/speckit.analyze` before implementing

### 6. Keep Documents in Sync
- Constitution changes trigger version bumps
- Spec updates may require plan updates
- Use `/speckit.analyze` to catch drift

---

## Quick Reference

| Command | When | Creates | Purpose |
| :--- | :--- | :--- | :--- |
| `/speckit.constitution` | First | `constitution.md` | Define principles |
| `/speckit.specify` | After constitution | `specification.md` | Write requirements |
| `/speckit.clarify` | Before plan (optional) | Inline Q&A | Resolve ambiguities |
| `/speckit.plan` | After specify | `plan.md` | Technical design |
| `/speckit.checklist` | After plan (optional) | Inline checklist | Validate quality |
| `/speckit.tasks` | After plan | `tasks.md` | Break down work |
| `/speckit.analyze` | Before implement (optional) | Inline report | Check consistency |
| `/speckit.implement` | Last | Code files | Execute tasks |

---

## Try It Now!

Start your Spec-Driven Development journey:

```
/speckit.constitution
```

Define your project principles and let Claude Code guide you through building a robust, well-specified agentic AI system!


## 📋 n8n for Agentic AI Orchestration

### Overview

**n8n** is a powerful, open-source workflow automation platform that excels at orchestrating complex agentic AI processes. Unlike code-based frameworks like LangGraph, n8n provides a visual, low-code interface for designing and managing multi-agent workflows, making it ideal for rapid prototyping and production-grade orchestration.

**Website**: https://n8n.io
**Self-hosted**: Docker, npm, or cloud deployment
**Key Strength**: Visual workflow builder with extensive integrations

### Why n8n for Agentic AI?

| Feature | Benefit for Agentic Systems |
| :--- | :--- |
| **Visual Flow Design** | See the entire agent workflow at a glance, making complex orchestration understandable |
| **State Management** | Built-in data passing between nodes maintains context across agent calls |
| **Error Handling** | Native retry logic, fallback paths, and error routing |
| **Integration Hub** | 400+ pre-built nodes for APIs, databases, LLMs, vector stores, and tools |
| **HTTP Webhooks** | Easy external triggers for event-driven agent activation |
| **Conditional Logic** | IF/Switch nodes enable dynamic routing based on agent outputs |
| **Loops & Iterations** | Process batches, iterate over results, or implement ReAct loops |
| **Human-in-the-Loop** | Wait-for-approval nodes for critical decisions |

### Core Architecture for Agentic Workflows

#### 1. Node Types for Agent Orchestration

| Node Type | Purpose in Agentic System | Example Use Case |
| :--- | :--- | :--- |
| **HTTP Request** | Call LLM APIs (OpenAI, Anthropic, Ollama) | Invoke Claude for reasoning step |
| **AI Agent Node** | Native LangChain/AI agent integration | Run pre-configured autonomous agent |
| **Code Node** | Custom logic in JavaScript/Python | Parse JSON, validate outputs, format prompts |
| **IF/Switch** | Conditional routing | Route based on agent confidence score |
| **Loop Node** | Iterative processing | ReAct loop until task completion |
| **Set/Merge** | Data transformation | Aggregate multi-agent responses |
| **Wait** | Delay or human approval | Pause for user confirmation |
| **Webhook** | External triggers | Receive events from Slack, email, APIs |

#### 2. State Management Pattern

n8n passes data between nodes using a JSON object. For agentic workflows, structure your state similar to LangGraph:

```json
{
  "messages": [
    {"role": "user", "content": "Find me a recipe"},
    {"role": "assistant", "content": "...", "tool_calls": [...]}
  ],
  "extracted_data": {
    "ingredient": "tomato",
    "confidence": 0.95
  },
  "workflow_status": "awaiting_generation",
  "iteration_count": 2
}
```

**Best Practice**: Use **Set Node** to initialize state, and **Merge Node** to combine outputs from parallel agents.

#### 3. Common Agentic Orchestration Patterns

##### Pattern A: Sequential Agent Pipeline

```
Trigger → Agent 1 (Parse) → Agent 2 (Validate) → Agent 3 (Generate) → Output
```

**Use case**: Each agent has a distinct role and must run in sequence.

##### Pattern B: Conditional ReAct Loop

```
Trigger → Parse Agent → IF (needs_tool?)
                          ├─ YES → Tool Execution → Loop back to Parse Agent
                          └─ NO → Generate Agent → Output
```

**Use case**: Agent decides if it needs more information (similar to LangGraph example).

##### Pattern C: Multi-Agent Consensus

```
Trigger → Split into 3 parallel agents (Agent A, B, C)
       → Merge Results
       → Consensus Logic (Code Node)
       → Final Decision
```

**Use case**: Multiple specialized agents analyze the same input, and a consensus mechanism decides the final output.

##### Pattern D: Human-in-the-Loop Orchestration

```
Trigger → Agent 1 → IF (confidence < 0.8?)
                     ├─ YES → Send Slack notification → Wait for approval → Continue
                     └─ NO → Proceed to Agent 2
```

**Use case**: High-stakes decisions require human review before proceeding.

### Key n8n Nodes for LLM Integration

| Node Name | What It Does | Configuration |
| :--- | :--- | :--- |
| **OpenAI** | Call GPT models, embeddings, DALL-E | API key, model selection, prompt |
| **Anthropic** | Call Claude models | API key, model (Claude 3.5 Sonnet, etc.) |
| **HTTP Request** | Call any LLM API (Ollama, Groq, etc.) | Custom endpoint, headers, JSON body |
| **AI Agent** | LangChain-powered agent with tools | Define tools, memory, and prompt |
| **Vector Store** | Pinecone, Weaviate, Qdrant integration | Store/retrieve embeddings for RAG |
| **Embeddings** | Generate embeddings for semantic search | OpenAI, Cohere, HuggingFace |

### Example Workflow: n8n Recipe Orchestrator

Replicating the LangGraph Recipe Assistant in n8n:

1. **Webhook Trigger** → User sends ingredient via HTTP POST
2. **OpenAI Node (Parse Agent)** → Extract and validate ingredient with function calling
3. **IF Node** → Check if `tool_calls` exist in response
   - **YES** → Route to Google Search node
   - **NO** → Route to Generate node
4. **HTTP Request (Google Search Tool)** → Fetch ingredient info
5. **Loop Back** → Pass search result back to OpenAI Parse Agent (set max iterations = 3)
6. **OpenAI Node (Generate Agent)** → Create final recipe
7. **Response Node** → Return formatted recipe

**Advantages over pure code**:
- Visualize the loop structure instantly
- Easily add error handling (what if API fails?)
- Add human review step without refactoring
- Monitor live executions with built-in logging

### Production Considerations

| Aspect | Best Practice |
| :--- | :--- |
| **Error Handling** | Add error branches to every LLM node (network failures, rate limits) |
| **Timeouts** | Set appropriate timeout values for long-running agent calls |
| **Retries** | Configure exponential backoff for transient API failures |
| **Rate Limiting** | Use "Wait" nodes to avoid hitting API rate limits |
| **Logging** | Enable execution data retention for debugging agent behavior |
| **Security** | Store API keys in n8n credentials, not hardcoded in workflows |
| **Versioning** | Export workflows as JSON and commit to version control |
| **Testing** | Use manual triggers and test mode before enabling webhooks |

### n8n vs LangGraph: When to Use Each

| Scenario | Use n8n | Use LangGraph |
| :--- | :--- | :--- |
| **Rapid prototyping** | ✅ Visual builder is faster | ❌ Requires coding |
| **Complex state logic** | ⚠️ Can get messy with many branches | ✅ Code provides better control |
| **Team collaboration** | ✅ Non-engineers can modify workflows | ❌ Requires Python knowledge |
| **Integration-heavy** | ✅ 400+ pre-built integrations | ⚠️ Manual API integration |
| **Advanced memory** | ⚠️ Limited built-in memory options | ✅ Full control over state |
| **Version control** | ⚠️ JSON exports (less readable) | ✅ Native Git integration |
| **Production scale** | ✅ Self-hosted with queue support | ✅ Lightweight, embeddable |

**Recommendation**: Start with **n8n** for MVPs and proof-of-concepts, then migrate to **LangGraph** if you need fine-grained control or want to embed the workflow in a larger application.

### Getting Started with n8n

#### Quick Start (Docker)

```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

Access at: http://localhost:5678

#### Self-Hosted (npm)

```bash
npm install n8n -g
n8n start
```

#### Cloud Option

Sign up at: https://n8n.cloud (free tier available)

### Learning Resources

- **Official Docs**: https://docs.n8n.io
- **AI Agent Templates**: https://n8n.io/workflows/?categories=AI
- **Community Forum**: https://community.n8n.io
- **LangChain Integration**: https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.ai-agent/

### Next Steps

1. Install n8n locally or use cloud version
2. Import a starter AI agent workflow from the template library
3. Connect your OpenAI/Anthropic API keys
4. Experiment with conditional routing and loops
5. Build your first multi-agent orchestration system

---

## 🤖 Ollama - Local LLM Infrastructure for Agentic AI

### Overview

**Ollama** is a lightweight, open-source tool that enables you to run large language models (LLMs) locally on your own hardware. For agentic AI systems, Ollama provides a cost-effective, privacy-preserving, and low-latency alternative to cloud-based LLM APIs.

**Website**: https://ollama.com
**GitHub**: https://github.com/ollama/ollama
**Key Strength**: Run powerful LLMs locally without API costs or internet dependency

### Why Ollama for Agentic AI?

| Feature | Benefit for Agentic Systems |
| :--- | :--- |
| **Zero API Costs** | Run unlimited agent iterations without per-token charges |
| **Data Privacy** | Keep sensitive data local - no external API calls |
| **Low Latency** | No network overhead for agent-to-LLM communication |
| **Offline Capability** | Agents work without internet connection |
| **Model Flexibility** | Easily switch between models (Llama, Mistral, Gemma, etc.) |
| **Reproducibility** | Consistent model versions across development and production |
| **Fine-tuning Ready** | Use custom-trained models for specialized agents |
| **Development Speed** | Rapid iteration without rate limits |

### Supported Models for Agentic Workflows

#### Recommended Models by Use Case

| Model | Size | Use Case | Performance |
| :--- | :--- | :--- | :--- |
| **Llama 3.1 (8B)** | ~5GB | General-purpose agents | Fast, good reasoning |
| **Llama 3.1 (70B)** | ~40GB | Complex multi-step tasks | Excellent reasoning |
| **Mistral (7B)** | ~4GB | Fast agent responses | Very fast, decent quality |
| **Mixtral (8x7B)** | ~26GB | Multi-agent orchestration | Strong reasoning, balanced |
| **Gemma 2 (9B)** | ~5.5GB | Code generation agents | Good for technical tasks |
| **Qwen 2.5 (7B)** | ~4GB | Structured output agents | Excellent JSON/tool calling |
| **DeepSeek Coder (6.7B)** | ~4GB | Code-focused agents | Best for coding tasks |
| **Phi-3 (3.8B)** | ~2.3GB | Resource-constrained systems | Fast, lightweight |

**Note**: Model size affects RAM usage. For agentic systems with multiple concurrent agents, plan for 1.5x-2x the model size in available RAM.

### Installation

#### Quick Install

**macOS/Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:**
Download from https://ollama.com/download/windows

**Docker:**
```bash
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

### Getting Started

#### 1. Pull a Model

```bash
# Download Llama 3.1 8B (recommended starting point)
ollama pull llama3.1:8b

# Or other popular models
ollama pull mistral
ollama pull qwen2.5:7b
ollama pull deepseek-coder:6.7b
```

#### 2. Test the Model

```bash
# Interactive chat
ollama run llama3.1:8b

# Single prompt
ollama run llama3.1:8b "Explain ReAct agent pattern in 3 sentences"
```

#### 3. Check Running Models

```bash
# List available models
ollama list

# Show model info
ollama show llama3.1:8b

# Stop a model to free memory
ollama stop llama3.1:8b
```

### Ollama API for Agentic Systems

Ollama provides an OpenAI-compatible REST API on `http://localhost:11434`.

#### Python Integration Example

```python
import requests
import json

def call_local_llm(prompt, model="llama3.1:8b"):
    """Call Ollama API for agent reasoning step"""
    url = "http://localhost:11434/api/generate"

    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }

    response = requests.post(url, json=payload)
    return response.json()["response"]

# Example: Parse Agent
user_input = "I want a recipe with aubergine"
parse_prompt = f"""Extract the main ingredient from: {user_input}
Return JSON: {{"ingredient": "...", "confidence": 0.0-1.0}}"""

result = call_local_llm(parse_prompt)
print(result)
```

#### Using with LangChain

```python
from langchain_community.llms import Ollama
from langchain.agents import initialize_agent, Tool
from langchain.agents import AgentType

# Initialize Ollama LLM
llm = Ollama(model="llama3.1:8b", temperature=0.7)

# Define tools for agent
tools = [
    Tool(
        name="Search",
        func=lambda q: "Aubergine is another name for eggplant",
        description="Search for ingredient information"
    )
]

# Create agent with local LLM
agent = initialize_agent(
    tools=tools,
    llm=llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True
)

# Run agent
result = agent.run("What is aubergine?")
```

#### Using with n8n

In n8n workflows, use the **HTTP Request** node with Ollama:

**Configuration:**
- Method: POST
- URL: `http://localhost:11434/api/generate`
- Body:
```json
{
  "model": "llama3.1:8b",
  "prompt": "{{ $json.user_input }}",
  "stream": false
}
```

### Multi-Agent Architecture with Ollama

#### Pattern: Specialized Local Agents

Run different models for different agent roles:

```python
agents = {
    "parser": Ollama(model="qwen2.5:7b"),      # Best for structured output
    "reasoner": Ollama(model="llama3.1:70b"),  # Deep reasoning
    "coder": Ollama(model="deepseek-coder"),   # Code generation
    "summarizer": Ollama(model="mistral")      # Fast summaries
}

# Route tasks to specialized agents
def route_task(task_type, prompt):
    agent = agents[task_type]
    return agent(prompt)
```

#### Pattern: Parallel Agent Execution

Since Ollama runs locally, you can run multiple agents in parallel (limited by hardware):

```python
import concurrent.futures

def parallel_agents(prompt):
    """Run 3 agents in parallel and aggregate results"""
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        futures = {
            executor.submit(call_local_llm, prompt, "llama3.1:8b"): "agent_1",
            executor.submit(call_local_llm, prompt, "mistral"): "agent_2",
            executor.submit(call_local_llm, prompt, "qwen2.5:7b"): "agent_3"
        }

        results = {}
        for future in concurrent.futures.as_completed(futures):
            agent_name = futures[future]
            results[agent_name] = future.result()

        return results

# Use case: Multi-agent consensus
responses = parallel_agents("Is tomato a fruit or vegetable?")
```

### Function Calling & Tool Use

Recent models like Llama 3.1, Mistral, and Qwen 2.5 support function calling:

```python
import json

def ollama_with_tools(prompt, tools):
    """Call Ollama with tool/function definitions"""
    url = "http://localhost:11434/api/chat"

    payload = {
        "model": "llama3.1:8b",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "tools": tools,
        "stream": False
    }

    response = requests.post(url, json=payload)
    return response.json()

# Define tools for agent
tools = [
    {
        "type": "function",
        "function": {
            "name": "search_ingredient",
            "description": "Search for information about an ingredient",
            "parameters": {
                "type": "object",
                "properties": {
                    "ingredient": {
                        "type": "string",
                        "description": "The ingredient to search for"
                    }
                },
                "required": ["ingredient"]
            }
        }
    }
]

result = ollama_with_tools("What is aubergine?", tools)
```

### Performance Optimization

#### 1. Model Quantization

Ollama uses quantized models by default (Q4_0 format). For better performance:

```bash
# Standard 4-bit quantization (default)
ollama pull llama3.1:8b

# Higher quality 8-bit (slower, more accurate)
ollama pull llama3.1:8b-q8_0

# Smaller 2-bit (faster, less accurate)
ollama pull llama3.1:8b-q2_k
```

#### 2. GPU Acceleration

Ollama automatically uses GPU if available (CUDA, Metal, ROCm).

Check GPU usage:
```bash
# Monitor GPU while running agents
nvidia-smi -l 1  # NVIDIA
```

#### 3. Context Window Management

For agentic workflows with long conversations:

```python
# Keep last N messages to stay within context window
def trim_context(messages, max_tokens=4096):
    # Implement token counting and trimming
    return messages[-10:]  # Simple approach: keep last 10 messages
```

### Production Considerations

| Aspect | Best Practice |
| :--- | :--- |
| **Resource Planning** | Allocate 2x model size in RAM; use GPU for 7B+ models |
| **Model Loading** | Pre-load models at startup to avoid cold-start delays |
| **Concurrency** | Limit concurrent requests based on hardware (typically 1-3) |
| **Timeout Handling** | Set reasonable timeouts (30-120s for complex reasoning) |
| **Model Updates** | Pin specific model versions for reproducibility |
| **Monitoring** | Track inference time, memory usage, and output quality |
| **Fallback Strategy** | Have cloud API fallback if local inference fails |
| **Security** | Run Ollama in isolated network segment for production |

### Ollama vs Cloud APIs: Cost Analysis

**Example Scenario**: Recipe assistant with 10,000 daily requests

| Provider | Cost Model | Monthly Cost |
| :--- | :--- | :--- |
| **OpenAI GPT-4** | $10/1M input tokens | ~$3,000 |
| **Anthropic Claude** | $3/1M input tokens | ~$900 |
| **Ollama (8GB GPU Server)** | One-time hardware + electricity | ~$50/month |

**Break-even**: After 1-2 months, local Ollama becomes cost-effective for high-volume agentic systems.

### Integration with LangGraph

```python
from langgraph.graph import StateGraph, END
from langchain_community.llms import Ollama

# Define state
class AgentState(TypedDict):
    messages: list
    ingredient: str

# Initialize local LLM
llm = Ollama(model="llama3.1:8b")

# Define nodes with local LLM
def parse_node(state):
    prompt = f"Extract ingredient from: {state['messages'][-1]}"
    response = llm.invoke(prompt)
    return {"ingredient": response}

# Build graph with local Ollama
graph = StateGraph(AgentState)
graph.add_node("parse", parse_node)
graph.add_edge("parse", END)
```

### Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Out of memory** | Use smaller model (3B/7B) or increase system RAM |
| **Slow inference** | Enable GPU, use smaller model, or reduce context length |
| **Model not found** | Run `ollama pull <model>` to download |
| **Connection refused** | Check if Ollama is running: `ollama serve` |
| **Poor output quality** | Try larger model (70B) or fine-tune for your use case |

### Learning Resources

- **Official Docs**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **Model Library**: https://ollama.com/library
- **Discord Community**: https://discord.gg/ollama
- **LangChain Integration**: https://python.langchain.com/docs/integrations/llms/ollama

### Next Steps

1. Install Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
2. Download a starter model: `ollama pull llama3.1:8b`
3. Test with simple prompt: `ollama run llama3.1:8b "Hello"`
4. Integrate with your agentic framework (LangChain, LangGraph, or n8n)
5. Experiment with different models for different agent roles
6. Monitor performance and optimize based on your use case

---

## 🧠 RAG Implementation Strategy for n8n

### Overview

**Retrieval-Augmented Generation (RAG)** is a powerful technique that combines the strengths of retrieval-based systems with generative AI. Instead of putting all documents into the LLM prompt (which is limited by context window), RAG retrieves only the most relevant information from a knowledge base and uses it to augment the prompt.

**Key Advantage**: Enables agents to work with massive document collections (millions of documents) while staying within LLM context limits.

### Why RAG for Agentic AI?

| Challenge | RAG Solution |
| :--- | :--- |
| **Context Window Limits** | Only retrieve top-k relevant chunks (e.g., top 5 out of 10,000) |
| **Outdated LLM Knowledge** | Query real-time, up-to-date knowledge bases |
| **Hallucination** | Ground responses in retrieved factual content |
| **Cost** | Smaller prompts = lower token costs |
| **Specialized Knowledge** | Access domain-specific documents not in LLM training data |
| **Source Attribution** | Cite which documents were used for the answer |

---

### RAG Architecture in n8n

#### Core Components

```
User Query
    ↓
[1. Embedding Generation]     ← Convert query to vector
    ↓
[2. Vector Search]            ← Find similar document chunks
    ↓
[3. Context Retrieval]        ← Fetch top-k relevant chunks
    ↓
[4. Prompt Augmentation]      ← Add chunks to LLM prompt
    ↓
[5. LLM Generation]           ← Generate answer with context
    ↓
Response + Source Citations
```

---

### Key n8n Nodes for RAG

| Node | Purpose | Configuration |
| :--- | :--- | :--- |
| **Ollama Embeddings** | Convert text to vector embeddings | Model: `nomic-embed-text`, Dimensions: 768 |
| **Vector Store (Qdrant)** | Store and search document embeddings | Local: `http://localhost:6333` |
| **Supabase Vector Store** | Alternative vector DB (cloud-hosted) | Connection string + API key |
| **Pinecone** | Cloud vector database | API key + index name |
| **Document Loader** | Load files (PDF, CSV, TXT, Markdown) | File path or URL |
| **Text Splitter** | Chunk documents into smaller pieces | Chunk size: 500-1000 characters |
| **HTTP Request** | Call Ollama for embeddings/generation | Ollama API endpoint |
| **Code Node** | Custom retrieval logic | JavaScript/Python |

---

### RAG Implementation Patterns

#### Pattern 1: Basic RAG Pipeline

**Use case**: Simple question-answering over document collection

**n8n Workflow:**

```
1. Webhook Trigger (User submits question)
2. Ollama Embeddings Node (Convert question to vector)
3. Qdrant Vector Store Node (Search for similar chunks)
   - Action: "Retrieve Documents"
   - Top K: 5
4. Code Node (Format context from retrieved chunks)
5. HTTP Request Node (Call Ollama with augmented prompt)
   - Prompt: "Based on these documents: [chunks], answer: [question]"
6. Response Node (Return answer with sources)
```

**Example:**

```json
{
  "question": "How do I install Qdrant?",
  "retrieved_chunks": [
    {"text": "docker run -p 6333:6333 qdrant/qdrant", "source": "docs.md", "score": 0.92},
    {"text": "Qdrant can be run locally...", "source": "quickstart.md", "score": 0.87}
  ],
  "answer": "To install Qdrant, run: docker run -p 6333:6333 qdrant/qdrant",
  "sources": ["docs.md", "quickstart.md"]
}
```

---

#### Pattern 2: Document Ingestion Pipeline

**Use case**: Index documents into vector database (one-time or periodic)

**n8n Workflow:**

```
1. Schedule Trigger (Daily at 2 AM)
2. Read Files Node (Load documents from folder)
3. Text Splitter Node (Chunk documents)
   - Chunk Size: 800 characters
   - Chunk Overlap: 200 characters
4. Loop Node (For each chunk):
   a. Ollama Embeddings Node (Generate vector)
   b. Qdrant Vector Store Node (Insert into DB)
      - Action: "Insert Documents"
      - Collection: "knowledge_base"
5. Notification (Send completion email)
```

**Document Chunking Strategy:**

```javascript
// Code Node: Custom chunking logic
const chunks = [];
const chunkSize = 800;
const overlap = 200;

for (let i = 0; i < text.length; i += (chunkSize - overlap)) {
  chunks.push({
    text: text.slice(i, i + chunkSize),
    metadata: {
      source: fileName,
      chunk_id: chunks.length,
      timestamp: new Date().toISOString()
    }
  });
}

return chunks;
```

---

#### Pattern 3: RAG with Re-ranking

**Use case**: Improve retrieval quality by re-ranking results

**n8n Workflow:**

```
1. Webhook Trigger
2. Ollama Embeddings (Query vector)
3. Qdrant Vector Store (Retrieve top 20 candidates)
4. Code Node (Re-rank using cross-encoder)
   - Calculate relevance scores
   - Sort by score
   - Return top 5
5. HTTP Request (Ollama with refined context)
6. Response
```

**Re-ranking Logic:**

```javascript
// Code Node: Re-rank retrieved chunks
const rerank = (query, chunks) => {
  return chunks.map(chunk => {
    // Simple keyword overlap scoring (use ML model for better results)
    const queryWords = query.toLowerCase().split(' ');
    const chunkWords = chunk.text.toLowerCase().split(' ');
    const overlap = queryWords.filter(w => chunkWords.includes(w)).length;

    return {
      ...chunk,
      relevance_score: overlap / queryWords.length
    };
  }).sort((a, b) => b.relevance_score - a.relevance_score);
};

const reranked = rerank($json.query, $json.chunks).slice(0, 5);
return reranked;
```

---

#### Pattern 4: Multi-Agent RAG

**Use case**: Different agents query different knowledge bases

**n8n Workflow:**

```
1. Webhook Trigger (User question + domain)
2. Switch Node (Route by domain)
   Case "technical":
     → Qdrant Collection "tech_docs"
     → Ollama llama3.1:8b
   Case "legal":
     → Qdrant Collection "legal_docs"
     → Ollama qwen2.5:7b (better for structured text)
   Case "creative":
     → Qdrant Collection "creative_writing"
     → Ollama mistral
3. RAG Pipeline (per domain)
4. Merge Results
5. Response
```

---

### Setting Up Qdrant Locally

#### 1. Install Qdrant via Docker

```bash
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -p 6334:6334 \
  -v $(pwd)/qdrant_storage:/qdrant/storage \
  qdrant/qdrant
```

**Access:**
- **REST API**: http://localhost:6333
- **Dashboard**: http://localhost:6333/dashboard

#### 2. Create Collection

```bash
curl -X PUT 'http://localhost:6333/collections/knowledge_base' \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 768,
      "distance": "Cosine"
    }
  }'
```

#### 3. Configure in n8n

**Vector Store Node Settings:**
- **Action**: "Insert Documents" or "Retrieve Documents"
- **Qdrant URL**: `http://localhost:6333`
- **Collection Name**: `knowledge_base`
- **Distance Metric**: Cosine (best for embeddings)

---

### Ollama Embeddings Configuration

#### Install Embedding Model

```bash
# Pull nomic-embed-text (768 dimensions, optimized for RAG)
ollama pull nomic-embed-text

# Or use mxbai-embed-large (1024 dimensions, higher quality)
ollama pull mxbai-embed-large
```

#### Generate Embeddings in n8n

**HTTP Request Node Configuration:**

```json
{
  "method": "POST",
  "url": "http://localhost:11434/api/embeddings",
  "body": {
    "model": "nomic-embed-text",
    "prompt": "{{ $json.text }}"
  }
}
```

**Response:**

```json
{
  "embedding": [0.123, -0.456, 0.789, ...],  // 768-dimensional vector
  "model": "nomic-embed-text"
}
```

---

### Complete RAG Example Workflow

#### Indexing Documents

```
[Manual Trigger]
    ↓
[Read Binary Files] (PDFs from /docs folder)
    ↓
[Loop Over Files]
    ↓
[Extract Text from PDF]
    ↓
[Split Text] (Chunk size: 800, Overlap: 200)
    ↓
[Loop Over Chunks]
    ↓
[HTTP Request - Ollama Embeddings]
    ↓
[Qdrant Insert] (Store chunk + embedding + metadata)
    ↓
[Set Variable] (Track progress)
```

#### Querying with RAG

```
[Webhook Trigger] (POST /ask with query)
    ↓
[HTTP Request - Ollama Embeddings] (Query vector)
    ↓
[Qdrant Retrieve] (Top 5 similar chunks)
    ↓
[Code Node] (Format context)
    ↓
[Set Variable] (Build augmented prompt)
    ↓
[HTTP Request - Ollama Generate]
    Prompt: "Based on the following context:\n\n
    {{ $json.context }}\n\n
    Answer this question: {{ $json.query }}\n
    If the context doesn't contain the answer, say 'I don't know'."
    ↓
[Code Node] (Format response with sources)
    ↓
[Respond to Webhook]
```

**Augmented Prompt Example:**

```
Based on the following context:

---
[Source: quickstart.md | Score: 0.92]
Qdrant can be run locally using Docker. Run: docker run -p 6333:6333 qdrant/qdrant

[Source: api-reference.md | Score: 0.87]
To create a collection, use the PUT /collections/{name} endpoint with vector size config.

[Source: deployment.md | Score: 0.85]
For production, run Qdrant in cluster mode with multiple replicas.
---

Answer this question: How do I install Qdrant locally?

If the context doesn't contain the answer, say "I don't know based on the available documentation."
```

---

### Common Challenges and Solutions

#### Challenge 1: Poor Retrieval Quality

**Symptoms:**
- Retrieved chunks are not relevant
- Answer quality is low
- Missing obvious information

**Solutions:**

| Problem | Solution |
| :--- | :--- |
| Query too vague | Use query expansion (rephrase query 3 ways, search all) |
| Wrong embedding model | Try different models (nomic vs mxbai vs e5) |
| Chunk size mismatch | Experiment: 500, 800, 1000, 1500 characters |
| No metadata filtering | Add filters (e.g., only search docs from last 30 days) |
| Distance metric wrong | Try Cosine, Euclidean, Dot Product |

**Query Expansion Example:**

```javascript
// Code Node: Generate query variations
const expandQuery = (query) => {
  return [
    query,  // Original
    `How to ${query}`,  // Instructional
    `${query} explanation`,  // Explanatory
    `${query} example`  // Example-seeking
  ];
};
```

---

#### Challenge 2: Context Window Overflow

**Symptoms:**
- Too many chunks retrieved
- Prompt exceeds token limit
- LLM truncates context

**Solutions:**

| Strategy | Implementation |
| :--- | :--- |
| Reduce top-k | Retrieve 3-5 chunks instead of 10+ |
| Compress chunks | Summarize each chunk before adding to prompt |
| Hierarchical RAG | First retrieve high-level, then drill down |
| Sliding window | Process chunks in batches with overlapping context |

---

#### Challenge 3: Slow Query Performance

**Symptoms:**
- Retrieval takes > 2 seconds
- Workflow times out
- Poor user experience

**Solutions:**

| Optimization | Impact |
| :--- | :--- |
| Use smaller embedding model | 2-3x faster (nomic-embed-text vs mxbai) |
| Reduce vector dimensions | Use PCA to compress from 1024 to 512 |
| Add indices in Qdrant | Create HNSW index for faster search |
| Cache frequent queries | Store popular query results for 1 hour |
| Parallel searches | Search multiple collections simultaneously |

**Caching Strategy (Code Node):**

```javascript
// Simple in-memory cache with TTL
const cache = {};
const TTL = 3600000; // 1 hour

const getCachedOrFetch = async (query, fetchFn) => {
  const key = query.toLowerCase();
  const now = Date.now();

  if (cache[key] && (now - cache[key].timestamp < TTL)) {
    return cache[key].result;
  }

  const result = await fetchFn();
  cache[key] = { result, timestamp: now };
  return result;
};
```

---

#### Challenge 4: Hallucination Despite Context

**Symptoms:**
- LLM makes up facts not in retrieved docs
- Contradicts source material
- Ignores context entirely

**Solutions:**

| Technique | Effectiveness |
| :--- | :--- |
| Constrain prompt | "ONLY use the provided context. If not found, say 'I don't know'." | High |
| Lower temperature | Set to 0.1-0.3 for more factual responses | High |
| Citation requirement | Force LLM to cite source for each claim | Medium |
| Post-processing validation | Check if answer terms appear in context | Medium |
| Use instruction-tuned models | Llama 3.1 Instruct, Mistral Instruct | High |

**Constrained Prompt Template:**

```
You are a helpful assistant that ONLY answers based on the provided context.

CONTEXT:
{{ context }}

RULES:
1. ONLY use information from the CONTEXT above
2. If the answer is not in the context, respond with "I don't have that information in the provided documents."
3. Cite the source document for each fact: [Source: filename.md]
4. Do not make assumptions or add information not in the context

QUESTION: {{ question }}

ANSWER:
```

---

#### Challenge 5: Embedding Model Quality

**Symptoms:**
- Semantically similar queries don't match
- Keyword matches work better than semantic search
- Foreign language support poor

**Solutions:**

| Model | Best For | Dimensions |
| :--- | :--- | :--- |
| **nomic-embed-text** | General English, fast | 768 |
| **mxbai-embed-large** | High quality, slower | 1024 |
| **e5-large-v2** | Multilingual | 1024 |
| **gte-large** | Technical docs | 1024 |
| **bge-large-en** | Long documents | 1024 |

**Testing Embedding Quality:**

```javascript
// Code Node: Test embedding similarity
const cosineSimilarity = (a, b) => {
  const dot = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dot / (magA * magB);
};

// Test cases
const testPairs = [
  ["install qdrant", "how to setup qdrant"],  // Should be high (0.8+)
  ["install qdrant", "python syntax"],        // Should be low (0.2-)
];

// Generate embeddings and compare
```

---

### Production Best Practices

| Aspect | Recommendation |
| :--- | :--- |
| **Collection Management** | Separate collections by domain/use case |
| **Metadata** | Store: source, timestamp, author, version, tags |
| **Monitoring** | Track: retrieval latency, relevance scores, user feedback |
| **Updates** | Incremental updates: upsert changed docs, delete old |
| **Backup** | Regular Qdrant snapshots (use snapshot API) |
| **Scaling** | Shard collections > 1M vectors across multiple nodes |
| **Security** | Use Qdrant API keys, network isolation |
| **Testing** | Maintain evaluation dataset with query-answer pairs |

---

### RAG Evaluation Metrics

Track these metrics to measure RAG quality:

```javascript
// Code Node: Calculate RAG metrics
const metrics = {
  // Retrieval Metrics
  recall_at_k: (retrieved, relevant) => {
    return relevant.filter(r => retrieved.includes(r)).length / relevant.length;
  },

  // Generation Metrics
  answer_relevance: (answer, question) => {
    // Use LLM to judge if answer addresses question (0-1 score)
  },

  // Groundedness
  citation_rate: (answer, sources) => {
    // Percentage of claims that can be traced to sources
  },

  // User Experience
  latency_p95: (measurements) => {
    // 95th percentile response time
  }
};
```

---

### Alternative Vector Databases

| Database | Pros | Cons | Best For |
| :--- | :--- | :--- | :--- |
| **Qdrant** | Self-hosted, fast, feature-rich | Requires infrastructure | Full control, privacy |
| **Pinecone** | Managed, scalable, easy | Costly, vendor lock-in | Quick setup, scale |
| **Weaviate** | GraphQL API, hybrid search | Complex setup | Knowledge graphs |
| **Chroma** | Lightweight, embedded | Limited scale | Local dev, prototyping |
| **Supabase Vector** | PostgreSQL-based, free tier | Performance limits | Existing Supabase users |

---

### Complete n8n RAG Stack

**Production-Ready Setup:**

```
Infrastructure:
├── n8n (Orchestration)
│   └── Docker: n8nio/n8n
├── Ollama (LLM + Embeddings)
│   ├── llama3.1:8b (Generation)
│   └── nomic-embed-text (Embeddings)
├── Qdrant (Vector Store)
│   └── Docker: qdrant/qdrant
└── Monitoring
    ├── n8n execution logs
    └── Qdrant metrics dashboard
```

**Total Cost:** $0 (fully self-hosted)

**Monthly Savings vs Cloud:**
- OpenAI Embeddings: $200/month → $0
- Pinecone: $70/month → $0
- OpenAI GPT-4: $900/month → $0

**Total Savings:** ~$1,170/month

---

### Learning Resources

- **Qdrant Docs**: https://qdrant.tech/documentation/
- **Ollama Embeddings**: https://ollama.com/blog/embedding-models
- **n8n Vector Store Nodes**: https://docs.n8n.io/integrations/builtin/cluster-nodes/sub-nodes/n8n-nodes-langchain.vectorstoreqdrant/
- **RAG Tutorial**: https://www.pinecone.io/learn/retrieval-augmented-generation/
- **LangChain RAG**: https://python.langchain.com/docs/use_cases/question_answering/

---

### Next Steps

1. **Install Qdrant**: `docker run -d -p 6333:6333 qdrant/qdrant`
2. **Pull Embedding Model**: `ollama pull nomic-embed-text`
3. **Create n8n Indexing Workflow**: Load docs → Split → Embed → Store
4. **Create n8n Query Workflow**: Query → Embed → Retrieve → Generate
5. **Test with Sample Documents**: Start with 10-50 docs
6. **Evaluate Quality**: Track retrieval accuracy and answer relevance
7. **Optimize**: Tune chunk size, top-k, and prompts based on results