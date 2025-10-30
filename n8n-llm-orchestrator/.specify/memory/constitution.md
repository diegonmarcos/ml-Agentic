<!--
Sync Impact Report
==================
Version: 0.0.0 → 1.0.0 (Initial ratification)
Modified Principles: N/A (new constitution)
Added Sections: Core Principles (5), Architecture Constraints, Quality Standards, Governance
Removed Sections: N/A
Templates Status: ⚠️ Pending initial spec, plan, and tasks creation
Follow-up TODOs: None
-->

# n8n LLM Orchestrator Constitution

## Core Principles

### I. Visual-First Design
All agentic workflows MUST be representable in n8n's visual interface. This ensures:
- Non-technical stakeholders can understand agent flows at a glance
- Debugging is visual and intuitive
- No hidden logic in external scripts unless absolutely necessary for performance
- Complex multi-agent orchestrations remain maintainable

**Rationale**: Visual workflows reduce cognitive load and make agentic systems accessible to broader teams.

### II. LLM-Agnostic Architecture
The system MUST support multiple LLM providers interchangeably:
- OpenAI (GPT-4, GPT-3.5)
- Anthropic (Claude 3.5 Sonnet, Claude 3 Opus)
- Ollama (local models: Llama 3.1, Mistral, Qwen)

Requirements:
- Abstract LLM calls behind unified n8n node patterns
- Provider switching MUST NOT require workflow redesign
- Each agent can specify preferred provider via configuration
- Fallback chains supported (e.g., Ollama → OpenAI on failure)

**Rationale**: Avoid vendor lock-in, enable cost optimization, support offline/local operation.

### III. Fail-Safe Operations (NON-NEGOTIABLE)
Every LLM call, tool execution, and data retrieval MUST implement error handling:
- Automatic retries with exponential backoff (max 3 attempts)
- Graceful degradation when services unavailable
- Meaningful error messages returned to user
- Circuit breaker pattern for repeated failures
- No workflow crash—always return actionable response

**Rationale**: LLM APIs are inherently unreliable; production systems require resilience.

### IV. Cost-Conscious Design
Token usage and API costs MUST be actively managed:
- Monitor and log token consumption per workflow execution
- Implement prompt optimization strategies (chunking, compression)
- Cache LLM responses for identical queries (1-hour TTL)
- Prefer local Ollama for development and high-volume use cases
- Track monthly spend and set budget alerts

**Rationale**: Unchecked LLM usage can lead to unexpected costs; proactive monitoring prevents budget overruns.

### V. Observable Agent Flows
Every agent step MUST be traceable and debuggable:
- Structured logging with context (agent name, step, timestamp)
- Capture all LLM prompts and responses
- Track RAG retrieval results (chunks retrieved, relevance scores)
- Execution metrics (latency, token count, success rate)
- n8n execution logs retained for 30 days minimum

**Rationale**: Complex multi-agent systems are opaque without comprehensive observability.

## Architecture Constraints

### Vector Database Standards
- **Primary**: Qdrant (self-hosted) for production RAG workflows
- **Alternative**: Supabase Vector for cloud-hosted scenarios
- All embeddings MUST use consistent model (nomic-embed-text, 768 dimensions)
- Collections MUST include metadata: source, timestamp, chunk_id, version
- Backup collections daily via Qdrant snapshot API

### Document Processing Rules
- Chunk size: 800 characters (±200 acceptable for specific use cases)
- Chunk overlap: 200 characters minimum
- Top-k retrieval: 3-5 chunks (never exceed 10 to prevent context overflow)
- Re-ranking optional but recommended for precision-critical applications

### State Management
- Agent state MUST be passed explicitly between n8n nodes (no hidden globals)
- Long-running workflows MUST persist state to prevent data loss
- Maximum workflow execution time: 5 minutes (configurable per workflow)

## Quality Standards

### Testing Requirements
- All RAG pipelines MUST have evaluation datasets with ground truth
- Measure and track: retrieval accuracy (recall@k), answer relevance, latency
- Integration tests required for: document ingestion, query workflows, fallback paths
- Manual testing protocol documented for each workflow before production

### Performance Benchmarks
- RAG query response time: < 5 seconds end-to-end
- Document ingestion: > 10 docs/minute
- Concurrent workflow support: minimum 5 simultaneous executions
- LLM response timeout: 30 seconds (configurable)

### Security
- API keys stored in n8n credentials (never hardcoded)
- Vector database access restricted to local network or VPN
- User input sanitized before LLM prompts
- No PII in logs unless explicitly required and compliant

## Governance

This constitution supersedes all other development practices. Changes require:
1. Proposal with rationale and impact analysis
2. Version bump following semantic versioning (MAJOR.MINOR.PATCH)
3. Update to all dependent templates and documentation
4. Team review (or author review for solo projects)

All workflows and implementations MUST be verified against these principles during:
- Design review (before implementation)
- Code/workflow review (before deployment)
- Post-deployment audit (after 1 week in production)

Complexity that violates these principles MUST be explicitly justified and documented as technical debt with remediation plan.

**Version**: 1.0.0 | **Ratified**: 2025-10-30 | **Last Amended**: 2025-10-30
