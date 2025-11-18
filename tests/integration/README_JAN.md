# Jan Integration Testing Guide

This guide explains how to test the Jan provider for privacy-first local LLM inference.

---

## Prerequisites

### 1. Start Jan via Docker Compose

```bash
# From project root
docker-compose up -d jan

# Check Jan is running
docker-compose ps jan
curl http://localhost:1337/v1/models
```

### 2. Download Models (First Time Only)

Jan requires at least one model to be downloaded. You have two options:

#### Option A: Via Jan UI (Recommended for first-time setup)

```bash
# Jan UI will be available at http://localhost:1337
# Navigate to the UI and download a model
# Recommended models for testing:
# - llama-3.1-8b-instruct (fastest)
# - mistral-7b-instruct (good quality)
# - phi-3-mini-4k-instruct (smallest)
```

#### Option B: Via CLI (if Jan supports it)

```bash
# Example (check Jan documentation for exact command)
docker exec orchestrator_jan jan download llama-3.1-8b-instruct
```

### 3. Verify Model Available

```bash
# Check models endpoint
curl http://localhost:1337/v1/models | jq '.data[].id'
```

You should see at least one model ID like:
```json
[
  "llama-3.1-8b-instruct",
  "mistral-7b-instruct"
]
```

---

## Running Tests

### Run All Jan Integration Tests

```bash
pytest tests/integration/test_jan_integration.py -v
```

### Run Specific Test Class

```bash
# Basic functionality tests
pytest tests/integration/test_jan_integration.py::TestJanIntegration -v

# Privacy mode tests
pytest tests/integration/test_jan_integration.py::TestJanPrivacyMode -v
```

### Run Individual Tests

```bash
# Test health check
pytest tests/integration/test_jan_integration.py::TestJanIntegration::test_health_check -v

# Test chat completion
pytest tests/integration/test_jan_integration.py::TestJanIntegration::test_chat_completion -v

# Test streaming
pytest tests/integration/test_jan_integration.py::TestJanIntegration::test_streaming -v
```

### Run with Output Capture

```bash
# Show print statements
pytest tests/integration/test_jan_integration.py -v -s

# Show detailed output
pytest tests/integration/test_jan_integration.py -vv -s
```

---

## Test Coverage

### TestJanIntegration

1. **test_health_check** - Verify Jan server is running
2. **test_list_models** - List available models
3. **test_chat_completion** - Basic completion test
4. **test_chat_completion_with_context** - Multi-turn conversation
5. **test_streaming** - Streaming completion
6. **test_cost_calculation** - Verify $0 cost
7. **test_temperature_variation** - Temperature parameter
8. **test_max_tokens_limit** - Max tokens enforcement
9. **test_error_handling_invalid_model** - Error handling
10. **test_concurrent_requests** - Concurrent request handling

### TestJanPrivacyMode

1. **test_local_only_execution** - Verify local-only config
2. **test_zero_cost_operation** - Verify zero cost
3. **test_no_api_key_required** - No auth required

---

## Expected Test Results

### All Tests Passing

```
tests/integration/test_jan_integration.py::TestJanIntegration::test_health_check PASSED [ 7%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_list_models PASSED [14%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_chat_completion PASSED [21%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_chat_completion_with_context PASSED [28%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_streaming PASSED [35%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_cost_calculation PASSED [42%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_temperature_variation PASSED [50%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_max_tokens_limit PASSED [57%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_error_handling_invalid_model PASSED [64%]
tests/integration/test_jan_integration.py::TestJanIntegration::test_concurrent_requests PASSED [71%]
tests/integration/test_jan_integration.py::TestJanPrivacyMode::test_local_only_execution PASSED [78%]
tests/integration/test_jan_integration.py::TestJanPrivacyMode::test_zero_cost_operation PASSED [85%]
tests/integration/test_jan_integration.py::TestJanPrivacyMode::test_no_api_key_required PASSED [92%]

============================================ 13 passed in 45.23s ============================================
```

---

## Troubleshooting

### Jan Not Running

**Error**: `Jan server not healthy`

**Solution**:
```bash
# Check if Jan is running
docker-compose ps jan

# Start Jan
docker-compose up -d jan

# Check logs
docker-compose logs jan
```

### No Models Available

**Error**: `No models available in Jan`

**Solution**:
```bash
# Check models
curl http://localhost:1337/v1/models

# If no models, download via UI or CLI
# Access UI at http://localhost:1337
```

### Model Loading Slow

**Symptom**: Tests timeout or take very long

**Solution**:
- Use smaller models (phi-3-mini, llama-3.1-8b)
- Increase test timeouts
- Ensure GPU is available (if using GPU models)

```bash
# Check GPU availability
docker exec orchestrator_jan nvidia-smi  # If using NVIDIA GPU
```

### Connection Refused

**Error**: `Connection refused to http://localhost:1337`

**Solution**:
```bash
# Check Jan is listening on correct port
docker-compose logs jan | grep 1337

# Check port mapping
docker-compose port jan 1337

# Try from inside Docker network
docker-compose exec n8n curl http://jan:1337/v1/models
```

### Tests Fail on CI/CD

**Issue**: Jan requires significant resources

**Solution**:
- Mark tests with `@pytest.mark.slow` or `@pytest.mark.integration`
- Skip on CI: `pytest -m "not integration"`
- Use mock provider for unit tests

---

## Performance Benchmarks

Expected performance on different hardware:

| Hardware | Model | Tokens/sec | Test Duration |
|----------|-------|------------|---------------|
| CPU Only (8 cores) | llama-3.1-8b | ~5 | ~60s |
| GPU (RTX 3090) | llama-3.1-8b | ~50 | ~30s |
| GPU (RTX 4090) | llama-3.1-8b | ~100 | ~20s |
| CPU Only | phi-3-mini | ~10 | ~45s |

---

## Privacy Mode Verification

Jan enables GDPR/HIPAA-compliant privacy mode:

### Verify Local Execution

```bash
# While tests run, monitor network traffic
# No external API calls should be made

# Check Docker network isolation
docker network inspect orchestrator_orchestrator

# Verify no internet access from Jan container
docker-compose exec jan ping -c 1 8.8.8.8
# Should fail if network is isolated
```

### Verify Zero Cost

```python
# All operations should have $0 cost
from src.providers.jan_provider import JanProvider

provider = JanProvider()
cost = provider.get_cost(1000000, 1000000)
assert cost == 0.0  # Always free
```

### Verify No API Keys Required

```python
# Should work without any environment variables
provider = JanProvider()  # No ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.
is_healthy = await provider.health_check()
assert is_healthy
```

---

## Next Steps

After Jan integration tests pass:

1. **Provider Router Integration**: Test Jan in router with failover
2. **Privacy Mode E2E**: Test full privacy workflow (MCP + Jan)
3. **Performance Optimization**: Optimize model loading and caching
4. **Production Deployment**: Configure Jan for production workloads

---

## References

- Jan Documentation: https://jan.ai/docs
- Provider Implementation: `src/providers/jan_provider.py`
- Docker Compose: `docker-compose.yml` (jan service)
- Integration Tests: `tests/integration/test_jan_integration.py`
