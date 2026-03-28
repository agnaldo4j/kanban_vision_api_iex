# 0005. Evolve Board With Explicit CQS Operations

- Status: accepted
- Date: 2026-03-27
- Supersedes: none
- Related:
  - 0001-use-cqs-and-hexagonal-boundaries-with-in-memory-persistence
  - 0003-adopt-structured-application-errors
  - 0004-complete-board-context-as-a-first-class-bounded-context

## Context

ADR 0004 elevated `board` to a first-class bounded context with explicit
commands, queries, use cases, HTTP adapters, and OpenAPI documentation.
That phase established the base read and lifecycle operations for boards:
create, list, get by id, get by simulation id, and delete.

At that point, the aggregate still behaved mostly like a named container.
The core board evolution rules that matter for a Kanban simulation were still
missing from the application boundary:

- board rename as an explicit command
- workflow step management as explicit operations
- worker allocation as explicit operations

Without those operations, the public API exposed `board` as a resource, but not
yet as a meaningful simulation aggregate. The project would continue to "scream"
resource CRUD more than business intent, and the usecase layer would still lack
the explicit commands needed to evolve the board through the same CQS style
already adopted in the rest of the system.

This decision remains aligned with the project's established architecture:

- CQS, not CQRS
- use cases as the primary organizing structure
- structured application errors
- in-memory persistence with opaque repository runtimes
- board-centric aggregate persistence, not partial workflow/worker repositories

## Decision

We will evolve the `board` context with explicit CQS operations for aggregate
mutation.

The board aggregate now supports these commands:

- rename board
- add workflow step
- remove workflow step
- reorder workflow step
- allocate worker
- remove worker

These operations are implemented as explicit command DTOs and explicit use cases
behind the `KanbanVisionApi.Usecase.Board` orchestrator.

The public HTTP contract exposes granular command-oriented endpoints instead of
a single aggregate patch operation:

- `PATCH /api/v1/boards/:id`
- `POST /api/v1/boards/:id/workflow/steps`
- `DELETE /api/v1/boards/:id/workflow/steps/:step_id`
- `PATCH /api/v1/boards/:id/workflow/steps/:step_id/order`
- `POST /api/v1/boards/:id/workers`
- `DELETE /api/v1/boards/:id/workers/:worker_id`

The board detail query response is expanded to expose the aggregate state needed
to observe these mutations:

- board summary fields
- workflow steps with required ability
- allocated workers with abilities

The chosen business semantics for this phase are:

- board rename updates only the board name
- workflow step addition creates an empty-task step with required ability
- workflow step removal removes the step without task migration logic
- workflow step reorder normalizes the final order deterministically
- worker allocation stores a board-local worker snapshot
- worker removal deletes that board-local snapshot

This phase does not introduce:

- task creation or movement
- service class mutation
- workflow batch patching
- cross-context worker references

## Consequences

### Positive

- `board` becomes a meaningful simulation aggregate instead of a thin resource.
- The project remains consistent with explicit CQS operations.
- Board evolution rules stay inside domain and usecase boundaries.
- HTTP and OpenAPI now reflect the real aggregate behavior.
- Future task and flow simulation work can build on a stable board model.

### Negative

- The board context now has a broader HTTP and test surface.
- More application code is required for command-specific orchestration.
- Some future changes, such as task migration across workflow steps, will need
  new ADRs because they can no longer be hidden behind a generic board update.
