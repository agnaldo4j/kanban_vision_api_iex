[![Elixir CI](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml/badge.svg)](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/agnaldo4j/kanban_vision_api_iex/badge.svg?branch=main)](https://coveralls.io/github/agnaldo4j/kanban_vision_api_iex?branch=main)

# Kanban Vision API

A Kanban board simulator built with **Elixir/OTP** that uses the [Object Prevalence](https://en.wikipedia.org/wiki/Object_prevalence) pattern for in-memory state management. Designed to integrate with real data from tools like Jira, enabling flow simulation and analysis of Kanban workflows.

## Features

- **Kanban Simulation** — Model organizations, teams, and workflows to simulate how work items flow through a Kanban board
- **Object Prevalence** — In-memory state managed by OTP Agents (inspired by [Prevayler](https://prevayler.org/)), providing fast reads and atomic mutations
- **Explicit Use Cases** — Each business operation isolated in dedicated modules following Single Responsibility Principle
- **Ports & Adapters** — Domain defines behaviour contracts (ports); infrastructure implements them as adapters with contract tests
- **Command/Query Separation** — Use cases accept validated Command and Query DTOs with factory functions
- **Observability Built-In** — Structured logging with correlation IDs and Telemetry events for all operations
- **Real Data Integration** — Import project data from tools like Jira to simulate with actual workflow metrics
- **Event Sourcing Ready** — Persistence layer designed for CQRS with event logs and snapshots

## Architecture

**Screaming Architecture + Ports & Adapters + DDD** organized as an Elixir **umbrella project** with **explicit Use Cases** following **Single Responsibility Principle**.

### Data Flow

```
Adapter (HTTP/CLI)
    ↓
GenServer (Orchestrator)
    ↓
Use Case Modules ← Logger + Telemetry
    ↓
Agent (Repository) @behaviour Port
    ↓
Domain Entities (Pure)
```

**Key Principles:**
- GenServers **orchestrate** — they maintain state and route requests
- Use Cases **execute** — they contain business logic, logging, and validation
- Agents **persist** — they implement repository contracts atomically
- Domain **defines** — it specifies entities, ports, and business rules

### Apps

| App | Role | Description |
|-----|------|-------------|
| **kanban_domain** | Domain | Core entities, value objects, and Port behaviours (`domain/ports/`). Pure business logic with no infrastructure dependencies. All entities created via factory functions with UUID generation. |
| **persistence** | Adapter | Agent-based state stores implementing domain Ports via `@behaviour`. Holds the entire object graph in memory using `Agent.get_and_update` for atomic operations. |
| **usecase** | Application | Use Case modules (one per operation) orchestrated by GenServers. Each Use Case handles logging, telemetry, validation, and delegates to repository Agents. Contains the OTP Application supervisor. |

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

### Command/Query DTOs with Validation

Commands and Queries use **factory functions** with built-in validation:

```elixir
# ✅ Valid command
{:ok, cmd} = CreateOrganizationCommand.new("Acme Corp", [])
Organization.add(pid, cmd)

# ❌ Invalid command
{:error, :invalid_name} = CreateOrganizationCommand.new("", [])
```

| Use Case | Commands | Queries |
|----------|----------|---------|
| Organization | `CreateOrganizationCommand`, `DeleteOrganizationCommand` | `GetOrganizationByIdQuery`, `GetOrganizationByNameQuery` |
| Simulation | `CreateSimulationCommand` | `GetSimulationByOrgAndNameQuery` |

### Use Cases (One per Operation)

Each business operation has a dedicated Use Case module with **logging**, **telemetry**, and **error handling**:

```elixir
# Use Case structure
defmodule Organizations.CreateOrganization do
  def execute(cmd, repository_pid, opts \\ []) do
    Logger.info("Creating organization", ...)  # 📊 Observability
    organization = Organization.new(cmd.name)

    case OrganizationRepository.add(repository_pid, organization) do
      {:ok, org} ->
        emit_telemetry_event(...)               # 📈 Metrics
        {:ok, org}
      {:error, reason} ->
        Logger.error("Failed", ...)
        {:error, reason}
    end
  end
end
```

**Available Use Cases:**
- `Organizations.CreateOrganization`
- `Organizations.DeleteOrganization`
- `Organizations.GetOrganizationById`
- `Organizations.GetOrganizationByName`
- `Organizations.GetAllOrganizations`
- `Simulations.CreateSimulation`
- `Simulations.GetAllSimulations`
- `Simulations.GetSimulationByOrgAndName`

### Project Structure

```
apps/
  kanban_domain/
    lib/kanban_vision_api/domain/
      ports/                        # Behaviour contracts (interfaces)
        organization_repository.ex  # @callback definitions
        simulation_repository.ex
        board_repository.ex
      organization.ex               # Domain entities (pure)
      simulation.ex
      board.ex
      audit.ex                      # Value objects
      ...
  persistence/
    lib/kanban_vision_api/agent/
      organizations.ex              # @behaviour OrganizationRepository
      simulations.ex                # @behaviour SimulationRepository
      boards.ex                     # @behaviour BoardRepository
    test/
      agent/
        organization_repository_contract_test.exs  # ✅ Contract tests
        simulation_repository_contract_test.exs
  usecase/
    lib/kanban_vision_api/usecase/
      organization.ex               # GenServer (orchestrator only)
      organization/
        commands.ex                 # DTOs with validation
        queries.ex
      organizations/                # ⭐ Use Case modules
        create_organization.ex      # One Use Case = One file
        delete_organization.ex
        get_organization_by_id.ex
        get_organization_by_name.ex
        get_all_organizations.ex
      simulation.ex                 # GenServer (orchestrator only)
      simulation/
        commands.ex
        queries.ex
      simulations/                  # ⭐ Use Case modules
        create_simulation.ex
        get_all_simulations.ex
        get_simulation_by_org_and_name.ex
      application.ex                # OTP Supervisor
```

## Key Design Decisions

### **1. Explicit Use Cases (SRP)**
- ✅ **One Use Case = One Operation** — each file has a single responsibility
- ✅ **No God Objects** — GenServers orchestrate, Use Cases execute
- ✅ **Testable in Isolation** — Use Cases are pure functions (except I/O)

### **2. Observability First**
- 📊 **Structured Logging** — all operations log with `correlation_id`, entity IDs, and timestamps
- 📈 **Telemetry Events** — business events emitted for metrics (`organization_created`, etc.)
- 🔍 **Traceable Flows** — correlation IDs propagate through the call chain

### **3. Validation at the Edge**
- ✅ **Factory Functions** — Commands/Queries validate before construction
- ✅ **Type Safety** — `@enforce_keys` ensures required fields
- ✅ **Early Failure** — invalid input rejected before domain logic executes

### **4. Repository Pattern (Ports & Adapters)**
- 🔌 **Agents use pid-based access** (no atom name registration) to avoid atom table exhaustion
- 🔌 **Agent mutations use `Agent.get_and_update`** (not separate get + update) to prevent race conditions
- 🔌 **Agents implement @behaviour Ports** — easy to swap implementations (e.g., Postgres adapter)

### **5. Domain Purity**
- 🧼 **Zero Infrastructure Coupling** — domain never imports Agent, GenServer, or HTTP
- 🧼 **Factory Functions with UUIDs** — all entities created via `Module.new/N` with auto-generated IDs
- 🧼 **Audit Timestamps** — consistent `created`/`updated` tracking across all entities

### **6. Contract Testing**
- ✅ **Integration tests verify Port compliance** — ensures Agents implement contracts correctly
- ✅ **No surprises in production** — if contract tests pass, Ports work as expected

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
| `:integration` | Contract tests (Port compliance verification) |

### Test Structure

```
persistence/test/
  agent/
    organizations_test.exs                        # Unit tests
    organization_repository_contract_test.exs     # ✅ Contract tests (@integration)
    simulations_test.exs
    simulation_repository_contract_test.exs       # ✅ Contract tests (@integration)

usecase/test/
  usecase/
    organization_test.exs                         # Integration tests (GenServer + Agent)
    simulation_test.exs
```

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

## Architecture Evolution

This project recently underwent a major architectural refactoring to align with **Platform Engineering Standards** and **Clean Architecture principles**:

### ✅ What Changed

1. **Use Cases Made Explicit** — Replaced God Object GenServers with dedicated Use Case modules (one per operation)
2. **Observability Added** — Every Use Case now has structured logging (Logger) and telemetry events
3. **Validation at Entry Points** — Commands/Queries use factory functions that validate before construction
4. **Contract Tests** — Added integration tests verifying Agents correctly implement Port behaviours
5. **Single Responsibility** — GenServers now only orchestrate; business logic moved to Use Cases

### 📊 Impact

| Metric | Before | After |
|--------|--------|-------|
| Use Case modules | 0 (logic in GenServers) | 8 dedicated modules |
| Observability | None | Logger + Telemetry in all operations |
| Input validation | Runtime errors | Compile-time + factory validation |
| Contract tests | 0 | 2 (OrganizationRepository, SimulationRepository) |
| SRP compliance | ❌ God Objects | ✅ Single responsibility per module |

### 🎯 Benefits

- **Maintainability** — easier to understand, test, and modify individual operations
- **Observability** — production-ready logging and metrics out of the box
- **Reliability** — validation catches errors early; contract tests prevent regressions
- **Testability** — Use Cases are pure functions (except I/O), easy to unit test

See [CLAUDE.md](CLAUDE.md) for the complete architectural standards and patterns followed.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all tests pass (`mix test`)
4. Run the linter (`mix credo`)
5. Check formatting (`mix format --check-formatted`)
6. Read [CLAUDE.md](CLAUDE.md) for architectural patterns and the Definition of Done skill (`.claude/skills/definition-of-done/SKILL.md`) before completing features
7. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE).
