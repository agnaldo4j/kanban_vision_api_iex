# 0003. Adopt Structured Application Errors Across Persistence, Usecase, and HTTP

- Status: accepted
- Date: 2026-03-27
- Supersedes: none
- Related:
  - 0001-use-cqs-and-hexagonal-boundaries-with-in-memory-persistence
  - 0002-remove-pid-leakage-from-domain-repository-ports

## Context

ADR 0001 established that the project should keep:

- CQS at the application boundary
- inward dependency direction
- in-memory persistence during process execution
- use-case-first orchestration with HTTP adapters limited to translation

ADR 0002 removed raw `pid` leakage from domain repository ports and pushed
runtime process details behind opaque repository runtimes. That improved the
boundary between domain, usecase, and persistence, but one important coupling
still remains: failures are still propagated as free-form strings and interpreted
differently by outer layers.

Today, the codebase still contains these patterns:

- `persistence` adapters return string errors such as `"not found"` and
  `"already exist"`
- `usecase` modules propagate those strings upward as application failures
- `web_api` controllers determine HTTP status codes by parsing message text with
  `String.contains?/2`

This keeps the transport layer coupled to incidental wording from persistence
adapters. As a result:

- HTTP behavior depends on text phrasing instead of semantic categories
- changing an error message can unintentionally change API behavior
- tests remain brittle because they assert wording instead of intent
- future persistence evolution, including prevalence-oriented persistence, would
  still be forced to preserve incidental message conventions

The project does not plan to adopt CQRS at this stage. This ADR remains aligned
with CQS and does not change the in-memory runtime model. The decision is only
about replacing string-based failure contracts with structured application
errors.

## Decision

We will adopt structured application errors across `persistence`, `usecase`, and
`web_api`.

The canonical application-facing failure shape will be:

- `{:error, %{code: atom(), message: String.t(), details: map()}}`

The intent of each field is:

- `code`: stable semantic category used by application and transport logic
- `message`: human-readable description
- `details`: optional contextual data for debugging, logging, or downstream
  handling

The following canonical error codes are adopted initially:

- `:invalid_input`
- `:not_found`
- `:conflict`
- `:internal_error`

HTTP adapters must map status codes from `code`, never from `message`.

The initial HTTP status mapping will be:

- `:invalid_input -> 422`
- `:not_found -> 404`
- `:conflict -> 409`
- `:internal_error -> 500`

Validation failures produced at command/query construction time may continue to
originate as explicit atoms during the transition, but before an error crosses
the HTTP boundary it must be normalized to the structured application error
contract.

Persistence adapters may still generate descriptive messages, but those messages
must travel together with explicit error codes rather than acting as the only
contract.

This ADR does not change the current public JSON error body shape. For now, HTTP
responses may continue to render:

- `%{error: message}`

This ADR also does not introduce:

- exception-based control flow
- internationalization of errors
- public API versioning changes
- a global error catalog beyond the initial canonical codes

## Considered Options

### Option A

Keep propagating string errors and continue mapping HTTP status by parsing error
messages.

Why it was not chosen:

- couples transport behavior to persistence wording
- keeps the boundary fragile and hard to evolve
- makes tests brittle and semantically weak

### Option B

Adopt structured application errors and map HTTP behavior from explicit error
codes.

Why it is preferred:

- creates a stable boundary across adapters and use cases
- keeps HTTP translation independent of wording changes
- aligns with the intended hexagonal architecture
- makes future persistence changes safer

## Consequences

### Positive

- HTTP adapters become deterministic and independent of error message wording.
- Persistence and use case layers gain a stable failure contract.
- Tests can assert semantic categories instead of brittle text fragments.
- Future persistence evolution remains compatible with the current architecture.
- Logging and telemetry can use structured failure categories directly.

### Negative

- The refactor will touch `persistence`, `usecase`, `web_api`, and tests.
- Transitional coexistence with legacy validation atoms must be managed.
- Existing tests and documentation that assume string-based failures will need
  updates.

## Execution Plan

### Phase 1: Error Contract Definition

- Introduce a shared application error contract and canonical error categories.
- Define normalization rules for validation atoms and structured adapter errors.
- Document the HTTP mapping rules from error code to response status.

Status:
- Completed.

### Phase 2: Persistence And Usecase Adoption

- Update Agent adapters to return structured errors instead of raw string-only
  tuples.
- Update use cases to propagate structured errors as the application contract.
- Preserve structured logging while including `code` and relevant `details`.

Status:
- Completed.

### Phase 3: HTTP Mapping Refactor

- Replace `String.contains?/2`-based error mapping in controllers with explicit
  `code` mapping.
- Keep response body shape as `%{error: message}` unless a later ADR changes the
  public error payload.

Status:
- Completed.

### Phase 4: Test And Contract Alignment

- Update persistence contract tests to assert semantic error codes.
- Update use case tests to assert structured error propagation.
- Update controller tests to assert status mapping by category instead of
  message parsing.
- Remove brittle assertions that rely on incidental wording when wording is not
  the contract.

Status:
- Completed.

## Acceptance Criteria For Future Implementation

- No controller uses `String.contains?/2` or equivalent message parsing to map
  HTTP status.
- Persistence adapters return structured errors for conflict and missing-resource
  scenarios.
- Use cases propagate structured application errors consistently.
- HTTP adapters map `:invalid_input`, `:not_found`, `:conflict`, and
  `:internal_error` deterministically.
- The current public JSON error body shape remains backward compatible unless a
  later ADR changes it.

## Notes

This ADR records the next architectural refactoring phase after ADR 0002. It
preserves the current CQS model and in-memory runtime while strengthening the
failure contract across architectural boundaries.
