# Architecture Update v2.0 - Tool Integration Summary

**Date**: 2025-11-17
**Status**: Constitution & Spec Updated, Plan/Research/Tasks Pending
**Breaking Changes**: Yes - New unified LLM interface layer

## Overview

This document summarizes the architectural updates to integrate professional-grade tools for cost optimization, observability, and intelligent routing.

## Tools Added

### Essential (Priority 1 - Week 1-2)

1. **aisuite** - Unified LLM Interface
   - **Purpose**: Single API for all LLM providers (Ollama, Claude, Gemini, OpenAI)
   - **Integration**: HTTP wrapper service, n8n calls aisuite instead of individual providers
   - **Benefit**: Simplifies n8n workflows, provider switching without workflow changes

2. **RouteLLM** - Intelligent Query Routing
   - **Purpose**: Automatically routes queries to cost-optimal models based on complexity
   - **Integration**: Analyzes queries before aisuite call, selects appropriate model
   - **Benefit**: 70%+ of queries routed to cheaper models (Ollama/Gemini Flash)

3. **MCPcat** - Production Monitoring
   - **Purpose**: Real-time tracking of agent tool calls, errors, performance
   - **Integration**: Observes n8n workflow executions, logs to monitoring backend
   - **Benefit**: Real-time visibility into agent behavior and costs

4. **Helicone** - Cost Proxy & Caching
   - **Purpose**: LLM request caching, cost tracking, logging
   - **Integration**: Proxy between aisuite and LLM providers
   - **Benefit**: 20%+ cache hit rate, automated cost tracking, zero code changes

### High Priority (Priority 2 - Week 3-4)

5. **OpenTelemetry** - Distributed Tracing
   - **Purpose**: End-to-end request tracing across n8n → aisuite → providers
   - **Integration**: Instrumentation in each service, traces to Jaeger/Zipkin
   - **Benefit**: Visual trace diagrams for debugging, latency analysis

6. **Firecrawl** - Web Scraping
   - **Purpose**: Extract LLM-friendly content from web URLs
   - **Integration**: n8n HTTP Request node calls Firecrawl API
   - **Benefit**: Clean markdown output, handles JavaScript rendering

7. **LangSmith** or **Langfuse** - LLM Monitoring
   - **Purpose**: Prompt/response logging, trace visualization, cost analytics
   - **Integration**: SDK integration in aisuite service
   - **Benefit**: Full audit trail, prompt engineering insights, cost dashboards

8. **PageIndex MCP** - Vectorless RAG
   - **Purpose**: Keyword-based document retrieval without embeddings
   - **Integration**: MCP server called from n8n for documentation queries
   - **Benefit**: 40% reduction in embedding API calls for docs

## Updated Architecture

### Request Flow (New)

```
User Query
    ↓
n8n Workflow (Visual orchestration)
    ↓
RouteLLM (Analyze complexity)
    ↓
aisuite (Unified LLM API) + Helicone Proxy (Caching/Logging)
    ↓
LLM Provider (Ollama/Claude/Gemini/GPT-4)
    ↓
Response + Tracing (OpenTelemetry) + Logging (LangSmith/MCPcat)
```

### Container Stack (Updated)

**Required Services**:
- n8n (orchestration)
- aisuite (LLM interface layer) **NEW**
- RouteLLM (routing service) **NEW**
- Helicone (cost proxy) **NEW**
- Ollama (local LLM)
- Qdrant (vector database)
- Redis (n8n queue + caching)

**Observability Services**:
- OpenTelemetry Collector **NEW**
- Jaeger or Zipkin (trace backend) **NEW**
- LangSmith or Langfuse (LLM monitoring) **NEW**
- MCPcat (agent monitoring) **NEW**

**Optional Services**:
- Firecrawl (web scraping) **NEW**
- PageIndex MCP server (vectorless RAG) **NEW**

### Memory Requirements (Updated)

**Previous**: 16GB RAM
**New**: 24GB RAM

Breakdown:
- Ollama: 8GB
- Qdrant: 4GB
- n8n: 2GB
- aisuite: 2GB
- Helicone: 1GB
- OpenTelemetry + Jaeger: 2GB
- LangSmith/Langfuse: 1GB
- Headroom: 4GB

## Constitution Changes (v1.0 → v2.0)

### Modified Principles

**II. LLM-Agnostic Architecture**
- **Before**: Direct calls to multiple providers
- **After**: ALL calls through aisuite unified interface

**IV. Cost-Conscious Design**
- **Added**: Helicone for automated caching
- **Added**: RouteLLM for intelligent routing
- **Added**: MCPcat for real-time cost tracking

**V. Observable Agent Flows**
- **Added**: OpenTelemetry distributed tracing
- **Added**: LangSmith/Langfuse for prompt/response capture
- **Added**: MCPcat for agent-specific metrics

### New Principles

**VI. Intelligent Routing**
- RouteLLM determines model based on query complexity
- Simple → Ollama/Gemini Flash (cheap)
- Medium → Claude 3.5/GPT-4 (balanced)
- Complex → Claude Opus/GPT-4 Turbo (premium)
- Manual override available

**VII. Tool Integration Standards**
- Use MCP (Model Context Protocol) patterns
- Firecrawl for web scraping
- PageIndex MCP for documentation
- Composio/Rube for app integrations (future)
- AgentAuth for OAuth (future)

## Specification Updates (01-spec.md)

### New Functional Requirements

**Unified LLM Interface (FR-027 to FR-032)**
- ALL LLM calls through aisuite
- aisuite exposes HTTP API for n8n
- Provider fallback chain via aisuite config
- Token tracking via Helicone proxy

**Intelligent Routing (FR-040 to FR-045)**
- RouteLLM analyzes query complexity
- Automatic model selection based on complexity tier
- Routing decisions logged for auditability
- Manual override via workflow parameter

**Web Content Extraction (FR-046 to FR-050)**
- Firecrawl for web URL extraction
- LLM-friendly markdown output
- JavaScript rendering support
- Graceful fallback to simple HTTP

**Vectorless RAG (FR-051 to FR-055)**
- PageIndex MCP for documentation
- Keyword-based retrieval without embeddings
- Combined with Qdrant vector search
- Graceful degradation if PageIndex fails

**Enhanced Observability (FR-038 to FR-039)**
- OpenTelemetry distributed tracing
- MCPcat for tool call tracking
- LangSmith/Langfuse for prompt logging

### New Success Criteria

- **SC-011**: 70%+ queries routed to cost-optimized models
- **SC-012**: 20%+ cache hit rate via Helicone
- **SC-013**: 100% trace coverage with OpenTelemetry
- **SC-014**: 95%+ web extraction success rate
- **SC-015**: 40% reduction in embedding calls via PageIndex
- **SC-016**: 100% prompt/response audit trail
- **SC-019**: Monthly costs < $50 with intelligent routing
- **SC-020**: 60% faster debugging with distributed tracing

## Research Topics (for research.md update)

### New Research Tasks

1. **aisuite Setup & Configuration**
   - Question: How to deploy aisuite as HTTP service accessible to n8n?
   - Research: Docker deployment, API format, provider configuration
   - Decision TBD: Port selection, authentication method, rate limiting

2. **RouteLLM Integration**
   - Question: How to integrate RouteLLM with aisuite for pre-call routing?
   - Research: RouteLLM API, complexity scoring algorithm, model tier mapping
   - Decision TBD: Routing thresholds, override mechanism

3. **Helicone Proxy Setup**
   - Question: How to configure Helicone between aisuite and providers?
   - Research: Proxy configuration, cache TTL, cost dashboard setup
   - Decision TBD: Caching strategy, logging verbosity

4. **OpenTelemetry Instrumentation**
   - Question: How to instrument n8n, aisuite, and RouteLLM for tracing?
   - Research: OpenTelemetry SDKs, trace propagation, Jaeger vs Zipkin
   - Decision TBD: Trace backend, sampling rate, span attributes

5. **LangSmith vs Langfuse**
   - Question: Which LLM monitoring tool to use (paid vs opensource)?
   - Research: Feature comparison, cost, aisuite integration ease
   - Decision TBD: Primary monitoring platform

6. **Firecrawl API Integration**
   - Question: Firecrawl API endpoints, response format, rate limits
   - Research: API documentation, pricing, n8n node configuration
   - Decision TBD: Self-hosted vs cloud, fallback strategy

7. **PageIndex MCP Server**
   - Question: How to deploy MCP server and integrate with n8n?
   - Research: MCP protocol, server deployment, document indexing
   - Decision TBD: Documentation sources, update frequency

8. **MCPcat Deployment**
   - Question: How to deploy MCPcat to monitor n8n workflows?
   - Research: MCPcat setup, metrics collection, dashboard configuration
   - Decision TBD: Metrics backend, retention policy

## Implementation Order (for tasks.md update)

### Phase 0: Infrastructure Setup (NEW - Week 1)
- Deploy aisuite HTTP service
- Deploy Helicone proxy
- Deploy RouteLLM service
- Configure provider credentials in aisuite
- Test unified API with simple query

### Phase 1: Observability Foundation (NEW - Week 2)
- Deploy OpenTelemetry Collector
- Deploy Jaeger or Zipkin
- Instrument aisuite with OpenTelemetry
- Deploy LangSmith or Langfuse
- Deploy MCPcat
- Verify end-to-end traces

### Phase 2-4: Core RAG (As Before)
- Document ingestion (Qdrant)
- Query processing (via aisuite)
- Multi-agent orchestration

### Phase 5: Advanced Features (Week 5-6)
- Integrate RouteLLM intelligent routing
- Add Firecrawl web extraction
- Add PageIndex MCP for documentation
- Tune routing thresholds based on metrics

### Phase 6: Optimization & Monitoring (Week 7)
- Configure Helicone caching
- Set up cost dashboards (LangSmith/Helicone)
- Set up budget alerts
- Performance tuning based on traces

## Configuration Files Needed (NEW)

```
configs/
  aisuite-config.yaml        # Provider credentials, fallback chain
  routellm-config.yaml       # Routing thresholds, model tiers
  helicone-config.yaml       # Cache TTL, logging settings
  otel-collector-config.yaml # Trace exporters, sampling
  langsmith-config.yaml      # Project settings, API keys
  firecrawl-config.yaml      # API endpoint, rate limits
  pageindex-mcp-config.yaml  # Document sources, MCP server
```

## Docker Compose Updates (NEW Services)

```yaml
services:
  aisuite:
    image: aisuite/aisuite:latest
    ports: ["8000:8000"]
    env_file: .env
    volumes: ["./configs/aisuite-config.yaml:/config.yaml"]

  routellm:
    image: routellm/routellm:latest
    ports: ["8001:8001"]
    volumes: ["./configs/routellm-config.yaml:/config.yaml"]

  helicone:
    image: helicone/helicone:latest
    ports: ["8002:8002"]
    env_file: .env

  otel-collector:
    image: otel/opentelemetry-collector:latest
    ports: ["4317:4317", "4318:4318"]
    volumes: ["./configs/otel-collector-config.yaml:/etc/otel/config.yaml"]

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports: ["16686:16686", "14268:14268"]

  langsmith:  # OR langfuse
    image: langsmith/langsmith:latest  # or langfuse/langfuse
    ports: ["8080:8080"]
    env_file: .env

  mcpcat:
    image: mcpcat/mcpcat:latest
    ports: ["8003:8003"]
    volumes: ["./configs/mcpcat-config.yaml:/config.yaml"]
```

## Next Steps

1. ✅ **DONE**: Update constitution.md (v2.0.0)
2. ✅ **DONE**: Update spec.md with new FRs and success criteria
3. **TODO**: Update plan.md:
   - Technical Context with new tool stack
   - Constitution checks for principles VI & VII
   - Phase 0 research with 8 new research topics
4. **TODO**: Update research.md with technology decisions for all 8 new tools
5. **TODO**: Update tasks.md with new implementation phases

## Cost Impact

**Previous Monthly Cost**: $0-50 (mostly Ollama)

**New Monthly Cost** (estimated):
- Ollama: $0 (local)
- RouteLLM routing: 70% queries → $0 (Ollama/Gemini Flash free tier)
- RouteLLM routing: 25% queries → $15 (Claude/GPT-4)
- RouteLLM routing: 5% queries → $10 (Claude Opus/GPT-4 Turbo)
- Helicone cache: 20% reduction → -$5 savings
- **Total**: $20-30/month (40-60% reduction with intelligent routing)

**Tool Costs**:
- aisuite: Free (opensource)
- RouteLLM: Free (opensource)
- Helicone: Free tier (10K requests/month)
- OpenTelemetry: Free (opensource)
- Jaeger: Free (opensource)
- Langfuse: Free (opensource, self-hosted)
- MCPcat: Free (opensource)
- Firecrawl: $0-20/month (API tier)
- PageIndex MCP: Free (opensource)

**Infrastructure Cost**:
- VPS upgrade: +8GB RAM = ~$10-15/month more

**Net Impact**: Break-even to slight savings, massive observability upgrade

---

## Summary for User

I've updated the specification kit to reflect the robust architecture with professional-grade tools:

### Completed Updates:

1. **Constitution (v2.0.0)**: Added 2 new principles (Intelligent Routing, Tool Integration Standards), enhanced existing principles with specific tools

2. **Spec.md**: Added 23 new functional requirements across 4 categories (Unified LLM Interface, Intelligent Routing, Web Extraction, Vectorless RAG, Enhanced Observability), plus 10 new success criteria

3. **This Summary Doc**: Complete architecture blueprint for implementing all tools

### Next Actions:

The remaining files (plan.md, research.md, tasks.md) need manual updates due to character encoding issues with the Edit tool. However, this summary document provides everything needed to proceed:

- **For plan.md**: Copy the Technical Context, Constitution checks, and Research topics from above
- **For research.md**: Add the 8 new research tasks with decisions
- **For tasks.md**: Add Phase 0 (Infrastructure) and Phase 1 (Observability) before existing phases

Would you like me to create fresh versions of these files or provide specific guidance on any tool integration?
