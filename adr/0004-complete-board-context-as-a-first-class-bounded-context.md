# 0004. Complete Board Context As A First-Class Bounded Context

- Status: accepted
- Date: 2026-03-27
- Supersedes: none
- Related:
  - 0001-use-cqs-and-hexagonal-boundaries-with-in-memory-persistence
  - 0002-remove-pid-leakage-from-domain-repository-ports
  - 0003-adopt-structured-application-errors

## Context

ADR 0001 established that this project should scream the business domain through
explicit bounded contexts, use-case-first orchestration, and transport adapters
that only translate inputs and outputs.

After ADR 0002 and ADR 0003, `organization` and `simulation` already exposed a
complete architectural slice:

- explicit command/query DTOs
- dedicated use-case modules
- a supervised application orchestrator
- HTTP adapters and OpenAPI surface
- structured errors across boundaries

`board`, however, still lagged behind that shape. The domain entity and the
persistence adapter existed, but the public application boundary was incomplete.
That meant:

- the `board` context did not appear with the same clarity as the other
  bounded contexts
- use cases were partial and not organized in the same CQS shape
- the HTTP layer did not expose `board` as a first-class capability
- the architecture still did not fully scream the current domain model

The project continues to use in-memory persistence during runtime, with opaque
repository runtimes hiding process details. This ADR does not change that
runtime strategy. It completes the architectural slice for `board` using the
same conventions already adopted in the rest of the system.

## Decision

We will complete the `board` context as a first-class bounded context with the
same architectural shape used by `organization` and `simulation`.

The `board` context must include:

- a dedicated `KanbanVisionApi.Usecase.Board` GenServer orchestrator
- explicit command/query DTOs
- explicit use-case modules for board commands and queries
- a dedicated HTTP port, adapter, controller, and serializer
- OpenAPI documentation for the public board endpoints
- automated tests for usecase, controller, integration, router, and serializer

The chosen HTTP shape is:

- nested routes under simulation for board collection operations
- top-level routes for direct board lookup and deletion

The initial board HTTP surface is:

- `GET /api/v1/simulations/:simulation_id/boards`
- `POST /api/v1/simulations/:simulation_id/boards`
- `GET /api/v1/boards/:id`
- `DELETE /api/v1/boards/:id`

The create contract is intentionally minimal:

- request body contains only `name`
- `simulation_id` is authoritative from the route
- `workflow` and `workers` remain internal defaults for this phase

The board HTTP response remains intentionally narrow for now and exposes:

- `id`
- `name`
- `simulation_id`
- `created_at`
- `updated_at`

This ADR does not introduce:

- board update semantics
- board workflow mutation over HTTP
- board worker allocation over HTTP
- new persistence mechanisms beyond the current Agent-backed runtime

## Considered Options

### Option A

Keep `board` as a partial/internal context and only expose the existing delete
flow.

Why it was not chosen:

- keeps the architecture uneven across bounded contexts
- weakens Screaming Architecture by hiding a real domain capability
- increases future implementation cost because every new board flow would remain
  ad hoc

### Option B

Complete `board` now with the same CQS and hexagonal structure already used by
the other contexts.

Why it is preferred:

- aligns the codebase around one architectural shape
- makes `board` visible as a first-class domain concept
- reduces special cases in usecase and HTTP layers
- strengthens consistency for future board-related evolution

## Consequences

### Positive

- The application now screams `board` as a proper bounded context.
- `board`, `organization`, and `simulation` follow the same structural pattern.
- HTTP and OpenAPI now reflect the existing domain capability more clearly.
- Future board evolution can build on a stable CQS and adapter boundary.
- Tests can cover board behavior through the same layers used by the other
  contexts.

### Negative

- The change touches multiple apps in the umbrella at once.
- More public surface area now needs to be maintained in tests and docs.
- Future decisions about board workflow and worker management remain deferred,
  so the public board contract is intentionally incomplete for now.

## Execution Plan

### Phase 1: Board Application Boundary

- Add a dedicated `KanbanVisionApi.Usecase.Board` orchestrator.
- Wire `:board` repository resolution through the same configuration path used
  by the other contexts.
- Keep the current in-memory Agent adapter and opaque repository runtime model.

Status:
- Completed.

### Phase 2: Board CQS Surface

- Add explicit command and query DTOs for board operations.
- Add use-case modules for create, list, get-by-id, get-by-simulation, and
  delete.
- Keep structured logging and telemetry aligned with the existing usecase
  boundary.

Status:
- Completed.

### Phase 3: Board HTTP Adapter

- Add the HTTP port, adapter, controller, and serializer for board operations.
- Expose nested simulation board routes and direct board routes.
- Reuse structured error mapping from ADR 0003.

Status:
- Completed.

### Phase 4: OpenAPI And Test Alignment

- Document the board endpoints and schema in OpenAPI.
- Add or update usecase, serializer, router, controller, and integration tests.
- Validate the full repository quality gate after the change.

Status:
- Completed.

## Acceptance Criteria

- `board` has a dedicated usecase orchestrator supervised with the other
  contexts.
- `board` operations are modeled through explicit command/query DTOs and
  use-case modules.
- HTTP exposes collection operations under simulation and direct lookup/delete
  routes for boards.
- OpenAPI documents the board endpoints and response schema.
- The full quality gate passes:
  - `mix format`
  - `mix compile`
  - `mix test`
  - `mix credo --strict`
  - `mix dialyzer`
  - `env MIX_ENV=test mix coveralls --umbrella`

## Notes

This ADR completes the next structural step after ADR 0003. It keeps the
current runtime model and structured error contract while making the `board`
context fully visible and consistent across the application's architectural
boundaries.
