---
name: clean-hexagonal-architecture
description: >
  Use when creating, reviewing, or refactoring code to align this repository
  with Clean Architecture, Hexagonal Architecture, and Screaming Architecture.
  Focuses on keeping the domain clean, enforcing inward dependencies, defining
  explicit ports and adapters, and making use cases the primary organizing
  structure instead of frameworks or transport concerns.
---

# Clean Hexagonal Architecture

Use this skill when the user wants to create or refactor code so the repository
stays aligned with a clean domain model, explicit use cases, and ports/adapters
boundaries.

## Primary Goal

Favor architecture that makes the business use cases obvious from the codebase.
Frameworks, HTTP, Agents, GenServers, and persistence are delivery details and
must stay at the edge.

## Core Rules

- Keep `apps/kanban_domain` framework-free and infrastructure-free.
- Put business operations in explicit use case modules under `apps/usecase`.
- Follow CQS: each use case entrypoint accepts either a Command or a Query DTO.
- Define ports at the boundary of the core; implement adapters in `apps/persistence`
  or `apps/web_api`.
- Make dependencies point inward: adapters depend on ports and use cases, never
  the reverse.
- Treat Plug, Bandit, Agent, and GenServer as mechanisms, not the architecture.
- Organizers and controllers translate input and output; they do not hold
  business rules.

## Repository Mapping

- `apps/kanban_domain`: entities, value objects, domain policies, and port
  behaviours that belong to the business core.
- `apps/usecase`: application services and orchestration for business actions,
  expressed as command and query handlers.
- `apps/persistence`: adapters that satisfy repository or gateway ports.
- `apps/web_api`: HTTP adapter that converts requests into commands or queries
  and renders responses.

## Design Checklist

When reviewing or changing code, verify these points first:

- Does the module name describe a business capability instead of a framework role?
- Can the use case run without HTTP, database, or process runtime concerns?
- Are dependencies crossing boundaries through behaviours, DTOs, or simple data?
- Is the domain free from persistence state management and transport validation?
- Is adapter code limited to translation, serialization, process wiring, or I/O?
- Would a new developer infer the product use cases before noticing the framework?

## Preferred Refactoring Direction

When existing code is not aligned, move it in this order:

1. Isolate business decisions into domain or use case modules.
2. Introduce or tighten a port behaviour at the core boundary.
3. Push HTTP, Agent, GenServer, or storage logic into an adapter.
4. Replace generic module names with use-case-oriented names.
5. Add regression tests around the use case and boundary contract.

## Smells That Usually Need Refactoring

- Domain modules calling `Agent`, `GenServer`, Plug, or persistence adapters directly.
- Controllers or routers assembling business rules inline.
- Use cases receiving raw framework params instead of a command or query DTO.
- Commands and queries mixed in the same contract or described with CQRS language
  when the implementation is still a single model with separate intent objects.
- Repositories exposing storage-specific details into the domain.
- Folder or module organization that highlights framework layers before use cases.
- Tests that require the web server or real storage just to validate business rules.

## Delivery Guidance

- Keep explanations concrete: identify the violated boundary, then propose the
  smallest change that restores the dependency direction.
- Prefer incremental refactors over large rewrites.
- Preserve structured logging and telemetry in application and adapter layers.
- When architecture tradeoffs are unclear, choose the option that keeps the
  domain more independent.

## References

If you need the rationale behind these rules, read
`references/uncle_bob_clean_hexagonal.md`.
