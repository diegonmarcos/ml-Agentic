-- Migration: 001_llmops_schema.sql
-- Description: Create PostgreSQL schema for LLMOps observability
-- Version: v4.2.0
-- Date: 2025-11-18

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLE: llm_invocations
-- Purpose: Track all LLM invocations for cost tracking and analytics
-- Retention: 30 days (managed by application)
-- ============================================================================
CREATE TABLE IF NOT EXISTS llm_invocations (
    id BIGSERIAL PRIMARY KEY,
    trace_id UUID NOT NULL DEFAULT uuid_generate_v4(),
    timestamp TIMESTAMP DEFAULT NOW(),
    user_id VARCHAR(255),
    tier INTEGER NOT NULL CHECK (tier >= 0 AND tier <= 4),
    model VARCHAR(255) NOT NULL,
    prompt_tokens INTEGER NOT NULL CHECK (prompt_tokens >= 0),
    completion_tokens INTEGER NOT NULL CHECK (completion_tokens >= 0),
    cost DECIMAL(10, 6) NOT NULL CHECK (cost >= 0),
    latency_ms INTEGER NOT NULL CHECK (latency_ms >= 0),
    success BOOLEAN NOT NULL,
    error TEXT,
    task_type VARCHAR(100),
    privacy_mode BOOLEAN DEFAULT FALSE,
    provider VARCHAR(100)
);

-- Indexes for llm_invocations
CREATE INDEX IF NOT EXISTS idx_llm_trace ON llm_invocations(trace_id);
CREATE INDEX IF NOT EXISTS idx_llm_user_tier ON llm_invocations(user_id, tier);
CREATE INDEX IF NOT EXISTS idx_llm_timestamp ON llm_invocations(timestamp);
CREATE INDEX IF NOT EXISTS idx_llm_task_type ON llm_invocations(task_type);
CREATE INDEX IF NOT EXISTS idx_llm_provider ON llm_invocations(provider);
CREATE INDEX IF NOT EXISTS idx_llm_success ON llm_invocations(success);

-- Partial index for failed invocations (faster error analysis)
CREATE INDEX IF NOT EXISTS idx_llm_failures ON llm_invocations(timestamp, provider)
WHERE success = FALSE;

COMMENT ON TABLE llm_invocations IS 'All LLM invocations for cost tracking and analytics (30-day retention)';
COMMENT ON COLUMN llm_invocations.trace_id IS 'Unique ID linking all steps in a workflow';
COMMENT ON COLUMN llm_invocations.tier IS '0=Ollama local, 1=Fireworks/Together, 2=Ollama Vision, 3=Claude/Gemini, 4=RunPod/Salad';
COMMENT ON COLUMN llm_invocations.privacy_mode IS 'TRUE if query was executed in privacy mode (local-only)';

-- ============================================================================
-- TABLE: workflow_versions
-- Purpose: Version control for n8n workflows with A/B testing support
-- ============================================================================
CREATE TABLE IF NOT EXISTS workflow_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_id VARCHAR(255) NOT NULL,
    version INTEGER NOT NULL,
    changes TEXT,
    creator VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    performance_metrics JSONB,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'testing', 'active', 'archived')),
    UNIQUE(workflow_id, version)
);

CREATE INDEX IF NOT EXISTS idx_workflow_id ON workflow_versions(workflow_id, version);
CREATE INDEX IF NOT EXISTS idx_workflow_status ON workflow_versions(status);

COMMENT ON TABLE workflow_versions IS 'Version control for n8n workflows with performance tracking';
COMMENT ON COLUMN workflow_versions.performance_metrics IS 'JSONB: {avg_cost, avg_latency, success_rate, sample_size}';

-- ============================================================================
-- TABLE: agent_messages
-- Purpose: Message queue persistence for multi-agent coordination
-- Retention: 7 days
-- ============================================================================
CREATE TABLE IF NOT EXISTS agent_messages (
    id BIGSERIAL PRIMARY KEY,
    from_agent VARCHAR(255) NOT NULL,
    to_agent VARCHAR(255) NOT NULL,
    message_type VARCHAR(100) NOT NULL,
    content JSONB NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_from_to ON agent_messages(from_agent, to_agent);
CREATE INDEX IF NOT EXISTS idx_agent_timestamp ON agent_messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_agent_type ON agent_messages(message_type);

COMMENT ON TABLE agent_messages IS 'Message queue for multi-agent coordination (7-day retention)';

-- ============================================================================
-- TABLE: budget_pools
-- Purpose: Track user budget pools for hard limit enforcement
-- ============================================================================
CREATE TABLE IF NOT EXISTS budget_pools (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    period VARCHAR(20) NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly')),
    limit_usd DECIMAL(10, 2) NOT NULL CHECK (limit_usd > 0),
    current_spend DECIMAL(10, 4) DEFAULT 0 CHECK (current_spend >= 0),
    reset_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, period)
);

CREATE INDEX IF NOT EXISTS idx_budget_user ON budget_pools(user_id);
CREATE INDEX IF NOT EXISTS idx_budget_reset ON budget_pools(reset_at);

COMMENT ON TABLE budget_pools IS 'User budget pools with hard limits and auto-reset';
COMMENT ON COLUMN budget_pools.reset_at IS 'Timestamp when budget will reset (daily: midnight, weekly: Monday, monthly: 1st)';

-- ============================================================================
-- TABLE: tool_registry
-- Purpose: Centralized registry for agent tools
-- ============================================================================
CREATE TABLE IF NOT EXISTS tool_registry (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(100)[] NOT NULL,
    privacy_compatible BOOLEAN DEFAULT FALSE,
    requires VARCHAR(255)[] DEFAULT ARRAY[]::VARCHAR[],
    cost_tier VARCHAR(20) DEFAULT 'free' CHECK (cost_tier IN ('free', 'low', 'medium', 'high')),
    handler_type VARCHAR(50) NOT NULL CHECK (handler_type IN ('function', 'mcp_server', 'api', 'n8n_node')),
    handler_config JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tool_category ON tool_registry USING GIN (category);
CREATE INDEX IF NOT EXISTS idx_tool_privacy ON tool_registry(privacy_compatible);

COMMENT ON TABLE tool_registry IS 'Centralized registry for agent tools with dependencies';
COMMENT ON COLUMN tool_registry.requires IS 'Array of tool IDs this tool depends on';

-- ============================================================================
-- MATERIALIZED VIEW: tier_performance_summary
-- Purpose: Fast analytics for tier optimization
-- Refresh: Every hour
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS tier_performance_summary AS
SELECT
    task_type,
    tier,
    provider,
    COUNT(*) as total_invocations,
    COUNT(*) FILTER (WHERE success = TRUE) as successful_invocations,
    (COUNT(*) FILTER (WHERE success = TRUE) * 100.0 / COUNT(*))::DECIMAL(5,2) as success_rate,
    AVG(latency_ms)::INTEGER as avg_latency_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms)::INTEGER as p95_latency_ms,
    AVG(cost)::DECIMAL(10,6) as avg_cost,
    SUM(cost)::DECIMAL(10,2) as total_cost,
    MIN(timestamp) as first_seen,
    MAX(timestamp) as last_seen
FROM llm_invocations
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY task_type, tier, provider;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tier_perf_unique
ON tier_performance_summary(task_type, tier, provider);

COMMENT ON MATERIALIZED VIEW tier_performance_summary IS 'Aggregated performance metrics by task_type, tier, and provider (refreshed hourly)';

-- ============================================================================
-- FUNCTION: refresh_tier_performance_summary
-- Purpose: Refresh materialized view
-- ============================================================================
CREATE OR REPLACE FUNCTION refresh_tier_performance_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY tier_performance_summary;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_tier_performance_summary IS 'Refresh tier performance summary (call hourly via cron)';

-- ============================================================================
-- FUNCTION: cleanup_old_data
-- Purpose: Delete old data based on retention policies
-- Schedule: Run daily
-- ============================================================================
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS TABLE (
    table_name TEXT,
    rows_deleted BIGINT
) AS $$
DECLARE
    llm_deleted BIGINT;
    msg_deleted BIGINT;
BEGIN
    -- Delete llm_invocations older than 30 days
    DELETE FROM llm_invocations
    WHERE timestamp < NOW() - INTERVAL '30 days';
    GET DIAGNOSTICS llm_deleted = ROW_COUNT;

    -- Delete agent_messages older than 7 days
    DELETE FROM agent_messages
    WHERE timestamp < NOW() - INTERVAL '7 days';
    GET DIAGNOSTICS msg_deleted = ROW_COUNT;

    -- Return results
    RETURN QUERY SELECT 'llm_invocations'::TEXT, llm_deleted
    UNION ALL SELECT 'agent_messages'::TEXT, msg_deleted;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_data IS 'Delete data older than retention policy (30d for llm_invocations, 7d for agent_messages)';

-- ============================================================================
-- GRANTS (adjust for your specific user)
-- ============================================================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO orchestrator_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO orchestrator_user;

-- ============================================================================
-- INITIAL DATA: Example tool registrations
-- ============================================================================
INSERT INTO tool_registry (id, name, description, category, privacy_compatible, handler_type, handler_config)
VALUES
    ('web_search', 'Web Search', 'Search the web using Brave Search API',
     ARRAY['research', 'web_agent'], FALSE, 'api',
     '{"endpoint": "https://api.search.brave.com/res/v1/web/search", "auth_header": "X-Subscription-Token"}'::JSONB),

    ('mcp_filesystem', 'Local Filesystem', 'Read/write files via MCP server',
     ARRAY['coder', 'research'], TRUE, 'mcp_server',
     '{"url": "http://localhost:3001/mcp/filesystem", "allowed_paths": ["/data/projects"]}'::JSONB),

    ('mcp_git', 'Git Repository', 'Access git repositories via MCP server',
     ARRAY['coder', 'research'], TRUE, 'mcp_server',
     '{"url": "http://localhost:3002/mcp/git", "operations": ["read", "search", "log"]}'::JSONB),

    ('analyze_code', 'Code Analyzer', 'Analyze code for bugs and improvements',
     ARRAY['coder'], TRUE, 'function',
     '{"module": "src.tools.code_analyzer", "function": "analyze_code"}'::JSONB)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the schema was created correctly:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT * FROM tool_registry;
-- SELECT matviewname FROM pg_matviews WHERE schemaname = 'public';

COMMIT;
