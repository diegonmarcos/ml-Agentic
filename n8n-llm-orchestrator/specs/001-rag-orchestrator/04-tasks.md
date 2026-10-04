# Tasks: Multi-Agent RAG Workflow Orchestrator

**Feature**: 001-rag-orchestrator
**Branch**: `001-rag-orchestrator`
**Created**: 2025-10-30
**Status**: Ready for Implementation

## Overview

This tasks file breaks down the RAG orchestrator implementation into actionable, independently testable phases organized by user story priority. Each phase delivers a working increment that can be tested and demonstrated independently.

**Total Tasks**: 58
**MVP Scope**: Phase 1-4 (Setup + Foundational + US2 + US1) = 32 tasks

---

## Phase 1: Setup & Infrastructure (8 tasks)

**Goal**: Establish development environment with all required services running

**Independent Test**: All services accessible - n8n GUI loads, Ollama responds to API, Qdrant dashboard shows empty collection

### Tasks

- [ ] T001 Create project directory structure per plan (workflows/, configs/, scripts/, test-data/)
- [ ] T002 [P] Create docker-compose.yml with n8n, Ollama, Qdrant, and Redis services
- [ ] T003 [P] Create .env.example with required environment variables (OLLAMA_URL, QDRANT_URL, API keys)
- [ ] T004 [P] Create .gitignore to exclude .env, node_modules, n8n data volumes
- [ ] T005 Start Docker Compose stack and verify all services running
- [ ] T006 Pull Ollama models (llama3.1:8b, nomic-embed-text) via `ollama pull` commands
- [ ] T007 Create Qdrant collection 'knowledge_base' with 768-dimensional vectors, Cosine distance
- [ ] T008 [P] Create README.md with project overview, setup instructions, and architecture diagram

**Acceptance Criteria**:
- ✅ n8n accessible at http://localhost:5678
- ✅ Ollama API responds to http://localhost:11434/api/tags
- ✅ Qdrant dashboard accessible at http://localhost:6333/dashboard
- ✅ Collection 'knowledge_base' visible in Qdrant with correct configuration

---

## Phase 2: Foundational Components (6 tasks)

**Goal**: Create reusable configuration files and helper scripts needed by all workflows

**Independent Test**: Configurations load without errors, scripts execute successfully

### Tasks

- [ ] T009 [P] Create configs/qdrant-collection-config.json with collection schema and index settings
- [ ] T010 [P] Create configs/embedding-models.json with model configurations (nomic-embed-text settings)
- [ ] T011 [P] Create configs/llm-providers.json with provider endpoints (Ollama, Anthropic, OpenAI)
- [ ] T012 [P] Create scripts/setup-qdrant-collection.sh to initialize collection via Qdrant REST API
- [ ] T013 [P] Create scripts/import-workflows.sh to bulk import n8n workflow JSONs
- [ ] T014 [P] Create test-data/sample-documents/ folder with 10 test PDFs/Markdown files

**Acceptance Criteria**:
- ✅ All config files valid JSON, no syntax errors
- ✅ setup-qdrant-collection.sh creates collection successfully when run
- ✅ import-workflows.sh ready to import workflows (tested with empty workflow)
- ✅ test-data contains 10 diverse documents (PDFs, MD, TXT)

---

## Phase 3: User Story 2 - Document Ingestion (P1) (9 tasks)

**Story**: A system administrator uploads documents which are automatically processed, chunked, embedded, and indexed into Qdrant

**Goal**: Working document ingestion pipeline that indexes documents into vector database

**Independent Test**: Upload 20 test documents → verify all appear in Qdrant with metadata → search by filename succeeds

### Tasks

- [ ] T015 [US2] Create n8n workflow 'Document Ingestion' with Manual Trigger node
- [ ] T016 [US2] Add 'Read Binary Files' node to load documents from test-data/sample-documents/
- [ ] T017 [US2] Add 'Code' node to extract text from PDFs using pdf-parse library
- [ ] T018 [US2] Add 'Code' node to chunk text into 800-char segments with 200-char overlap
- [ ] T019 [US2] Add 'Loop' node to process each chunk individually
- [ ] T020 [US2] Add 'HTTP Request' node to call Ollama embeddings API (POST /api/embeddings)
- [ ] T021 [US2] Add 'Code' node to format payload for Qdrant (point ID, vector, metadata)
- [ ] T022 [US2] Add 'HTTP Request' node to insert points into Qdrant (PUT /collections/knowledge_base/points)
- [ ] T023 [US2] Export workflow to workflows/001-document-ingestion.json

**Acceptance Criteria**:
- ✅ Workflow successfully processes 50 PDF files in under 5 minutes
- ✅ Each document chunked into 800±200 character segments
- ✅ All chunks have embeddings (768-dimensional vectors)
- ✅ Metadata includes: source filename, chunk_id, timestamp, page_number
- ✅ Re-running with same documents replaces old versions (upsert)
- ✅ Qdrant collection contains expected number of points

---

## Phase 4: User Story 1 - Query Processing (P1) (9 tasks)

**Story**: A user submits a natural language question via webhook and receives an accurate answer with source citations

**Goal**: Working RAG query workflow that retrieves relevant chunks and generates answers

**Independent Test**: POST question to webhook → receive answer in < 5 seconds with source citations

### Tasks

- [ ] T024 [US1] Create n8n workflow 'Query Processing' with Webhook Trigger (POST /query)
- [ ] T025 [US1] Add 'Code' node to validate query input (min 3 chars, max 500 chars, sanitize)
- [ ] T026 [US1] Add 'HTTP Request' node to generate query embedding via Ollama (POST /api/embeddings)
- [ ] T027 [US1] Add 'HTTP Request' node to search Qdrant for top 5 similar chunks (POST /collections/.../search)
- [ ] T028 [US1] Add 'Code' node to filter chunks by relevance score (threshold 0.6)
- [ ] T029 [US1] Add 'IF' node to check if relevant chunks found (>= 1 chunk)
- [ ] T030 [US1] Add 'Code' node to build augmented prompt with context and query
- [ ] T031 [US1] Add 'HTTP Request' node to call Ollama for answer generation (POST /api/generate)
- [ ] T032 [US1] Add 'Code' node to format response with answer + source citations, export to workflows/002-query-processing.json

**Acceptance Criteria**:
- ✅ Query "How do I install Qdrant?" returns answer with 3-5 relevant chunks
- ✅ Response time < 5 seconds for 90% of queries
- ✅ Response includes source document names and relevance scores
- ✅ Query not in docs returns "I don't have that information in the available documents"
- ✅ Citations properly formatted with [Source: filename.md | Score: 0.92]

---

## Phase 5: User Story 3 - Multi-Agent Orchestration (P2) (8 tasks)

**Story**: Users can query the system and trigger multi-step agent workflows with ReAct pattern

**Goal**: Intelligent agent that decides when to use tools and iterates until answer complete

**Independent Test**: Submit ambiguous query → agent determines tool needed → executes tool → generates final answer

### Tasks

- [ ] T033 [US3] Create n8n workflow 'Multi-Agent Orchestration' with Webhook Trigger (POST /agent-query)
- [ ] T034 [US3] Add 'Parse Agent' Code node to analyze query and determine if tool call needed (confidence check)
- [ ] T035 [US3] Add 'IF' node to route based on needs_tool flag (yes → tool call, no → generate)
- [ ] T036 [US3] Add 'HTTP Request' node for tool execution (Google Search or metadata filter)
- [ ] T037 [US3] Add 'Loop' node to enable iteration (max 5 iterations)
- [ ] T038 [US3] Add iteration counter in workflow variables, increment on each loop
- [ ] T039 [US3] Add 'Generate Agent' Code node to create final answer from all retrieved context
- [ ] T040 [US3] Export workflow to workflows/003-multi-agent-orchestration.json

**Acceptance Criteria**:
- ✅ Query "latest features in version 2.0" triggers metadata filter tool
- ✅ Ambiguous query (confidence < 0.8) triggers clarification or query expansion
- ✅ Workflow terminates after 5 iterations with partial results if not complete
- ✅ Tool call failure retries 3 times, then provides fallback response
- ✅ Response includes tool_calls array showing which tools were used

---

## Phase 6: User Story 4 - Provider Fallback (P3) (7 tasks)

**Story**: System automatically falls back to cloud LLM providers when Ollama is unavailable

**Goal**: Reliable LLM access with automatic failover chain

**Independent Test**: Stop Ollama → submit query → system uses Anthropic within 2 seconds

### Tasks

- [ ] T041 [US4] Create n8n workflow 'Provider Fallback' (called by other workflows)
- [ ] T042 [US4] Add input parameters: prompt, provider_priority array (e.g., ['ollama', 'anthropic', 'openai'])
- [ ] T043 [US4] Add 'HTTP Request' node to try Ollama (with Continue on Fail: true, timeout: 30s)
- [ ] T044 [US4] Add 'IF' node to check Ollama error, if true → error branch
- [ ] T045 [US4] Add error branch 'HTTP Request' node for Anthropic API (with API key from credentials)
- [ ] T046 [US4] Add secondary error branch 'HTTP Request' node for OpenAI API
- [ ] T047 [US4] Add final error node to return "All providers failed" message, export to workflows/004-provider-fallback.json

**Acceptance Criteria**:
- ✅ Ollama offline → Anthropic used automatically within 2 seconds
- ✅ Ollama timeout (> 30s) → fallback triggered
- ✅ Response metadata indicates which provider was used
- ✅ All providers fail → user receives clear error message with retry suggestion
- ✅ Fallback count tracked and logged

---

## Phase 7: User Story 5 - Observability (P3) (8 tasks)

**Story**: Administrators can view detailed logs and metrics for all workflow executions

**Goal**: Comprehensive logging and metrics aggregation for debugging and monitoring

**Independent Test**: Execute 10 queries → view aggregated metrics showing total queries, avg latency, token usage

### Tasks

- [ ] T048 [US5] Create n8n workflow 'Metrics Aggregation' with Schedule Trigger (daily at 2 AM)
- [ ] T049 [US5] Add 'HTTP Request' node to fetch n8n execution logs via n8n API (GET /executions)
- [ ] T050 [US5] Add 'Code' node to parse execution data and extract metrics (latency, token usage, status)
- [ ] T051 [US5] Add 'Code' node to aggregate by workflow, date, provider (sum tokens, avg latency, count errors)
- [ ] T052 [US5] Add 'Code' node to format as CSV or JSON
- [ ] T053 [US5] Add 'Write File' node to export metrics to logs/metrics-{date}.csv
- [ ] T054 [US5] Configure n8n execution log retention to 30 days in environment variables
- [ ] T055 [US5] Export workflow to workflows/005-metrics-aggregation.json

**Acceptance Criteria**:
- ✅ n8n execution logs show all node inputs/outputs including LLM prompts
- ✅ RAG retrieval logs include relevance scores, source documents, chunk count
- ✅ Metrics dashboard shows: total queries, average latency, token usage, error rate
- ✅ Error logs capture full stack trace and context (query + retrieved chunks)
- ✅ Daily CSV export contains all metrics for previous 24 hours

---

## Phase 8: Polish & Cross-Cutting Concerns (11 tasks)

**Goal**: Production readiness - error handling, caching, testing, documentation

**Independent Test**: System handles errors gracefully, caching reduces costs, all workflows documented

### Tasks

#### Error Handling & Resilience

- [ ] T056 [P] Add retry logic (3 attempts, exponential backoff) to all HTTP Request nodes across workflows
- [ ] T057 [P] Add timeout configuration (30s) to all LLM API calls
- [ ] T058 [P] Add error branches to all workflows with user-friendly error messages

#### Query Caching

- [ ] T059 [P] Add cache check Code node at start of Query Processing workflow (check workflow static data)
- [ ] T060 [P] Add cache write Code node after LLM response (store with 1-hour TTL)

#### Testing & Validation

- [ ] T061 [P] Create test-data/evaluation-set.json with 50 question-answer pairs
- [ ] T062 Create manual testing protocol document: docs/testing-protocol.md
- [ ] T063 Execute end-to-end test: ingest 20 docs → run 50 evaluation queries → measure accuracy

#### Documentation

- [ ] T064 [P] Update README.md with architecture diagram, workflow descriptions, API endpoints
- [ ] T065 [P] Create docs/quickstart.md with step-by-step setup and first query guide
- [ ] T066 [P] Create docs/troubleshooting.md with common issues and solutions

**Acceptance Criteria**:
- ✅ All workflows have retry + timeout + error handling configured
- ✅ Duplicate queries within 1 hour served from cache (< 100ms response time)
- ✅ Evaluation dataset shows 85%+ answer accuracy
- ✅ All documentation complete and tested by fresh user

---

## Dependencies & Execution Order

### Critical Path (Must Complete in Order)

```
Phase 1 (Setup)
  ↓
Phase 2 (Foundational)
  ↓
Phase 3 (US2: Ingestion) ← MUST complete before Phase 4
  ↓
Phase 4 (US1: Query) ← Needs indexed documents from US2
  ↓
Phase 5, 6, 7 (US3, US4, US5) ← Can be done in parallel after Phase 4
  ↓
Phase 8 (Polish) ← Applies to all workflows
```

### User Story Dependencies

- **US1 (Query)** depends on **US2 (Ingestion)** - cannot query without indexed documents
- **US3 (Multi-Agent)** extends **US1** - uses query workflow as foundation
- **US4 (Fallback)** is independent - can be integrated into any workflow
- **US5 (Observability)** is independent - observes all workflows

### Parallel Execution Opportunities

**Phase 1-2**: Tasks T002, T003, T004, T008, T009-T014 can run in parallel (different files, no dependencies)

**Phase 3 (US2)**: Tasks T015-T023 must run sequentially (building single workflow)

**Phase 4 (US1)**: Tasks T024-T032 must run sequentially (building single workflow)

**Phase 5-7**: Entire phases can run in parallel after Phase 4 completes

**Phase 8**: Tasks T056-T066 can run in parallel (marked with [P])

---

## Implementation Strategy

### MVP Scope (Phases 1-4)

**Recommended first implementation**: Complete Phases 1-4 only
- **Delivers**: Working document ingestion + query system (core RAG functionality)
- **Tasks**: 32 out of 58 total
- **Timeline**: ~2-3 weeks for solo developer
- **Value**: Fully functional Q&A system over documents

**After MVP Demo**: Add Phases 5-7 incrementally based on priority

### Incremental Delivery Plan

1. **Week 1**: Phases 1-2 (Setup + Foundational)
   - Deliverable: Running stack with empty workflows

2. **Week 2**: Phase 3 (US2: Ingestion)
   - Deliverable: Can index documents, verify in Qdrant

3. **Week 3**: Phase 4 (US1: Query)
   - Deliverable: MVP - Working RAG Q&A system

4. **Week 4**: Phase 5 (US3: Multi-Agent)
   - Deliverable: Enhanced with intelligent agent behavior

5. **Week 5**: Phases 6-7 (US4-US5: Fallback + Observability)
   - Deliverable: Production-ready with monitoring

6. **Week 6**: Phase 8 (Polish)
   - Deliverable: Hardened for production deployment

---

## Task Summary

| Phase | User Story | Tasks | Priority | Can Parallelize? |
| :--- | :--- | :--- | :--- | :--- |
| Phase 1 | Setup | 8 | Critical | Partially (5/8) |
| Phase 2 | Foundational | 6 | Critical | Yes (all) |
| Phase 3 | US2 (P1) | 9 | Critical | No (sequential workflow) |
| Phase 4 | US1 (P1) | 9 | Critical | No (sequential workflow) |
| Phase 5 | US3 (P2) | 8 | High | No (sequential workflow) |
| Phase 6 | US4 (P3) | 7 | Medium | No (sequential workflow) |
| Phase 7 | US5 (P3) | 8 | Medium | No (sequential workflow) |
| Phase 8 | Polish | 11 | High | Yes (all) |
| **Total** | **5 Stories** | **58** | | **28 parallelizable** |

**MVP (Phases 1-4)**: 32 tasks
**Post-MVP (Phases 5-8)**: 26 tasks

---

## File Paths Reference

### Workflows
- `workflows/001-document-ingestion.json` (Phase 3, Task T023)
- `workflows/002-query-processing.json` (Phase 4, Task T032)
- `workflows/003-multi-agent-orchestration.json` (Phase 5, Task T040)
- `workflows/004-provider-fallback.json` (Phase 6, Task T047)
- `workflows/005-metrics-aggregation.json` (Phase 7, Task T055)

### Configuration
- `configs/qdrant-collection-config.json` (Phase 2, Task T009)
- `configs/embedding-models.json` (Phase 2, Task T010)
- `configs/llm-providers.json` (Phase 2, Task T011)

### Scripts
- `scripts/setup-qdrant-collection.sh` (Phase 2, Task T012)
- `scripts/import-workflows.sh` (Phase 2, Task T013)

### Test Data
- `test-data/sample-documents/` (Phase 2, Task T014)
- `test-data/evaluation-set.json` (Phase 8, Task T061)

### Documentation
- `README.md` (Phase 1, Task T008; Phase 8, Task T064)
- `docs/testing-protocol.md` (Phase 8, Task T062)
- `docs/quickstart.md` (Phase 8, Task T065)
- `docs/troubleshooting.md` (Phase 8, Task T066)

### Infrastructure
- `docker-compose.yml` (Phase 1, Task T002)
- `.env.example` (Phase 1, Task T003)
- `.gitignore` (Phase 1, Task T004)

---

**Tasks Status**: ✅ Ready for `/speckit.implement` or manual execution

**Next Command**: `/speckit.implement` to begin task execution with guidance
