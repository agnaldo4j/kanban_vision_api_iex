# 0001. Use CQS And Hexagonal Boundaries With In-Memory Persistence

- Status: accepted
- Date: 2026-03-27

## Context

The project is an Elixir umbrella organized around `kanban_domain`, `usecase`,
`persistence`, and `web_api`.

The intended architecture is closer to Clean Architecture, Hexagonal
Architecture, and Screaming Architecture than to a framework-first design:

- `kanban_domain` should remain clean and independent of transport, runtime
  process details, and persistence mechanisms.
- `usecase` should express business operations explicitly.
- `persistence` should implement repository adapters.
- `web_api` should translate HTTP requests and responses only.

At the same time, the current project intentionally keeps state only during
process execution to simplify the implementation. There is no immediate plan to
implement CQRS. The near-term goal is to keep a simple in-memory runtime while
preserving an architecture that can evolve toward object prevalence with
persisted commands and snapshots later.

Before this ADR, part of the application layer depended directly on concrete
adapter modules such as `KanbanVisionApi.Agent.Organizations` and
`KanbanVisionApi.Agent.Simulations`. Documentation also used CQRS terminology
even though the implementation uses a single model and explicit command/query
DTOs.

## Decision

We adopt the following architectural decisions for the project:

1. The project follows CQS, not CQRS, at the application boundary.
   Each use case entrypoint must receive either a Command DTO or a Query DTO.
   Controllers, routers, and adapters must not pass mixed ad-hoc parameters into
   use cases.

2. In-memory persistence remains the current runtime model.
   Agent-backed adapters are acceptable while the project keeps state alive only
   during execution.

3. The architecture must remain prevalence-ready.
   Future persistence based on persisted commands and snapshots must be possible
   without redesigning the domain and use case layers.

4. Dependency direction must remain inward.
   Domain and use case code must not depend directly on concrete persistence or
   transport modules.

5. Repository adapter selection must happen at the application boundary.
   The composition root is responsible for wiring concrete adapters into the
   application runtime.

6. GenServer remains acceptable as an orchestration/runtime mechanism when it
   represents the live application state, but it must not absorb business rules.

## Consequences

### Positive

- The codebase stays aligned with a use-case-first architecture.
- The project keeps its current implementation simplicity.
- The path toward a prevalence-style persistence model remains open.
- Business operations become easier to test independently of HTTP concerns.
- Architectural terminology becomes more accurate and less misleading.

### Negative

- Some existing abstractions still expose runtime details such as `pid`.
- The current adapters still carry infrastructure-oriented contracts that will
  need another refactor phase.
- The transition is incremental, so the codebase will temporarily contain a mix
  of improved and still-pending architectural boundaries.

## Execution Plan

### Priority 1

- Reinforce CQS in repository guidance and project documentation.
- Centralize repository adapter selection in the application boundary.
- Remove direct concrete adapter defaults from individual use case modules.

Status:
- Completed in this iteration.

### Priority 2

- Remove `pid` leakage from domain repository ports.
- Replace infrastructure-shaped repository contracts with ports centered on
  business intent.
- Keep the in-memory implementation behind those refined ports.

Status:
- Planned.

### Priority 3

- Replace string-based error mapping between persistence, use case, and HTTP
  with structured application errors.
- Ensure HTTP status mapping depends on explicit error categories rather than
  message parsing.

Status:
- Planned.

### Priority 4

- Make bounded contexts more uniform so `board`, `organization`, and
  `simulation` follow the same architectural pattern.
- Expand contract and integration coverage around ports and adapters.

Status:
- Planned.

## Notes

This ADR intentionally records target direction and phased execution together.
The runtime remains in-memory for now, but future changes must preserve the
decisions above unless a newer ADR supersedes this one.
