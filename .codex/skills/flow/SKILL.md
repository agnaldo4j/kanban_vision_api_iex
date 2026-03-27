---
name: flow
description: >
  Use when implementing or reviewing Elixir Flow pipelines in this repository.
  Covers partitioning, batching, reducers, and when Flow is appropriate versus
  plain Enum or Stream.
---

# Flow Skill

Use Flow only when concurrency over larger collections materially helps. Prefer `Enum` or `Stream` for small, simple, or latency-sensitive paths.

## Good Uses

- Large bounded collections
- CPU-heavy transformations
- Parallel aggregation by partition key

## Guardrails

- Call `Flow.partition/2` only when related items must land on the same reducer.
- Avoid partitioning for embarrassingly parallel work.
- Keep reducers stateful and mapping stages stateless.
- Validate memory and throughput tradeoffs before adopting Flow in hot paths.

## Typical Shape

```elixir
source
|> Flow.from_enumerable()
|> Flow.map(&transform/1)
|> Flow.partition(key: &partition_key/1)
|> Flow.reduce(fn -> initial_state() end, &accumulate/2)
|> Enum.to_list()
```

If the pipeline becomes a long-lived or back-pressure-sensitive stream, prefer GenStage instead.
