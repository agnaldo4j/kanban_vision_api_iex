# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Install dependencies
mix deps.get

# Run all tests
mix test

# Run tests for a single app
mix test --app kanban_domain

# Run a single test file
mix test apps/persistence/test/kanban_vision_api/agent/organizations_test.exs

# Run tests by tag
mix test --only domain_boards
mix test --only integration          # integration tests excluded by default

# Watch mode
mix test.watch

# Coverage (CI uses this)
MIX_ENV=test mix coveralls.github --umbrella

# Linting
mix credo

# Format
mix format
```

## Architecture

Elixir **umbrella project** implementing a Kanban board simulator using OTP and the **Object Prevalence** pattern (in-memory state via Agents, inspired by Prevayler).

### Apps

- **kanban_domain** — Core domain structs and Agent-based state stores. The Agents (Organizations, Simulations, Boards) hold the entire object graph in memory using `Agent.get_and_update` for atomic operations. Domain structs all have UUID `id` fields and `Audit` timestamps.
- **usecase** — GenServer-based application layer that orchestrates domain operations. Contains the OTP Application supervisor (`KanbanVisionApi.Usecase.Application`).
- **persistence** — Placeholder for event sourcing / CQRS persistence (event logs + snapshots).

### Data Flow

```
Client → GenServer (Usecase) → Agent (kanban_domain) → In-Memory Map
```

### Domain Model Hierarchy

Organization → Tribe → Squad → Worker (with Abilities)
Simulation → Board → Workflow → Step → Task (with ServiceClass)

## Key Conventions

- Agents use **pid-based access** (no atom name registration) to avoid atom table exhaustion.
- Agent mutations use `Agent.get_and_update` (not separate get + update) to prevent race conditions.
- GenServers use `use GenServer` (not `@behaviour GenServer`) to get default callback implementations.
- All domain entities are created via `Module.new(...)` factory functions that generate UUIDs.

## Coverage Thresholds

Per-app minimums enforced in each `coveralls.json`:
- kanban_domain: 70%
- persistence: 100%
- usecase: 50%

## CI

GitHub Actions (`.github/workflows/elixir.yml`): Elixir 1.18.4, OTP 28. Runs `mix credo` → `mix coveralls` → `mix test --cover`.

# Platform Engineering Standards

This file defines the engineering quality agreements for this project.
Claude (and any AI agent) must follow these standards when generating,
reviewing, or refactoring code in this repository.

---

## Project Architecture Style

This project follows **Screaming Architecture + Ports & Adapters + DDD**
organized as a **Modular Monolith** (with optional microservice extraction).

The folder/module structure must reveal **what the system does** (business
capabilities), not what framework or stack it uses.

---

## Non-Negotiable Rules

### 1. Use Cases are the entry point to the domain
- Every business flow must live in an explicit **Use Case** class/function.
- Use Cases receive a **Command** (write) or **Query** (read) — never both.
- Use Cases must NOT import framework classes, HTTP types, or database ORMs directly.
- Use Cases depend only on **domain interfaces (ports)**.

### 2. Adapters translate — they don't decide
- Controllers, consumers, jobs, and CLI handlers are **adapters**.
- Adapters translate external input (HTTP request, message, CLI args) into domain types and call a Use Case.
- Business logic must never live in an adapter.

### 3. Ports are interfaces — infrastructure implements them
- Repositories, external service clients, email senders, and messaging are **output adapters**.
- The domain defines the interface (port). Infrastructure implements it.
- The domain must be fully testable with mocks/stubs — no real database, no web server, no framework.

### 4. Modules are bounded contexts
- Each module has its own public interface. Other modules must not access internals directly.
- Cross-module communication happens via well-defined public APIs (function calls, events, or use case calls).
- Follow **Ubiquitous Language**: class and method names must match the business domain vocabulary — not generic CRUD labels.

### 5. Every class/function follows SOLID + KISS
- **S**: One class, one reason to change.
- **O**: Extend behavior without modifying existing code.
- **L**: Subtypes are fully substitutable for their base types.
- **I**: Interfaces are focused — no client depends on methods it doesn't use.
- **D**: Depend on abstractions (interfaces/ports), not on concrete implementations.
- **KISS**: If a new developer can't understand it in a few minutes, simplify it.

### 6. Functional style inside domain logic
- Domain functions must be **pure** when possible: same input → same output, no hidden side effects.
- Prefer **immutability**: return new objects/structures instead of mutating existing ones.
- Avoid shared or global mutable state inside domain logic.

### 7. Refactor continuously — don't accumulate debt
- Before adding new features, clean up code smells in the affected area.
- Never commit long methods, deeply nested conditionals, or duplicated logic.
- Refactoring must not change external behavior — write/run tests first.

---

## Folder Structure Convention

Structure folders to scream the business domain:

```
src/
  modules/
    orders/           # Bounded context: Orders
      use-cases/      # CreateOrder, CancelOrder, ...
      domain/         # Entities, value objects, domain events
      ports/          # Repository interfaces, service interfaces
      adapters/       # HTTP controllers, DB repositories, external clients
    payments/         # Bounded context: Payments
    users/            # Bounded context: Users
  chassis/            # Cross-cutting: logging, tracing, config, auth, health
  shared/             # Shared value objects, base types, utilities
```

**Do not** structure by technical layer first (controllers/, services/, repositories/).

---

## Naming Conventions

| Concept | Naming example |
|---------|---------------|
| Use Case (command) | `CreateOrderUseCase`, `ConfirmPaymentUseCase` |
| Use Case (query) | `GetOrderByIdUseCase`, `ListActiveOrdersUseCase` |
| Command DTO | `CreateOrderCommand`, `ConfirmPaymentCommand` |
| Query DTO | `GetOrderByIdQuery`, `ListActiveOrdersQuery` |
| Repository port | `OrderRepository` (interface in domain) |
| Repository adapter | `PostgresOrderRepository` (implements port) |
| Domain entity | `Order`, `Payment`, `Customer` |
| Domain event | `OrderCreated`, `PaymentConfirmed` |

---

## Continuous Integration Rules

Every code change must be integration-ready. The team deploys at least once every two days,
even with partially complete features. **Deployment ≠ Release** — use the patterns below
to ship safely without exposing incomplete work to users.

### Delivery patterns (use when a feature is not fully complete)
- **Feature Flags/Toggles**: Hide incomplete features behind a flag. Default off in production.
- **Dark Launch**: Code deployed but completely inaccessible to users. Used for internal testing and validation in production environment.
- **Branch by Abstraction**: Evolve complexity in phases via CI, delivering value incrementally while the feature is being built.

### Branch rules
- Every development branch must be based on `main`.
- Branches must be short-lived. Long-running branches are a risk signal.
- Never merge directly into main without CI passing.

---

## Tests — Non-Negotiable

Tests are part of design, not an optional step. Every new or changed code must include tests.

### Unit tests
- Fast, deterministic, isolated.
- Follow **given–when–then** structure.
- Cover both happy paths and error/edge cases.
- Must run without database, network, or filesystem.

### Integration tests
- Required whenever there is a boundary: database, external API, queue, or inter-module contract.
- Must validate: contracts, schemas, mappings, queries, and messages.
- Keep OpenAPI / AsyncAPI / CDC specs updated alongside the tests.

### Rule
Coverage is a consequence, not a goal. Aim for quality of relevant cases and observable behavior,
not for hitting a percentage number.

---

## Versioning and Backward Compatibility

Every change starts from the contract. Breaking changes are a deployment risk and a trust issue.

- Use explicit versioning (`v1`, `v2` in path or header).
- **Additive changes** (new fields, new endpoints) stay in the same version.
- **Breaking changes** only in major versions with a migration path provided.
- Every change ships with updated OpenAPI docs and a clear changelog entry.
- Never remove or change the meaning of existing fields in active versions.
- Deprecated fields must be marked, maintained for an agreed period, and offer a migration path.

---

## Observability — "Done" requires telemetry

A feature is not done without observable behavior in production. When generating code that
touches business flows, always include or ask about:

- **Metrics**: error rates, response times, business event counts.
- **Logs**: structured, with correlation ID, service name, log level. Never log PII.
- **Traces**: distributed tracing headers propagated across service boundaries.
- **Business events**: instrument hypotheses, adoption, conversion, retention, revenue/cost impact.
- **Alerts**: high signal, low noise — triggered by user impact or SLO risk, pointing to a runbook.

If a new Use Case or adapter has no instrumentation, flag it explicitly before calling it done.

---

## What AI must NOT do when generating code for this project

- Do not put business logic in controllers, resolvers, or HTTP handlers.
- Do not import ORM entities or database types inside Use Cases or domain classes.
- Do not create a single "service" class that handles every operation for a domain (violates SRP + KISS).
- Do not name classes with generic suffixes like `Manager`, `Helper`, `Handler` — name them after what they do.
- Do not create deeply nested conditionals — extract to methods or use polymorphism.
- Do not mutate input parameters or shared state in domain functions.
- Do not skip writing/suggesting tests for Use Cases and domain logic.
- Do not generate code without at least mentioning where instrumentation (logs, metrics, traces) should be added.
- Do not hardcode secrets, credentials, or environment-specific URLs — use environment variables.
- Do not remove or rename existing public API fields without flagging it as a breaking change.

---

## Microservices Chassis (when applicable)

When creating a new service or microservice, include from the start:

- [ ] Structured logging (correlation ID, service name, log level)
- [ ] Health check endpoint
- [ ] Distributed tracing headers (propagation)
- [ ] External configuration (env vars / config service — never hardcoded)
- [ ] Circuit breaker for external dependencies
- [ ] Graceful shutdown handling

---

## Skills — Read before acting

Before completing a task, read the relevant skill:

| Task                                              | Skill                               |
|---------------------------------------------------|-------------------------------------|
| Finishing any feature, bug fix, or tech debt item | `docs/skills/definition-of-done.md` |
| How to use Flow in a performatic way              | `docs/skills/FLOW.md`               |
| How to use GenStage in a performatic way          | `docs/skills/GenStage.md`           |
| How to use Elixir in a performatic way            | `docs/skills/Elixir.md`             |

**The Definition of Done skill is mandatory before declaring any task complete.**

---

## References

- Clean Architecture — Robert C. Martin
- Domain-Driven Design — Eric Evans
- Screaming Architecture — https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html
- Clean Coders Component Design — https://cleancoders.com/series/clean-code/component-design
- SOLID Principles — https://cleancoders.com/series/clean-code/solid-principles