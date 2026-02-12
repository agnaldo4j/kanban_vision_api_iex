[![Elixir CI](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml/badge.svg)](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/agnaldo4j/kanban_vision_api_iex/badge.svg?branch=main)](https://coveralls.io/github/agnaldo4j/kanban_vision_api_iex?branch=main)

# Kanban Vision API

A Kanban board simulator built with **Elixir/OTP** that uses the [Object Prevalence](https://en.wikipedia.org/wiki/Object_prevalence) pattern for in-memory state management. Designed to integrate with real data from tools like Jira, enabling flow simulation and analysis of Kanban workflows.

## Features

- **Kanban Simulation** — Model organizations, teams, and workflows to simulate how work items flow through a Kanban board
- **Object Prevalence** — In-memory state managed by OTP Agents (inspired by [Prevayler](https://prevayler.org/)), providing fast reads and atomic mutations
- **Ports & Adapters** — Domain defines behaviour contracts (ports); infrastructure implements them as adapters
- **Command/Query Separation** — Use cases accept explicit Command and Query DTOs, keeping the public API clean and decoupled from domain internals
- **Real Data Integration** — Import project data from tools like Jira to simulate with actual workflow metrics
- **Event Sourcing Ready** — Persistence layer designed for CQRS with event logs and snapshots

## Architecture

**Screaming Architecture + Ports & Adapters + DDD** organized as an Elixir **umbrella project**.

### Data Flow

```
Adapter (HTTP/CLI) → UseCase GenServer → Agent (Persistence) → In-Memory Map
                          │                     │
                     Commands/Queries      @behaviour Port
                          │                     │
                     Domain Entities      domain/ports/
```

### Apps

| App | Role | Description |
|-----|------|-------------|
| **kanban_domain** | Domain | Core entities, value objects, and Port behaviours (`domain/ports/`). Pure business logic with no infrastructure dependencies. |
| **persistence** | Adapter | Agent-based state stores implementing domain Ports. Holds the entire object graph in memory using `Agent.get_and_update` for atomic operations. |
| **usecase** | Application | GenServer-based orchestration layer. Accepts Command/Query DTOs, creates domain entities, and delegates to persistence Agents. Contains the OTP Application supervisor. |

### Domain Model

```
Organization
  └── Tribe
        └── Squad
              └── Worker
                    └── Ability

Simulation (linked to Organization)
  ├── Board
  │     └── Workflow
  │           └── Step (requires Ability)
  │                 └── Task (has ServiceClass)
  └── Project
        └── Task
```

All domain entities are created via `Module.new(...)` factory functions that auto-generate UUIDs and Audit timestamps.

### Ports & Adapters

The domain defines behaviour contracts that the persistence layer implements:

| Port (Domain) | Adapter (Persistence) |
|----------------|----------------------|
| `Domain.Ports.OrganizationRepository` | `Agent.Organizations` |
| `Domain.Ports.SimulationRepository` | `Agent.Simulations` |
| `Domain.Ports.BoardRepository` | `Agent.Boards` |

### Command/Query DTOs

Use cases accept explicit DTOs instead of raw domain structs:

| Use Case | Commands | Queries |
|----------|----------|---------|
| Organization | `CreateOrganizationCommand`, `DeleteOrganizationCommand` | `GetOrganizationByIdQuery`, `GetOrganizationByNameQuery` |
| Simulation | `CreateSimulationCommand` | `GetSimulationByOrgAndNameQuery` |

### Project Structure

```
apps/
  kanban_domain/
    lib/kanban_vision_api/domain/
      ports/                        # Behaviour contracts (interfaces)
        organization_repository.ex
        simulation_repository.ex
        board_repository.ex
      organization.ex               # Domain entities
      simulation.ex
      board.ex
      ...
  persistence/
    lib/kanban_vision_api/agent/
      organizations.ex              # @behaviour OrganizationRepository
      simulations.ex                # @behaviour SimulationRepository
      boards.ex                     # @behaviour BoardRepository
  usecase/
    lib/kanban_vision_api/usecase/
      organization.ex               # GenServer use case
      organization/
        commands.ex                 # CreateOrganizationCommand, DeleteOrganizationCommand
        queries.ex                  # GetOrganizationByIdQuery, GetOrganizationByNameQuery
      simulation.ex                 # GenServer use case
      simulation/
        commands.ex                 # CreateSimulationCommand
        queries.ex                  # GetSimulationByOrgAndNameQuery
      application.ex                # OTP Supervisor
```

## Key Design Decisions

- **Agents use pid-based access** (no atom name registration) to avoid atom table exhaustion
- **Agent mutations use `Agent.get_and_update`** (not separate get + update) to prevent race conditions
- **GenServers delegate to Agents** — no duplicated business logic between layers
- **Use cases create domain entities internally** — callers only provide Commands/Queries, never raw structs
- **All domain entities have UUID ids and Audit timestamps** — consistent identity and traceability

## Prerequisites

- **Elixir** >= 1.18 with **OTP** >= 28

## Getting Started

```bash
# Clone the repository
git clone https://github.com/agnaldo4j/kanban_vision_api_iex.git
cd kanban_vision_api_iex

# Install dependencies
mix deps.get

# Compile
mix compile

# Start the application
mix run --no-halt
```

## Testing

```bash
# Run all tests
mix test

# Run tests for a specific app
mix test --app persistence
mix test --app usecase

# Run a single test file
mix test apps/persistence/test/kanban_vision_api/agent/organizations_test.exs

# Run tests by tag
mix test --only domain_boards
mix test --only domain_organizations
mix test --only integration

# Watch mode (re-runs on file changes)
mix test.watch

# Coverage report
MIX_ENV=test mix coveralls --umbrella
```

### Test Tags

| Tag | Scope |
|-----|-------|
| `:domain_organizations` | Organization agent tests |
| `:domain_boards` | Board agent tests |
| `:domain_smulations` | Simulation agent tests |
| `:integration` | Integration tests (excluded by default) |

## Code Quality

```bash
# Static analysis
mix credo

# Code formatting
mix format

# Check formatting (CI)
mix format --check-formatted

# Compile with warnings as errors
mix compile --warnings-as-errors
```

### Coverage Thresholds

| App | Minimum |
|-----|---------|
| kanban_domain | 61% |
| persistence | 100% |
| usecase | 12% |

## CI

GitHub Actions runs on every push and PR to `main`:

**Elixir 1.18.4** | **OTP 28** | **Ubuntu**

Pipeline: `mix deps.get` -> `mix credo` -> `mix coveralls` -> `mix test --cover`

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all tests pass (`mix test`)
4. Run the linter (`mix credo`)
5. Check formatting (`mix format --check-formatted`)
6. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE).
