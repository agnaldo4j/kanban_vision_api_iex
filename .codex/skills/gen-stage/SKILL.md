---
name: gen-stage
description: >
  Use when building or reviewing back-pressure-aware event pipelines with
  GenStage in this repository. Covers producer, consumer, producer-consumer,
  dispatching, and supervision concerns.
---

# GenStage Skill

Use GenStage when demand-driven concurrency matters more than simple collection processing.

## Reach For GenStage When

- Producers and consumers run continuously
- Back-pressure is required
- You need `:producer`, `:consumer`, or `:producer_consumer` stages
- The pipeline must be supervised as part of the OTP tree

## Guardrails

- Producers implement `handle_demand/2`.
- Consumers and producer-consumers implement `handle_events/3`.
- Tune `max_demand` and `min_demand` deliberately; do not leave defaults unquestioned in high-volume pipelines.
- Use supervision strategies that preserve subscriptions after producer restarts.

## Typical Shape

```elixir
children = [
  {MyProducer, []},
  {MyTransformer, []},
  {MyConsumer, []}
]
```

Choose Flow instead when the workload is batch-oriented and can be expressed as collection transformations.
