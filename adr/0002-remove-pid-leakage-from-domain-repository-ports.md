# 0002. Remove PID Leakage From Domain Repository Ports

- Status: planned
- Date: 2026-03-27
- Supersedes: none
- Related: 0001-use-cqs-and-hexagonal-boundaries-with-in-memory-persistence

## Context

ADR 0001 established that the project should keep:

- CQS at the application boundary
- in-memory persistence during process execution
- inward dependency direction
- adapter selection at the application boundary
- readiness for future evolution toward object prevalence

After the first refactoring phase, the codebase still exposes `pid` in domain
repository ports. This keeps a runtime process detail visible in the
abstractions that should model business-facing persistence capabilities.

Today, ports such as organization, simulation, and board repository contracts
encode infrastructure-shaped signatures like:

- `get_all(pid)`
- `get_by_id(pid, id)`
- `add(pid, entity)`
- `delete(pid, id)`

This has several consequences:

- the core contract reflects the current Agent-based implementation
- use cases and tests remain aware of process-oriented calling conventions
- future prevalence-style persistence would have to preserve an incidental OTP
  shape instead of implementing a cleaner business port

The project still intends to keep live state in memory for now. Therefore, this
ADR is not about removing runtime state or replacing Agents immediately. It is
about planning a cleaner architectural boundary so the in-memory implementation
becomes a detail behind the port.

## Decision

We plan to remove `pid` and other process-runtime details from domain repository
ports and redefine those ports around business intent.

The target direction is:

1. Domain repository ports expose business-oriented operations only.
   The port signature should describe the requested action and the business
   inputs and outputs, not the runtime container used to fulfill it.

2. Runtime handles stay outside the domain contract.
   If an adapter needs process state, session state, or a runtime handle, that
   concern must be owned by the application boundary or adapter composition, not
   by the domain port definition.

3. The in-memory adapter remains valid.
   Agent-backed implementations can continue to exist, but they should satisfy a
   cleaner port through internal encapsulation instead of exposing `pid` in the
   contract itself.

4. The refactor must preserve CQS.
   Commands and queries remain explicit DTOs at the use case boundary, and the
   repository contract must not reintroduce mixed ad-hoc parameter passing.

## Considered Options

### Option A

Keep `pid` in the domain ports and accept process-oriented contracts as part of
the architectural style.

Why it was not chosen:

- couples the core abstraction to the current Agent-based implementation
- weakens the hexagonal boundary
- makes the future prevalence migration less clean

### Option B

Remove `pid` from the ports and move runtime process concerns behind adapter
composition.

Why it is preferred:

- keeps the core contract focused on persistence capability, not mechanism
- aligns the codebase more closely with Clean and Hexagonal Architecture
- preserves the ability to keep the current in-memory runtime

## Consequences

### Positive

- Repository ports become cleaner and more stable.
- The domain contract stops encoding an OTP implementation detail.
- The path toward prevalence-style persistence becomes simpler.
- Tests can be written against more meaningful contracts.

### Negative

- The refactor will touch multiple apps at once: `kanban_domain`, `usecase`,
  and `persistence`.
- Existing tests and helper setup will need coordinated adjustments.
- The project may need an intermediate application-level abstraction to carry
  runtime state cleanly.

## Execution Plan

### Phase 1: Port Redesign

- Review all current repository behaviours in `kanban_domain`.
- Define new signatures centered on business operations.
- Remove `pid` from behaviour callbacks.

Status:
- Planned.

### Phase 2: Application Boundary Adaptation

- Identify where runtime state must live in `usecase`.
- Introduce or refine the application-level composition needed to hold runtime
  handles without pushing them into domain contracts.
- Keep GenServer only as orchestration/runtime mechanism, not as a port shape.

Status:
- Planned.

### Phase 3: Adapter Migration

- Update Agent-backed adapters in `persistence` to satisfy the new ports.
- Encapsulate internal process state so callers do not see `pid` in the
  contract.
- Preserve the current in-memory behavior.

Status:
- Planned.

### Phase 4: Test And Documentation Alignment

- Update contract tests and use case tests to the new boundary.
- Align architectural documentation and examples with the new port shape.
- Validate that ADR 0001 remains respected after the change.

Status:
- Planned.

## Acceptance Criteria For Future Implementation

- No domain repository behaviour exposes `pid` in its callback signatures.
- Use case modules do not depend on Agent-shaped contracts.
- In-memory persistence still works during process execution.
- The resulting design remains compatible with a future prevalence-style
  persistence model.

## Notes

This ADR records planning only. It does not authorize or imply implementation in
the current session.
