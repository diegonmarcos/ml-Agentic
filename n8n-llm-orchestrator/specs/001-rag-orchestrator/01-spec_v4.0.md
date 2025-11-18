# Feature Specification: Multi-Agent Orchestrator

**Feature Branch**: `001-rag-orchestrator`
**Version**: 4.0.0
**Created**: 2025-10-30
**Last Updated**: 2025-11-18
**Status**: Active Development - Multi-Agent System
**Input**: "Multi-agent orchestrator with coder agent and web agent, cost-optimized with 5-tier routing"

---

## Version History

- **v4.0.0** (2025-11-18): Multi-agent pivot - Coder + Web agents, git automation, browser automation, CLI + web chat interfaces
- **v3.0.0** (2025-11-18): LiteLLM integration, 5-tier routing, pre-budget checks, architect/executor pattern
- **v2.1.0** (2025-11-17): Web agent capabilities, multi-tier cost orchestration
- **v2.0.0** (2025-11-15): aisuite integration, RouteLLM, observability stack
- **v1.0.0** (2025-10-30): Initial RAG specification

---

## Executive Summary

**v4.0 represents a fundamental pivot** from document Q&A RAG to a **multi-agent orchestrator** system. The system enables intelligent automation of two distinct domains:

1. **Coder Agent**: Operates on codebases - reads, modifies, and commits code automatically
2. **Web Agent**: Operates on websites - scrapes, automates, and analyzes web content

Both agents share the same cost-optimization framework (5-tier routing, pre-budget checks, architect/executor pattern) achieving **84-88% cost savings** vs naive all-Tier-3 routing.

**Key Innovation**: Separate planning (Tier 3) from execution (Tier 0/1) for massive cost reduction while maintaining quality.

---

## User Scenarios & Testing *(mandatory)*

### CODER AGENT SCENARIOS

### User Story 1 - Code Refactoring Task (Priority: P1)

A developer submits a refactoring request via web chat or CLI. The Coder Agent analyzes the codebase, creates a detailed plan, modifies the code, and automatically commits changes to a git branch.

**Why this priority**: Core value proposition for Coder Agent - enabling AI-assisted code modifications with full git integration and cost optimization.

**Independent Test**: Select test codebase (10+ files), request "Refactor auth to use JWT tokens", verify modified files committed to git branch, validate cost breakdown shows architect/executor pattern used.

**Acceptance Scenarios**:

1. **Given** codebase at `/home/user/test-app` with 50 files, **When** user requests "Refactor authentication to use JWT tokens", **Then** system:
   - Creates git branch `ai-agent/{task-id}`
   - Modifies 3-5 auth-related files
   - Commits changes with detailed message
   - Returns cost breakdown (Architect $0.15, Executor $0.35, Reviewer $0.15 = $0.65 total)
   - Total time <30 seconds

2. **Given** user provides invalid codebase path, **When** task submitted, **Then** system returns error "Codebase not found: {path}" without charging any cost

3. **Given** coder agent modifies files, **When** error occurs mid-execution, **Then** system runs `git reset --hard HEAD` to revert all changes and returns detailed error message

4. **Given** multi-step refactoring task with 10 subtasks, **When** architect/executor pattern used, **Then** system achieves 50%+ cost savings vs all-Tier-3 baseline (logged in execution metadata)

---

### User Story 2 - Code Search and Analysis (Priority: P1)

A developer asks questions about a codebase. The Coder Agent uses RAG to search relevant code, analyzes with appropriate tier, and returns answer with file/line references.

**Why this priority**: Essential for code understanding - developers need fast answers about unfamiliar codebases without manually searching.

**Independent Test**: Index test codebase, ask "Where is authentication handled?", verify response includes file paths and line numbers, confirm Tier 0/1 used for simple query.

**Acceptance Scenarios**:

1. **Given** codebase indexed in Qdrant, **When** user asks "Find all API endpoints", **Then** system:
   - Uses Tier 0 (Ollama 3B) for classification ($0 cost)
   - Performs RAG vector search in codebase collection
   - Returns list of endpoints with file:line references
   - Response time <5 seconds
   - Cost: $0

2. **Given** complex architectural question "Explain the dependency injection pattern used", **When** query submitted, **Then** system:
   - Routes to Tier 3 (Claude) for complex reasoning
   - Retrieves 5-10 relevant code chunks via RAG
   - Generates detailed explanation with code examples
   - Cost: ~$0.15

3. **Given** codebase has 1000+ files, **When** first query submitted, **Then** system indexes codebase using batch routing (Tier 4 if >50 files) and caches index for future queries

---

### User Story 3 - Test Generation (Priority: P2)

A developer requests tests for specific modules. The Coder Agent generates test files, writes them to the codebase, and commits automatically.

**Why this priority**: High-value automation - test generation is time-consuming but follows patterns suitable for AI execution.

**Independent Test**: Request "Write unit tests for user service", verify test files created with proper assertions, validate git commit includes tests.

**Acceptance Scenarios**:

1. **Given** module file `src/services/user.js`, **When** user requests "Write unit tests for user service", **Then** system:
   - Architect (Tier 3) analyzes module and creates test plan
   - Executor (Tier 1) generates test cases using module structure
   - Creates file `tests/services/user.test.js`
   - Commits with message "test: Add unit tests for user service"
   - Cost: ~$0.40 (vs $1.20 all-Tier-3)

2. **Given** existing test file `tests/auth.test.js`, **When** user requests "Add edge case tests for login", **Then** system appends new test cases to existing file without overwriting

---

### User Story 4 - Code Documentation Generation (Priority: P3)

A developer requests documentation for code modules. The Coder Agent generates JSDoc/docstrings and updates README files.

**Why this priority**: Nice-to-have automation - improves code quality but not blocking for functionality.

**Independent Test**: Request "Add JSDoc comments to all exported functions in utils/", verify comments added inline, check git commit.

**Acceptance Scenarios**:

1. **Given** file `utils/helpers.js` with 10 exported functions, **When** user requests "Add JSDoc comments to all exports", **Then** system:
   - Tier 1 (Fireworks) generates JSDoc for each function
   - Inserts comments inline above function declarations
   - Preserves exact formatting and indentation
   - Commits with message "docs: Add JSDoc comments to utils/helpers.js"

2. **Given** outdated README.md, **When** user requests "Update README with current API documentation", **Then** system analyzes codebase, generates updated sections, commits changes

---

### User Story 5 - Codebase Indexing and Batch Processing (Priority: P2)

When user provides large codebase (>50 files), system automatically detects batch size and routes to Tier 4 GPU rental for cost-efficient indexing.

**Why this priority**: Essential for cost optimization on large codebases - batch routing saves 30-50% vs per-file processing.

**Independent Test**: Provide codebase with 100 files, trigger indexing, verify Tier 4 used, compare cost vs Tier 1 baseline.

**Acceptance Scenarios**:

1. **Given** codebase with 100 JavaScript files, **When** indexing triggered, **Then** system:
   - Detects batch size ≥50
   - Calculates cost: Tier 1 ($0.03) vs Tier 4 ($0.69/hr for ~5 min = $0.058)
   - Tier 4 not cheaper, uses Tier 1
   - Logs decision rationale

2. **Given** codebase with 500 files, **When** indexing triggered, **Then** system:
   - Detects batch size ≥50
   - Calculates cost: Tier 1 ($0.15) vs Tier 4 ($0.69/hr for ~15 min = $0.17)
   - Tier 4 IS cheaper (with GPU parallelization), uses Tier 4
   - Spins up RunPod instance, processes in parallel
   - Auto-shutdown after completion

---

### WEB AGENT SCENARIOS

### User Story 6 - Competitor Research Automation (Priority: P1)

A user requests web research on competitor pricing. The Web Agent navigates to websites, extracts pricing data, analyzes with vision if needed, and generates a markdown report.

**Why this priority**: Core value proposition for Web Agent - automating manual research with browser automation and intelligent extraction.

**Independent Test**: Request "Research pricing from competitor.com/pricing", verify browser navigation, content extraction, report generation, git commit of report.

**Acceptance Scenarios**:

1. **Given** target URL `https://competitor.com/pricing`, **When** user requests "Research competitor pricing", **Then** system:
   - Architect (Tier 3) creates research plan
   - Playwright navigates to URL (headless browser)
   - Firecrawl extracts structured content (pricing table as markdown)
   - Tier 1 (Fireworks) generates analysis report
   - Saves to `research/competitor-pricing-YYYY-MM-DD.md`
   - Commits to git with message "research: Competitor pricing analysis"
   - Closes browser session
   - Total cost: ~$0.25

2. **Given** pricing page with complex JavaScript rendering, **When** Firecrawl fails to extract, **Then** system:
   - Takes screenshot of page
   - Routes to Tier 2 (Ollama Vision) for visual analysis
   - Extracts pricing from screenshot
   - Cost: $0 (local vision model)

3. **Given** website blocks bot traffic (403/captcha), **When** navigation fails, **Then** system saves screenshot, logs error, closes browser, returns user-friendly error

---

### User Story 7 - Multi-Page Web Scraping (Priority: P2)

A user requests data extraction from multiple pages (product listings, documentation sites). The Web Agent uses batch routing for cost efficiency.

**Why this priority**: High-value automation with cost optimization - multi-page scraping benefits significantly from batch routing.

**Independent Test**: Request "Extract all product prices from catalog (50 pages)", verify batch routing to Tier 4, compare cost vs per-page Tier 1.

**Acceptance Scenarios**:

1. **Given** product catalog with 50 pages, **When** user requests "Extract all product data", **Then** system:
   - Detects batch size ≥50 pages
   - Calculates Tier 1 cost (50 × $0.05 = $2.50) vs Tier 4 cost ($0.69/hr for 10 min = $0.12)
   - Routes to Tier 4 (if available)
   - Processes pages in parallel
   - Generates structured JSON output
   - Cost savings: 95%

2. **Given** documentation site with 100 pages, **When** user requests "Index entire docs site for RAG", **Then** system:
   - Uses batch routing
   - Extracts content via Firecrawl
   - Generates embeddings
   - Stores in Qdrant `web_content` collection
   - Future queries can use RAG instead of re-scraping

---

### User Story 8 - Form Automation (Priority: P3)

A user requests automated form submission (contact forms, account creation). The Web Agent uses Playwright to fill fields and submit.

**Why this priority**: Nice-to-have automation - useful for testing but requires careful validation to avoid spam.

**Independent Test**: Request "Fill test contact form at test-site.com/contact", verify form submission, screenshot confirmation.

**Acceptance Scenarios**:

1. **Given** contact form URL and form data, **When** user requests "Fill and submit contact form", **Then** system:
   - Playwright navigates to form
   - Fills fields (name, email, message)
   - Clicks submit button
   - Takes screenshot of confirmation page
   - Returns success with screenshot path
   - Cost: ~$0.10

2. **Given** form with CAPTCHA, **When** automation attempted, **Then** system detects CAPTCHA, returns error "Form requires manual CAPTCHA completion"

---

### User Story 9 - Web Page Monitoring (Priority: P3)

A user requests periodic monitoring of web pages for changes (price tracking, availability tracking). System schedules recurring scraping and alerts on changes.

**Why this priority**: Useful automation but requires scheduling infrastructure (n8n cron triggers).

**Independent Test**: Request "Monitor this page daily for price changes", verify n8n scheduled workflow created, test alert on content change.

**Acceptance Scenarios**:

1. **Given** product page URL, **When** user requests "Monitor for price changes daily", **Then** system:
   - Creates n8n scheduled workflow (cron: daily at 9am)
   - Stores baseline price in database
   - Each run: Scrapes current price, compares to baseline
   - If changed: Sends alert (email/webhook), updates baseline
   - Cost per check: ~$0.05

---

### User Story 10 - Screenshot Analysis (Priority: P2)

A user provides screenshot or requests screenshot of page for visual analysis. Web Agent uses Tier 2 vision model.

**Why this priority**: Essential for handling visual-heavy websites where text extraction fails.

**Independent Test**: Request "What are the pricing tiers shown in this screenshot?", verify Tier 2 vision model used, cost $0.

**Acceptance Scenarios**:

1. **Given** screenshot of pricing page, **When** user requests "Extract pricing from screenshot", **Then** system:
   - Routes to Tier 2 (Ollama Vision 70B)
   - Analyzes screenshot
   - Extracts: "3 tiers: Basic $10/mo, Pro $50/mo, Enterprise $200/mo"
   - Cost: $0 (local vision model)

2. **Given** complex dashboard screenshot, **When** user requests "Summarize this dashboard", **Then** system:
   - Tier 2 vision identifies components
   - Tier 1 generates summary report
   - Total cost: ~$0.05

---

### Edge Cases (v4.0 Multi-Agent)

**Coder Agent**:
- What if codebase path contains spaces? (Properly quote paths in git commands)
- What if file is modified by another process during execution? (Git diff detects changes, fail with conflict error)
- What if requested refactoring would break syntax? (Reviewer agent catches errors, suggests fixes)
- What if codebase is 10,000+ files? (Batch indexing with Tier 4, incremental processing)
- What if git repo is dirty (uncommitted changes)? (Fail with error "Uncommitted changes detected, commit or stash first")

**Web Agent**:
- What if website is behind authentication? (Support cookie/session passing, environment variables for credentials)
- What if website has rate limiting? (Respect robots.txt, add configurable delays between requests)
- What if page takes >30s to load? (Timeout, save partial content, return error with screenshot)
- What if browser crashes mid-session? (Try/finally ensures cleanup, restart browser on next request)
- What if extracting 1000+ pages? (Batch routing, parallel processing with multiple browser instances)

**Cost Management**:
- What if budget exhausted mid-task? (Pre-budget check blocks next LLM call, graceful degradation to lower tier if possible)
- What if Tier 4 instance fails to start? (Fallback to Tier 1 per-request, log failure, notify admin)
- What if estimated cost wildly different from actual? (Log variance >10%, improve estimation algorithm)

---

## Requirements *(mandatory)*

### Functional Requirements

#### Agent Orchestration (Core)

- **FR-001**: System MUST support two agent types: `coder` and `web`
- **FR-002**: System MUST accept agent selection via user input (explicit) or automatic detection (keywords, paths, URLs)
- **FR-003**: System MUST route tasks to appropriate agent based on selection
- **FR-004**: System MUST support two input interfaces: Web chat (Flowise) and CLI
- **FR-005**: System MUST validate inputs before agent execution (codebase path exists, URL valid)
- **FR-006**: System MUST log all agent invocations with: agent type, task, timestamp, user
- **FR-007**: System MUST run pre-budget check before ANY agent operation (MANDATORY)
- **FR-008**: System MUST return structured response with: status, result, cost breakdown, execution time

#### Coder Agent Requirements

##### Codebase Management

- **FR-009**: Coder Agent MUST accept codebase path (absolute local path)
- **FR-010**: Coder Agent MUST validate codebase is git repository before modifications
- **FR-011**: Coder Agent MUST create git branch `ai-agent/{task-id}` before any file modifications
- **FR-012**: Coder Agent MUST index codebase on first query (if not already indexed)
- **FR-013**: Codebase indexing MUST use batch routing (Tier 4) if file count ≥50
- **FR-014**: Codebase index MUST be stored in Qdrant collection `codebase_{name}`
- **FR-015**: Codebase index MUST include metadata: file_path, function_name, class_name, line_start, line_end

##### Code Operations

- **FR-016**: Coder Agent MUST support read operations: read file, list files, search code
- **FR-017**: Coder Agent MUST support write operations: create file, modify file, delete file (with confirmation)
- **FR-018**: Coder Agent MUST preserve file formatting (indentation, line endings) when modifying
- **FR-019**: Coder Agent MUST validate file paths prevent directory traversal (no `../` outside codebase)
- **FR-020**: Coder Agent MUST use RAG vector search to find relevant code before operations
- **FR-021**: Coder Agent MUST support AST parsing for structural code analysis (via tree-sitter)

##### Git Automation

- **FR-022**: Coder Agent MUST automatically commit all file modifications
- **FR-023**: Git commits MUST follow format: `<type>: <summary>\n\n<details>\n\nCo-authored-by: AI Agent <agent@n8n>`
- **FR-024**: Git commit types MUST be one of: feat, fix, refactor, test, docs, chore
- **FR-025**: Coder Agent MUST support auto-push (optional, default: false)
- **FR-026**: Coder Agent MUST revert changes (`git reset --hard HEAD`) on execution error
- **FR-027**: Coder Agent MUST never modify files outside specified codebase path

##### Code Analysis

- **FR-028**: Coder Agent MUST support code search queries using Tier 0 (if simple) or Tier 1
- **FR-029**: Coder Agent MUST return file:line references for all code search results
- **FR-030**: Coder Agent MUST use architect/executor pattern for multi-step coding tasks
- **FR-031**: Coder Agent MUST track cost per task phase (planning, execution, review)

#### Web Agent Requirements

##### Browser Automation

- **FR-032**: Web Agent MUST use Playwright for browser automation
- **FR-033**: Web Agent MUST run browsers in headless mode (default)
- **FR-034**: Web Agent MUST set timeout for all browser actions (30s default)
- **FR-035**: Web Agent MUST take screenshot on every page navigation
- **FR-036**: Web Agent MUST save screenshots to `screenshots/` directory with timestamp
- **FR-037**: Web Agent MUST close browser sessions on task completion or error (MANDATORY cleanup)
- **FR-038**: Web Agent MUST support browser actions: navigate, click, fill form, extract content, scroll, wait

##### Web Scraping

- **FR-039**: Web Agent MUST use Firecrawl for structured content extraction (primary method)
- **FR-040**: Web Agent MUST fall back to Playwright HTML extraction if Firecrawl fails
- **FR-041**: Web Agent MUST extract content as structured markdown or JSON
- **FR-042**: Web Agent MUST handle JavaScript-rendered content (Playwright waits for `networkidle`)
- **FR-043**: Web Agent MUST respect robots.txt (check before scraping)
- **FR-044**: Web Agent MUST add delays between requests (configurable, default: 2s)
- **FR-045**: Web Agent MUST support authentication via cookies/session (environment variables)

##### Vision Analysis

- **FR-046**: Web Agent MUST use Tier 2 (Ollama Vision) for screenshot analysis when text extraction fails
- **FR-047**: Web Agent MUST automatically route visual tasks (screenshots, images) to vision model
- **FR-048**: Web Agent MUST support vision queries: "What's in this screenshot?", "Extract text from image"
- **FR-049**: Vision analysis MUST cost $0 (local Tier 2 model)

##### Batch Web Operations

- **FR-050**: Web Agent MUST detect batch operations (≥50 pages)
- **FR-051**: Web Agent MUST use batch routing (Tier 4) when cost-effective for bulk scraping
- **FR-052**: Web Agent MUST support parallel page processing (multiple browser instances)
- **FR-053**: Web Agent MUST aggregate results from batch operations into structured output

##### Web Content Storage

- **FR-054**: Web Agent MUST save extracted content to local files (markdown reports)
- **FR-055**: Web Agent MUST commit research reports to git with message "research: <summary>"
- **FR-056**: Web Agent MUST optionally index web content in Qdrant `web_content` collection for future RAG
- **FR-057**: Web content index MUST include metadata: url, page_title, extraction_date, content_type

#### Cost Optimization (Both Agents)

##### Pre-Budget Checks

- **FR-058**: System MUST perform pre-budget check BEFORE every LLM API call (MANDATORY)
- **FR-059**: Pre-budget check MUST validate sufficient balance in appropriate budget pool
- **FR-060**: Pre-budget check MUST BLOCK call if balance < estimated cost
- **FR-061**: Pre-budget check MUST return error "Budget exhausted in pool {name}" if insufficient
- **FR-062**: System MUST update budget pool balance in real-time after each LLM call

##### Budget Pools (v4.0 Adjusted)

- **FR-063**: System MUST maintain 4 separate budget pools:
  - `hourly_vram`: $100/month (Tier 4 GPU rental)
  - `per_token`: $50/month (Tier 1 providers)
  - `premium`: $50/month (Tier 3 - INCREASED from v3.0 $30 due to more planning)
  - `local_vps`: $75/month (Tier 0/2 infrastructure)
- **FR-064**: Budget pools MUST reset monthly (1st of month)
- **FR-065**: System MUST send alert when any pool reaches 90% capacity
- **FR-066**: System MUST log all budget pool updates (timestamp, pool, amount, balance_after)

##### 5-Tier Routing

- **FR-067**: System MUST implement 5-tier routing:
  - **Tier 0**: Ollama 3B-13B (classification, simple queries) - $0, <500ms
  - **Tier 1**: Fireworks/Together (standard execution) - $0.20-0.80/M tokens
  - **Tier 2**: Ollama 70B+Vision (multimodal) - $0 (VPS fixed cost)
  - **Tier 3**: Claude/Gemini (planning, review) - $3-15/M tokens
  - **Tier 4**: RunPod/Salad GPU (batch processing) - $0.69-2/hour

- **FR-068**: Tier selection MUST be based on task complexity (RouteLLM analysis)
- **FR-069**: Simple queries (<500 chars, factual) MUST route to Tier 0
- **FR-070**: Planning phase MUST route to Tier 3 (architect role)
- **FR-071**: Execution phase MUST route to Tier 0/1 (executor role)
- **FR-072**: Review phase MUST route to Tier 3 (reviewer role)
- **FR-073**: Vision tasks (screenshots, images) MUST route to Tier 2
- **FR-074**: Batch operations (≥50 items) MUST route to Tier 4 if cost-effective

##### Architect/Executor Pattern

- **FR-075**: Multi-step tasks (>3 subtasks) MUST use architect/executor pattern
- **FR-076**: Architect agent MUST use Tier 3 to create detailed plan with 5-15 subtasks
- **FR-077**: Executor agents MUST use Tier 0/1 to execute individual subtasks
- **FR-078**: Reviewer agent MUST use Tier 3 to validate results
- **FR-079**: System MUST track cost per agent role (architect, executor, reviewer)
- **FR-080**: System MUST log cost savings vs all-Tier-3 baseline

##### Prompt Compression

- **FR-081**: System MUST detect long prompts (>10k tokens)
- **FR-082**: Long prompts MUST be compressed via Tier 0 before sending to Tier 3
- **FR-083**: Compression MUST achieve 40-60% token reduction
- **FR-084**: Compression MUST preserve critical context (user query, top 3 chunks, source citations)

##### Batch Routing

- **FR-085**: System MUST detect batch size for all operations (file processing, page scraping)
- **FR-086**: Batch operations MUST calculate cost comparison: Tier 1 per-item vs Tier 4 hourly
- **FR-087**: Tier 4 MUST be used if savings ≥30%
- **FR-088**: Tier 4 instances MUST auto-shutdown after 30 minutes idle

#### Observability (Both Agents)

##### Logging

- **FR-089**: System MUST log all workflow executions with: agent, task, codebase/url, execution_id, trace_id
- **FR-090**: System MUST log all LLM calls with: tier, model, prompt, response, tokens, cost
- **FR-091**: Coder Agent MUST log file operations: file_path, operation (read/write/delete), lines_changed
- **FR-092**: Web Agent MUST log browser actions: url, action, screenshot_path, duration_ms
- **FR-093**: System MUST log all git operations: branch, commit_hash, files_modified
- **FR-094**: System MUST log all budget operations: pool, balance_before, amount, balance_after

##### Tracing

- **FR-095**: System MUST implement OpenTelemetry distributed tracing
- **FR-096**: Every agent request MUST generate trace_id and span_id
- **FR-097**: Traces MUST include spans for: agent_selection, planning, execution, review, git_commit
- **FR-098**: LLM calls MUST propagate trace context to LiteLLM and providers

##### Metrics

- **FR-099**: System MUST expose metrics dashboard with:
  - Total agent invocations (coder vs web)
  - Cost per agent type
  - Cost per tier (0-4)
  - Tier distribution (% queries per tier)
  - Budget pool balances and burn rate
  - Architect/executor cost breakdown
  - Cache hit rate (Helicone)
  - Average response time per agent

- **FR-100**: Metrics MUST be retained for 30 days minimum

#### Error Handling (Both Agents)

- **FR-101**: Coder Agent MUST revert file changes on error (`git reset --hard HEAD`)
- **FR-102**: Web Agent MUST close browser on error (try/finally cleanup)
- **FR-103**: Web Agent MUST save screenshot on error for debugging
- **FR-104**: System MUST return user-friendly error messages (not stack traces)
- **FR-105**: System MUST log full error context (task, files/urls, tier attempted, cost incurred)
- **FR-106**: System MUST retry LLM calls max 3 times with exponential backoff
- **FR-107**: System MUST timeout LLM calls after 30 seconds
- **FR-108**: System MUST gracefully degrade when budget exhausted (block new tasks, return error)

#### Interface Requirements

##### Web Chat (Flowise)

- **FR-109**: System MUST expose webhook endpoint for Flowise integration
- **FR-110**: Web chat MUST support agent selection dropdown: "Coder Agent" | "Web Agent"
- **FR-111**: Web chat MUST support codebase path input field (for Coder Agent)
- **FR-112**: Web chat MUST support URL input field (for Web Agent)
- **FR-113**: Web chat MUST display real-time status updates during execution
- **FR-114**: Web chat MUST display cost breakdown after task completion
- **FR-115**: Web chat MUST support conversation history (store in n8n database)

##### CLI Tool

- **FR-116**: System MUST provide CLI tool `n8n-agent-cli.sh`
- **FR-117**: CLI MUST accept arguments: agent_type, codebase_or_url, task_description
- **FR-118**: CLI MUST call n8n webhook via curl with JSON payload
- **FR-119**: CLI MUST display formatted response (status, result, cost)
- **FR-120**: CLI MUST support piping input from stdin for batch tasks

---

### Key Entities (v4.0 Multi-Agent)

1. **Agent** (NEW): Represents agent instance
   - agent_type: "coder" | "web"
   - task: user request text
   - codebase_path: (for coder) "/path/to/code"
   - target_url: (for web) "https://example.com"
   - execution_id: unique ID
   - trace_id: OpenTelemetry trace
   - status: "pending" | "in_progress" | "completed" | "failed"
   - created_at, completed_at, duration_ms

2. **CoderTask** (NEW): Represents coder agent task
   - agent_id: reference to Agent
   - codebase_path: validated path
   - task_type: "search" | "modify" | "test" | "document"
   - git_branch: created branch name
   - files_modified: array of file paths
   - commit_hash: git commit SHA
   - cost_breakdown: {architect, executor, reviewer}
   - lines_added, lines_deleted

3. **WebTask** (NEW): Represents web agent task
   - agent_id: reference to Agent
   - target_url: initial URL
   - task_type: "research" | "scrape" | "monitor" | "automate"
   - browser_session_id: Playwright session
   - pages_visited: array of URLs
   - screenshots: array of file paths
   - report_path: saved markdown report
   - cost_breakdown: {architect, executor, vision}

4. **GitCommit** (NEW): Represents automated git commit
   - coder_task_id: reference to CoderTask
   - branch: branch name
   - commit_hash: SHA
   - commit_message: formatted message
   - files_modified: array of paths
   - author: "AI Agent <agent@n8n>"
   - timestamp

5. **BrowserSession** (NEW): Represents Playwright session
   - web_task_id: reference to WebTask
   - session_id: Playwright session ID
   - browser_type: "chromium"
   - headless: boolean
   - start_time, end_time
   - actions: array of {action, target, duration_ms}
   - screenshots: array of paths
   - status: "active" | "closed" | "crashed"

6. **RoutingDecision**: tier_selected (0-4), complexity_score, routing_reason, agent_type
7. **BudgetCheck**: check_timestamp, tier_requested, estimated_cost, pool, balance, result (pass/fail)
8. **LLMResponse**: tier_used, model, tokens, cost, role (architect/executor/reviewer)
9. **WorkflowExecution**: agent_type, total_cost, cost_per_tier, budget_impact
10. **AgentTask**: task_id, role (architect/executor/reviewer), tier, cost, parent_task_id, savings_vs_baseline

---

## Success Criteria *(mandatory)*

### Cost Optimization (Primary Goals)

- **SC-001**: Tier 0 handles 40%+ of simple queries at $0 cost
- **SC-002**: Architect/executor pattern achieves 50%+ cost savings vs all-Tier-3 on multi-step tasks
- **SC-003**: Batch routing (Tier 4) achieves 30-50% savings on ≥50 operations
- **SC-004**: Pre-budget checks prevent 100% of budget overruns (0 unauthorized charges)
- **SC-005**: Overall cost reduction of 80%+ vs naive all-Tier-3 routing (measured over 30 days)
- **SC-006**: Monthly cost for 100 agent tasks: <$10 (vs $50 baseline)

### Coder Agent Success Criteria

- **SC-007**: Coder Agent completes code refactoring tasks with 85%+ correctness (validated by reviewer agent or user feedback)
- **SC-008**: Coder Agent response time: <30s for simple queries, <60s for multi-step tasks (P90)
- **SC-009**: Git commits follow format 100% of time with proper type and detailed description
- **SC-010**: File modifications preserve formatting (indentation, line endings) 95%+ of time
- **SC-011**: Coder Agent indexing processes 100+ files/minute
- **SC-012**: RAG code search returns relevant results (top-3 chunks relevant) 80%+ of time
- **SC-013**: Error rollback (git reset) succeeds 100% of time on execution failure
- **SC-014**: Coder Agent never modifies files outside specified codebase (0 path traversal incidents)

### Web Agent Success Criteria

- **SC-015**: Web Agent successfully navigates and extracts content from 95%+ of tested websites
- **SC-016**: Browser cleanup (close session) succeeds 100% of time (no orphaned processes)
- **SC-017**: Firecrawl extraction success rate: 90%+ for text-heavy pages
- **SC-018**: Vision fallback (Tier 2) handles 95%+ of screenshot analysis tasks correctly
- **SC-019**: Web Agent response time: <10s for single page, <60s for multi-page (P90)
- **SC-020**: Batch web scraping processes 10+ pages/minute
- **SC-021**: Web Agent respects robots.txt 100% of time (0 violations)
- **SC-022**: Screenshot capture succeeds on 100% of page navigations
- **SC-023**: Research reports saved and committed to git 100% of time

### Performance & Reliability

- **SC-024**: Pre-budget check overhead: <100ms (negligible impact on total latency)
- **SC-025**: System handles 5+ concurrent agent tasks without performance degradation
- **SC-026**: Error rate: <5% for all agent executions (excluding user errors like invalid paths)
- **SC-027**: Tier routing accuracy: 90%+ of tasks routed to appropriate tier
- **SC-028**: Cache hit rate (Helicone): 20%+ for duplicate queries

### Observability

- **SC-029**: 100% of agent tasks logged with full execution context
- **SC-030**: 100% of LLM calls traced with OpenTelemetry
- **SC-031**: Cost dashboard shows real-time budget pool status with <1 min delay
- **SC-032**: Administrators can debug failed tasks using logs within 10 minutes

### Business Outcomes

- **SC-033**: Coder Agent reduces time for code refactoring tasks by 70% vs manual coding
- **SC-034**: Web Agent reduces time for competitor research by 80% vs manual browsing
- **SC-035**: Monthly LLM costs stay under $10 for up to 100 agent tasks via intelligent routing
- **SC-036**: Zero budget overruns over 30-day period (pre-checks prevent)

---

## Assumptions (v4.0)

1. Codebases are git repositories with proper history
2. Users have basic understanding of git (branches, commits)
3. Web scraping targets are public websites (no auth required initially)
4. n8n, Ollama, LiteLLM, Qdrant running locally or accessible via network
5. Playwright browser automation works on target platform (Linux with Chrome/Chromium)
6. Budget pools reset monthly on 1st of month
7. Tier 4 GPU providers (RunPod/Salad) have <3 minute cold start
8. VPS has sufficient resources: 48GB RAM, RTX 4090 or equivalent for Tier 2
9. Flowise installed and configured to connect to n8n webhooks
10. Users provide valid codebase paths and URLs

---

## Out of Scope (v4.0)

- Real-time streaming of agent responses (batch response only)
- Multi-user authentication and authorization (single-user initially)
- Advanced code analysis (static analysis, linting) - basic generation only
- Mobile app interface (web chat + CLI only)
- Automated PR creation and merge (git commit only, user reviews and merges)
- Web automation behind paywalls or complex auth (basic cookie support only)
- Multi-language code generation (focus on JavaScript/Python initially)
- Advanced browser interactions (drag-drop, canvas manipulation)
- Custom LLM fine-tuning on user codebases
- Real-time code collaboration (no multi-agent editing same file)

---

## Dependencies (v4.0)

### Core Services
1. **n8n**: Workflow orchestration
2. **LiteLLM**: Unified LLM API (5-tier routing)
3. **Qdrant**: Vector DB (codebase + web content)
4. **Ollama**: Tier 0 + Tier 2 (local models)
5. **Redis**: Budget pool state (real-time balances)

### Observability
6. **OpenTelemetry Collector**: Distributed tracing
7. **Jaeger**: Trace backend
8. **LangSmith/Langfuse**: LLM monitoring
9. **Helicone**: Cost proxy + caching

### External Providers
10. **Fireworks.ai / Together.ai**: Tier 1 (per-token)
11. **Anthropic / Google**: Tier 3 (premium)
12. **RunPod / Salad**: Tier 4 (hourly VRAM)
13. **Firecrawl**: Web scraping API
14. **Playwright**: Browser automation (Node.js service)

### Interfaces
15. **Flowise**: Web chat UI
16. **CLI**: Bash script (curl wrapper)

### Tools (Coder Agent)
17. **tree-sitter**: AST parsing (optional HTTP service)
18. **Git**: Version control (system git)

---

## Migration Notes (v3.0 → v4.0)

### Breaking Changes

1. **System Purpose**: Document Q&A → Multi-Agent Orchestrator
2. **Input Format**: Documents → Codebases + URLs
3. **Output Format**: Text answers → Code commits + Research reports
4. **Budget Pools**: Premium pool increased to $50 (from $30) due to more planning
5. **New Entities**: Agent, CoderTask, WebTask, GitCommit, BrowserSession
6. **New Services**: Playwright browser automation, tree-sitter AST parsing

### What Stays the Same

- ✅ 5-tier routing system (Tier 0-4)
- ✅ Pre-budget checks (MANDATORY)
- ✅ Architect/executor pattern
- ✅ LiteLLM integration
- ✅ Qdrant vector DB
- ✅ Observability stack (OpenTelemetry, Helicone, LangSmith)

### Upgrade Path

1. Keep existing v3.0 RAG workflows (still useful for document Q&A)
2. Add new v4.0 agent workflows alongside v3.0
3. Deploy Playwright service for web automation
4. Deploy tree-sitter service for code parsing (optional)
5. Configure Flowise for web chat interface
6. Create CLI tool for command-line access
7. Update budget pools (increase premium to $50)
8. Test both agents with sample tasks

---

**Document Version**: 4.0.0
**Last Updated**: 2025-11-18
**Next Review**: After Phase 0 implementation (Playwright + CLI setup)
**Status**: Ready for Implementation
