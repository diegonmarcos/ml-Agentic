# Technology Research & Decisions: RAG Orchestrator

**Feature**: 001-rag-orchestrator
**Date**: 2025-10-30
**Purpose**: Document technology decisions and rationale for n8n RAG implementation

---

## 1. n8n Node Selection for RAG Pipeline

### Decision

**Selected Nodes**:
- **Document Processing**: `Read Binary Files` + `Code Node` (for PDF text extraction using pdf-parse library)
- **Text Splitting**: `Code Node` with custom chunking logic (800 chars, 200 overlap)
- **Embeddings**: `HTTP Request` node calling Ollama `/api/embeddings` endpoint
- **Vector Storage**: `HTTP Request` node for Qdrant REST API (`/collections/{name}/points`)

### Rationale

- **LangChain Nodes**: n8n has native LangChain integration but adds complexity. Direct HTTP requests provide more control and transparency.
- **Code Node for Processing**: Allows custom logic without external scripts. Can use built-in JavaScript libraries.
- **HTTP Request over Custom Nodes**: Universal approach works with any API, easier to debug, constitution-compliant (visual).

### Alternatives Considered

- **Alternative 1**: Use n8n's `Document Loader` and `Text Splitter` LangChain nodes
  - **Rejected**: Less flexible, harder to customize chunk size/overlap, adds dependency on LangChain version compatibility
- **Alternative 2**: External Python scripts for processing
  - **Rejected**: Violates "Visual-First Design" principle, adds deployment complexity

---

## 2. Ollama API Endpoints for RAG

### Decision

**Embeddings Endpoint**: `POST http://localhost:11434/api/embeddings`
```json
{
  "model": "nomic-embed-text",
  "prompt": "text to embed"
}
```

**Response**: `{"embedding": [0.123, -0.456, ...]}`

**Generation Endpoint**: `POST http://localhost:11434/api/generate`
```json
{
  "model": "llama3.1:8b",
  "prompt": "Based on context...",
  "stream": false
}
```

**Response**: `{"response": "answer text", "done": true}`

### Rationale

- Non-streaming mode (`"stream": false`) simplifies n8n integration
- Single HTTP Request node per API call
- Response parsing straightforward with n8n's built-in JSON handling

### n8n Configuration

**HTTP Request Node Settings**:
- Method: POST
- URL: `{{ $env.OLLAMA_URL }}/api/embeddings` (use environment variable)
- Headers: `Content-Type: application/json`
- Body: JSON with `model` and `prompt` fields
- Timeout: 30 seconds
- Retry: 3 attempts, exponential backoff

---

## 3. Qdrant Collection Setup

### Decision

**Collection Configuration**:
```json
{
  "vectors": {
    "size": 768,
    "distance": "Cosine"
  },
  "optimizers_config": {
    "indexing_threshold": 20000
  },
  "hnsw_config": {
    "m": 16,
    "ef_construct": 100
  }
}
```

**Distance Metric**: Cosine (standard for embeddings, normalized vectors)

**Index Type**: HNSW (Hierarchical Navigable Small World) for fast approximate search

**Metadata Schema**:
```json
{
  "source": "string",
  "chunk_id": "integer",
  "page_number": "integer | null",
  "timestamp": "string (ISO 8601)"
}
```

### Rationale

- **Cosine Distance**: Best for normalized embeddings (nomic-embed-text outputs are normalized)
- **HNSW m=16**: Balances speed vs accuracy for 100K vector scale
- **ef_construct=100**: Higher than default (improves recall at index time)
- **Indexing Threshold 20K**: Start indexing after 20K points (reduces rebuild frequency)

### Qdrant API Calls in n8n

**Create Collection**:
```bash
PUT /collections/knowledge_base
```

**Insert Points**:
```bash
PUT /collections/knowledge_base/points
```

**Search**:
```bash
POST /collections/knowledge_base/points/search
{
  "vector": [0.1, 0.2, ...],
  "limit": 5,
  "with_payload": true
}
```

### Alternatives Considered

- **Alternative 1**: Dot Product distance
  - **Rejected**: Cosine is standard for embeddings, more interpretable scores
- **Alternative 2**: Flat index (exact search)
  - **Rejected**: Too slow for 100K+ vectors, HNSW provides 99%+ recall with 10x speedup

---

## 4. n8n Workflow Export/Import

### Decision

**Development Process**:
1. Build workflows in n8n GUI
2. Export as JSON: Settings → Export Workflow → Download JSON
3. Commit JSON files to `workflows/` directory in Git
4. Import to new n8n instance: Settings → Import Workflow → Upload JSON
5. Use n8n CLI for automation: `n8n import:workflow --input=workflow.json`

**Version Control Strategy**:
- Store workflow JSONs in `workflows/` directory
- Use descriptive names: `001-document-ingestion.json`
- Include workflow version in commit message
- Tag releases: `v1.0.0-ingestion-workflow`

### Rationale

- **Manual Export/Import**: Simple, no additional tooling required
- **Git for Versioning**: Leverage existing version control, diffs visible in PRs
- **n8n CLI for CI/CD**: Enables automated deployment if needed

### Alternatives Considered

- **Alternative 1**: n8n API for programmatic management
  - **Rejected**: Adds complexity, manual export sufficient for MVP
- **Alternative 2**: Database backups instead of JSON exports
  - **Rejected**: Less portable, harder to review changes in Git

---

## 5. Query Caching Strategy

### Decision

**Caching Mechanism**: n8n `Code Node` with in-memory Map + Redis fallback (optional)

**Implementation**:
```javascript
// Code Node: Check cache
const cache = $workflow.getStaticData();
const queryHash = crypto.createHash('md5').update($json.query).digest('hex');
const now = Date.now();

if (cache[queryHash] && (now - cache[queryHash].timestamp < 3600000)) {
  return [{json: cache[queryHash].response, source: 'cache'}];
}

return [{json: {queryHash, needsFetch: true}}];
```

**Cache Invalidation**: 1-hour TTL (3,600,000 ms)

**Storage**: n8n's `getStaticData()` (persists across executions, cleared on workflow restart)

### Rationale

- **In-Memory First**: Fast, no external dependencies
- **TTL-based**: Simple expiration logic
- **MD5 Hash**: Unique key per query, handles duplicates
- **Workflow Static Data**: Built into n8n, no setup required

### Alternatives Considered

- **Alternative 1**: External Redis cache
  - **Deferred**: Adds infrastructure complexity, implement if in-memory insufficient
- **Alternative 2**: Qdrant as cache (store queries as vectors)
  - **Rejected**: Overkill, semantic similarity not needed for exact match caching
- **Alternative 3**: n8n's built-in caching
  - **Rejected**: n8n doesn't have native query result caching

---

## 6. Error Handling Patterns

### Decision

**n8n Error Handling Strategy**:
1. **HTTP Request Node Settings**:
   - Continue on Fail: TRUE (prevents workflow crash)
   - Retry: 3 attempts
   - Retry Delay: Exponential (1s, 2s, 4s)
   - Timeout: 30 seconds

2. **Error Branch Pattern**:
```
[HTTP Request: Call Ollama]
  ├─ On Success → [Continue Workflow]
  └─ On Error → [IF Node: Check Error Type]
                  ├─ Timeout → [Try Anthropic Fallback]
                  ├─ Rate Limit → [Wait & Retry]
                  └─ Other → [Return Error Response]
```

3. **Error Response Format**:
```json
{
  "error": true,
  "message": "Unable to process your request. Please try again.",
  "code": "LLM_TIMEOUT",
  "timestamp": "2025-10-30T12:00:00Z"
}
```

### Rationale

- **Continue on Fail**: Enables error branch logic, doesn't crash entire workflow
- **Exponential Backoff**: Reduces load on failing services
- **User-Friendly Messages**: No technical details exposed to end users
- **Structured Error Codes**: Enables client-side error handling

### Alternatives Considered

- **Alternative 1**: Try-catch blocks in Code Node
  - **Rejected**: Less visual, harder to debug than n8n's built-in error branches
- **Alternative 2**: Global error handler workflow
  - **Deferred**: Implement if common error patterns emerge across multiple workflows

---

## 7. Token Usage Tracking

### Decision

**Tracking Mechanism**: Parse LLM API responses in `Code Node`, aggregate in metrics workflow

**Implementation**:
```javascript
// Code Node: Extract token usage
const llmResponse = $json.llm_response;

// Ollama doesn't return token count directly
// Estimate: ~4 chars per token for English text
const estimatedTokens = Math.ceil((llmResponse.response?.length || 0) / 4);

return [{
  json: {
    ...llmResponse,
    token_usage: {
      prompt_tokens: Math.ceil(($json.prompt?.length || 0) / 4),
      completion_tokens: estimatedTokens,
      total_tokens: estimatedTokens + Math.ceil(($json.prompt?.length || 0) / 4),
      provider: 'ollama',
      cost_usd: 0  // Ollama is free
    }
  }
}];
```

**Aggregation Workflow** (scheduled daily):
1. Fetch n8n execution logs via API
2. Extract token_usage from each execution
3. Sum by provider, workflow, date
4. Export to CSV or database

### Rationale

- **Character-Based Estimation**: Ollama doesn't expose token counts, 4-char heuristic is ~80% accurate
- **Cost Tracking**: Even though Ollama is free, track tokens for cloud fallback cost estimation
- **Execution Log Storage**: Leverages n8n's built-in data retention

### Alternatives Considered

- **Alternative 1**: Use tiktoken library in Code Node for exact counts
  - **Deferred**: Requires npm package installation in n8n, estimation sufficient for MVP
- **Alternative 2**: External token counter API
  - **Rejected**: Adds latency and external dependency

---

## 8. Performance Optimization

### Decision

**n8n Configuration**:
```yaml
# docker-compose.yml or n8n environment variables
N8N_EXECUTIONS_MODE=queue
N8N_EXECUTIONS_PROCESS=own
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PORT=6379
EXECUTIONS_DATA_MAX_AGE=30  # days
EXECUTIONS_DATA_PRUNE=true
```

**Worker Configuration**:
- **Queue Mode**: Enabled (handles concurrent workflows)
- **Workers**: 5 (matches concurrency requirement from spec)
- **Redis**: Required for queue mode
- **Execution Pruning**: Auto-delete after 30 days

**Workflow-Level Optimization**:
- **Batch Processing**: Use `Split In Batches` node for large document sets
- **Parallel Branches**: Split independent tasks (e.g., embed multiple chunks simultaneously)
- **Lazy Loading**: Only fetch data when needed (avoid preloading entire dataset)

### Rationale

- **Queue Mode**: Prevents workflow conflicts, enables horizontal scaling
- **Redis Backing**: Industry-standard queue, reliable for production
- **Worker Count**: Balances concurrency vs resource usage (5 = spec requirement)
- **Pruning**: Prevents database bloat, maintains performance

### Alternatives Considered

- **Alternative 1**: Regular mode (no queue)
  - **Rejected**: Cannot handle concurrent workflows reliably
- **Alternative 2**: 10+ workers
  - **Rejected**: Exceeds MVP requirements, increases resource usage unnecessarily

---

## Summary of Decisions

| Topic | Decision | Rationale |
| :--- | :--- | :--- |
| **Document Processing** | Code Node + HTTP Request | Visual, flexible, no external scripts |
| **Ollama Integration** | Non-streaming POST requests | Simpler n8n integration |
| **Qdrant Configuration** | Cosine distance, HNSW index | Standard for embeddings, fast search |
| **Workflow Management** | Manual JSON export/import | Simple, version controlled |
| **Caching** | In-memory with TTL | Fast, no external dependencies |
| **Error Handling** | n8n error branches + retry | Visual, constitution-compliant |
| **Token Tracking** | Character-based estimation | Good enough for MVP, no libraries |
| **Performance** | Queue mode + 5 workers | Meets spec, production-ready |

---

## Technology Stack Final

| Component | Technology | Version | Justification |
| :--- | :--- | :--- | :--- |
| **Orchestration** | n8n | v1.x | Visual workflows, extensive integrations |
| **LLM (Primary)** | Ollama | latest | Free, local, privacy-preserving |
| **LLM (Fallback)** | Anthropic Claude | 3.5 Sonnet | High quality, good API |
| **Embeddings** | nomic-embed-text | via Ollama | 768d, optimized for RAG |
| **Vector DB** | Qdrant | v1.7+ | Fast, self-hosted, feature-rich |
| **Queue** | Redis | v7.x | Required for n8n queue mode |
| **Deployment** | Docker Compose | v2.x | Simple multi-container setup |

---

**Research Status**: ✅ COMPLETE - All 8 research tasks resolved with documented decisions.

**Next Phase**: Create data-model.md, contracts/, and quickstart.md per Phase 1 plan.
