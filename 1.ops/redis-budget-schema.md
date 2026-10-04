# Redis Budget Schema Documentation

**Version**: 1.0
**Last Updated**: 2025-11-18
**Component**: Cost Tracking & Budget Enforcement

---

## Overview

The Redis budget schema enables real-time cost tracking and hard budget enforcement with <5ms latency using atomic operations. All budget operations use Redis transactions to prevent race conditions.

---

## Key Patterns

### 1. Cost Tracking Keys

**Format**: `cost:{period}:{entity_type}:{entity_id}`

```
cost:daily:user:user_123          # Daily cost for user_123
cost:daily:tier:0                 # Daily cost for Tier 0
cost:daily:total                  # Daily total cost (all users)

cost:weekly:user:user_123         # Weekly cost for user_123
cost:monthly:user:user_123        # Monthly cost for user_123
```

**Data Type**: String (float stored as string)
**Operations**: `INCRBYFLOAT`, `GET`, `DEL`
**TTL**:
- Daily: 86400 seconds (24 hours)
- Weekly: 604800 seconds (7 days)
- Monthly: 2592000 seconds (30 days)

**Example**:
```redis
# Increment user cost
INCRBYFLOAT cost:daily:user:user_123 0.000045

# Get current cost
GET cost:daily:user:user_123
# Returns: "0.0234"
```

---

### 2. Budget Limit Keys

**Format**: `budget:{entity_id}:{period}:limit`

```
budget:user_123:daily:limit       # Daily budget limit for user_123
budget:user_123:weekly:limit      # Weekly limit
budget:user_123:monthly:limit     # Monthly limit
```

**Data Type**: String (float)
**Operations**: `SET`, `GET`, `DEL`
**TTL**: No expiration (persistent)

**Example**:
```redis
# Set daily budget limit
SET budget:user_123:daily:limit 10.00

# Get limit
GET budget:user_123:daily:limit
# Returns: "10.00"
```

---

### 3. Alert Threshold Keys

**Format**: `alert:{period}:{entity_id}:{threshold_percent}`

```
alert:daily:user_123:80           # 80% threshold alert
alert:daily:user_123:90           # 90% threshold alert
alert:daily:user_123:95           # 95% threshold alert
```

**Data Type**: String (flag: "1")
**Operations**: `SET NX`, `GET`, `DEL`
**TTL**: Same as cost period

**Purpose**: Prevent duplicate alerts for same threshold

**Example**:
```redis
# Set alert (only if not exists)
SET alert:daily:user_123:80 1 NX EX 86400
# Returns: 1 if set, nil if already exists

# Check if alert was sent
GET alert:daily:user_123:80
# Returns: "1" if alert sent, nil if not
```

---

## Atomic Operations

### Budget Deduction with Check

Uses WATCH/MULTI/EXEC transaction to atomically check budget and deduct cost:

```python
async def deduct_budget(user_id, period, cost):
    key = f"budget:{user_id}:{period}"
    limit_key = f"{key}:limit"

    while True:
        try:
            # Watch for concurrent modifications
            await redis.watch(key)

            # Get current values
            current = float(await redis.get(key) or 0)
            limit = float(await redis.get(limit_key) or 0)

            # Check budget
            if limit > 0 and (current + cost) > limit:
                raise BudgetExceededError(
                    f"Budget exceeded: ${current} + ${cost} > ${limit}"
                )

            # Atomic deduction
            await redis.multi()
            await redis.incrbyfloat(key, cost)
            await redis.execute()
            break

        except redis.WatchError:
            continue  # Retry on concurrent modification
```

### Cost Tracking with Pipelining

Track costs across multiple dimensions atomically:

```python
async def track_cost(user_id, tier, cost, period="daily"):
    # Define keys
    user_key = f"cost:{period}:user:{user_id}"
    tier_key = f"cost:{period}:tier:{tier}"
    total_key = f"cost:{period}:total"

    # Atomic pipeline
    async with redis.pipeline(transaction=True) as pipe:
        pipe.incrbyfloat(user_key, cost)
        pipe.incrbyfloat(tier_key, cost)
        pipe.incrbyfloat(total_key, cost)

        # Set TTL if key is new
        ttl = get_ttl_for_period(period)
        pipe.expire(user_key, ttl, nx=True)
        pipe.expire(tier_key, ttl, nx=True)
        pipe.expire(total_key, ttl, nx=True)

        results = await pipe.execute()

    return results[0]  # New user total
```

---

## Schema Examples

### User Budget Tracking

```redis
# Daily budget for user_123
SET budget:user_123:daily:limit 10.00
INCRBYFLOAT cost:daily:user:user_123 0.0015    # Track LLM call
INCRBYFLOAT cost:daily:user:user_123 0.0023    # Track another call

GET cost:daily:user:user_123
# Returns: "0.0038"

# Check if over 80% of budget
GET budget:user_123:daily:limit
# Returns: "10.00"
# 0.0038 / 10.00 = 0.038% (not at threshold yet)
```

### Tier Cost Aggregation

```redis
# Track costs by tier
INCRBYFLOAT cost:daily:tier:0 0.0000    # Ollama (free)
INCRBYFLOAT cost:daily:tier:1 0.0015    # Fireworks
INCRBYFLOAT cost:daily:tier:3 0.0234    # Claude

# Get tier costs
MGET cost:daily:tier:0 cost:daily:tier:1 cost:daily:tier:3
# Returns: ["0.0000", "0.0015", "0.0234"]
```

### Alert Management

```redis
# 80% threshold reached
SET alert:daily:user_123:80 1 NX EX 86400
# Returns: 1 (alert sent)

# Try to send again
SET alert:daily:user_123:80 1 NX EX 86400
# Returns: nil (alert already sent, don't duplicate)

# 90% threshold reached
SET alert:daily:user_123:90 1 NX EX 86400
# Returns: 1 (new threshold, send alert)
```

---

## Key Expiration Strategy

| Period | TTL | Cleanup |
|--------|-----|---------|
| Daily | 86400s (24h) | Automatic via TTL |
| Weekly | 604800s (7d) | Automatic via TTL |
| Monthly | 2592000s (30d) | Automatic via TTL |

**Note**: Limit keys (`budget:*:limit`) have no TTL and persist until explicitly deleted.

---

## Performance Characteristics

| Operation | Latency | Throughput |
|-----------|---------|------------|
| `INCRBYFLOAT` | <1ms | 100k+ ops/sec |
| `GET` | <1ms | 200k+ ops/sec |
| Pipeline (3 ops) | <2ms | 50k+ pipelines/sec |
| Transaction (WATCH/MULTI/EXEC) | <5ms | 20k+ txns/sec |

---

## Memory Usage

**Per User** (daily + weekly + monthly):
- Cost keys: 3 × ~50 bytes = 150 bytes
- Limit keys: 3 × ~50 bytes = 150 bytes
- Alert keys (max 9): 9 × ~50 bytes = 450 bytes
- **Total**: ~750 bytes per user

**For 10,000 users**: ~7.5 MB

**For 100,000 users**: ~75 MB

---

## Migration & Cleanup

### Reset Daily Budgets

```redis
# Delete all daily cost keys
SCAN 0 MATCH cost:daily:* COUNT 100
# For each key: DEL {key}

# Delete all daily alerts
SCAN 0 MATCH alert:daily:* COUNT 100
# For each key: DEL {key}
```

### Change User Budget

```redis
# Update limit
SET budget:user_123:daily:limit 20.00

# Optionally reset current spend
DEL cost:daily:user:user_123
```

### Export Budget Data

```python
async def export_daily_budgets():
    budgets = {}

    # Scan all user cost keys
    cursor = 0
    while True:
        cursor, keys = await redis.scan(
            cursor, match="cost:daily:user:*", count=100
        )

        for key in keys:
            user_id = key.split(":")[-1]
            cost = float(await redis.get(key) or 0)
            limit = float(await redis.get(f"budget:{user_id}:daily:limit") or 0)

            budgets[user_id] = {
                "cost": cost,
                "limit": limit,
                "utilization": cost / limit if limit > 0 else 0
            }

        if cursor == 0:
            break

    return budgets
```

---

## Best Practices

### 1. Always Use Transactions for Budget Checks

❌ **Bad** (race condition):
```python
current = await redis.get(key)
if current + cost > limit:
    raise BudgetExceededError()
await redis.incrbyfloat(key, cost)
```

✅ **Good** (atomic):
```python
await redis.watch(key)
# ... check budget ...
await redis.multi()
await redis.incrbyfloat(key, cost)
await redis.execute()
```

### 2. Set TTL on First Write

```python
await redis.incrbyfloat(key, cost)
await redis.expire(key, ttl, nx=True)  # Only set if no TTL
```

### 3. Use Pipelining for Batch Operations

```python
async with redis.pipeline(transaction=True) as pipe:
    for user_id, cost in user_costs:
        pipe.incrbyfloat(f"cost:daily:user:{user_id}", cost)
    await pipe.execute()
```

### 4. Monitor Alert Key Existence Before Sending

```python
alert_key = f"alert:daily:{user_id}:80"
was_set = await redis.set(alert_key, "1", nx=True, ex=86400)

if was_set:
    await send_alert(user_id, "80% budget utilization")
```

---

## Integration with LLMOps

The budget system integrates with LLMOps logging:

```python
from src.llmops.logger import LLMOpsLogger
from src.cost.redis_tracker import RedisCostTracker

# Log LLM invocation
trace_id = await logger.log_invocation(
    user_id="user_123",
    tier=1,
    model="llama-v3p1-8b",
    prompt_tokens=150,
    completion_tokens=50,
    cost=0.0015,
    latency_ms=234,
    success=True
)

# Track cost in Redis (real-time)
await cost_tracker.track_cost(
    user_id="user_123",
    tier=1,
    cost=0.0015,
    period="daily"
)

# Check budget before next call
try:
    await budget_enforcer.deduct_budget(
        user_id="user_123",
        period="daily",
        cost=0.0020  # Estimated cost
    )
except BudgetExceededError:
    # Fallback to cheaper tier or reject
    pass
```

---

## Monitoring Queries

### Top Spenders (Daily)

```python
async def get_top_spenders(limit=10):
    spenders = []

    cursor = 0
    while True:
        cursor, keys = await redis.scan(
            cursor, match="cost:daily:user:*", count=100
        )

        for key in keys:
            user_id = key.split(":")[-1]
            cost = float(await redis.get(key) or 0)
            spenders.append((user_id, cost))

        if cursor == 0:
            break

    # Sort and return top N
    spenders.sort(key=lambda x: x[1], reverse=True)
    return spenders[:limit]
```

### Budget Utilization Report

```python
async def budget_utilization_report(period="daily"):
    report = {
        "total_users": 0,
        "over_80_percent": 0,
        "over_90_percent": 0,
        "over_95_percent": 0,
        "exceeded": 0
    }

    cursor = 0
    while True:
        cursor, keys = await redis.scan(
            cursor, match=f"cost:{period}:user:*", count=100
        )

        for key in keys:
            user_id = key.split(":")[-1]
            cost = float(await redis.get(key) or 0)
            limit = float(await redis.get(f"budget:{user_id}:{period}:limit") or 0)

            if limit == 0:
                continue

            report["total_users"] += 1
            utilization = cost / limit

            if utilization >= 1.0:
                report["exceeded"] += 1
            elif utilization >= 0.95:
                report["over_95_percent"] += 1
            elif utilization >= 0.90:
                report["over_90_percent"] += 1
            elif utilization >= 0.80:
                report["over_80_percent"] += 1

        if cursor == 0:
            break

    return report
```

---

## References

- **Implementation**: `src/cost/redis_tracker.py`
- **Budget Enforcer**: `src/budget/enforcer.py`
- **LLMOps Integration**: `src/llmops/logger.py`
- **Redis Documentation**: https://redis.io/commands/
