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
mix test apps/kanban_domain/test/kanban_vision_api/agent/organizations_test.exs

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
- kanban_domain: 61%
- persistence: 100%
- usecase: 12%

## CI

GitHub Actions (`.github/workflows/elixir.yml`): Elixir 1.18.4, OTP 28. Runs `mix credo` → `mix coveralls` → `mix test --cover`.
