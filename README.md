[![Elixir CI](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml/badge.svg)](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/agnaldo4j/kanban_vision_api_iex/badge.svg?branch=main)](https://coveralls.io/github/agnaldo4j/kanban_vision_api_iex?branch=main)
![Elixir](https://img.shields.io/badge/Elixir-1.18-4B275F)
![OTP](https://img.shields.io/badge/OTP-28-8A2BE2)

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
HTTP Client
    ↓
web_api (Plug Router + Controllers)
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
| **web_api** | HTTP Adapter | REST API built with Plug + Bandit. Controllers translate HTTP requests into Commands/Queries and call use case ports. Includes OpenAPI 3.0 spec and Swagger UI. |

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
  def execute(cmd, repository_runtime, opts \\ []) do
    Logger.info("Creating organization", ...)  # 📊 Observability
    organization = Organization.new(cmd.name)

    case OrganizationRepository.add(repository_runtime, organization) do
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
        organization_repository.ex
        simulation_repository.ex
        board_repository.ex
      organization.ex               # Domain entities (pure)
      simulation.ex
      board.ex
      audit.ex                      # Value objects
  persistence/
    lib/kanban_vision_api/agent/
      organizations.ex              # @behaviour OrganizationRepository
      simulations.ex                # @behaviour SimulationRepository
      boards.ex                     # @behaviour BoardRepository
    test/agent/
      organization_repository_contract_test.exs  # ✅ @moduletag :integration
      simulation_repository_contract_test.exs
  usecase/
    lib/kanban_vision_api/usecase/
      organization.ex               # GenServer (orchestrator only)
      organization/
        commands.ex                 # DTOs with validation
        queries.ex
      organizations/                # ⭐ Use Case modules (one per operation)
        create_organization.ex
        delete_organization.ex
        get_organization_by_id.ex
        get_organization_by_name.ex
        get_all_organizations.ex
      simulation.ex
      simulation/
        commands.ex
        queries.ex
      simulations/
        create_simulation.ex
        get_all_simulations.ex
        get_simulation_by_org_and_name.ex
      application.ex                # OTP Supervisor
  web_api/
    lib/kanban_vision_api/web_api/
      application.ex                # Starts Bandit (disabled in test env)
      router.ex                     # Plug.Router — all routes
      plugs/
        correlation_id.ex           # X-Correlation-ID header
        request_logger.ex           # Structured request/response logging
      ports/
        organization_usecase.ex     # @behaviour — HTTP port for org use cases
        simulation_usecase.ex       # @behaviour — HTTP port for sim use cases
      adapters/
        organization_adapter.ex     # Delegates to Usecase.Organization GenServer
        simulation_adapter.ex       # Delegates to Usecase.Simulation GenServer
      organizations/
        organization_controller.ex  # HTTP adapter → org use cases
        organization_serializer.ex  # Domain.Organization → JSON map (recursive)
      simulations/
        simulation_controller.ex    # HTTP adapter → sim use cases
        simulation_serializer.ex    # Domain.Simulation → JSON map
      open_api/
        spec.ex                     # OpenAPI 3.0 spec
        schemas/                    # OrganizationSchema, SimulationSchema, ErrorSchema
    test/
      integration/                  # ✅ @moduletag :integration
        organizations_integration_test.exs
        simulations_integration_test.exs
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
- 🔌 **Agents stay internal to persistence adapters** through opaque runtimes (still no atom name registration)
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

# Start the application (HTTP server on port 4000)
mix run --no-halt
```

The API will be available at `http://localhost:4000`. OpenAPI docs at `http://localhost:4000/api/openapi` and Swagger UI at `http://localhost:4000/api/swagger`.

## HTTP API

Base path: `/api/v1`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/organizations` | List all organizations |
| POST | `/api/v1/organizations` | Create organization (`{"name": "..."}`) |
| GET | `/api/v1/organizations/:id` | Get by ID |
| GET | `/api/v1/organizations/search?name=X` | Search by name |
| DELETE | `/api/v1/organizations/:id` | Delete organization |
| GET | `/api/v1/simulations` | List all simulations |
| POST | `/api/v1/simulations` | Create simulation (`{"name": "...", "description": "...", "organization_id": "..."}`) |
| GET | `/api/v1/simulations/search?org_id=X&name=Y` | Search by org and name |
| DELETE | `/api/v1/simulations/:id` | Delete simulation |
| GET | `/api/openapi` | OpenAPI 3.0 JSON spec |
| GET | `/api/swagger` | Swagger UI |

All responses include an `X-Correlation-ID` header for distributed tracing.

## Testing

```bash
# Run all tests
mix test

# Run tests for a specific app
mix test apps/kanban_domain/test
mix test apps/persistence/test
mix test apps/usecase/test
mix test apps/web_api/test

# Run a single test file
mix test apps/persistence/test/kanban_vision_api/agent/organizations_test.exs

# Run tests by tag
mix test --only domain_boards
mix test --only domain_organizations
mix test --only integration          # contract + HTTP integration tests

# Watch mode (re-runs on file changes)
mix test.watch

# Coverage report (run from umbrella root)
MIX_ENV=test mix coveralls --umbrella
```

### Test Tags

| Tag | Scope |
|-----|-------|
| `:domain_organizations` | Organization agent tests |
| `:domain_boards` | Board agent tests |
| `:domain_simulations` | Simulation agent tests |
| `:integration` | Contract tests (persistence) + HTTP integration tests (web_api) |

### Test Structure

```
persistence/test/agent/
  organizations_test.exs                        # Unit tests
  organization_repository_contract_test.exs     # ✅ Contract tests (@moduletag :integration)
  simulations_test.exs
  simulation_repository_contract_test.exs       # ✅ Contract tests (@moduletag :integration)

usecase/test/usecase/
  organization_test.exs                         # GenServer + Agent integration
  simulation_test.exs

web_api/test/
  organizations/
    organization_controller_test.exs            # Unit tests (Mox)
    organization_serializer_test.exs
  simulations/
    simulation_controller_test.exs              # Unit tests (Mox)
    simulation_serializer_test.exs
  integration/
    organizations_integration_test.exs          # ✅ HTTP integration (@moduletag :integration)
    simulations_integration_test.exs
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
| kanban_domain | 70% |
| persistence | 100% |
| usecase | 50% |
| web_api | 80% |

## CI

GitHub Actions runs on every push and PR to `main`:

**Elixir 1.18.4** | **OTP 28** | **Ubuntu**

Pipeline: `mix deps.get` → `mix credo` → `mix dialyzer` → `mix coveralls` → `mix test --cover`

## Architecture Evolution

This project recently underwent a major architectural refactoring to align with **Platform Engineering Standards** and **Clean Architecture principles**:

### ✅ What Changed

1. **Use Cases Made Explicit** — Replaced God Object GenServers with dedicated Use Case modules (one per operation)
2. **Observability Added** — Every Use Case now has structured logging (Logger) and telemetry events
3. **Validation at Entry Points** — Commands/Queries use factory functions that validate before construction
4. **Contract Tests** — Added integration tests verifying Agents correctly implement Port behaviours
5. **Single Responsibility** — GenServers now only orchestrate; business logic moved to Use Cases
6. **REST HTTP Layer** — `web_api` app exposes use cases as a versioned JSON API (Plug + Bandit) with OpenAPI 3.0 docs and Swagger UI

### 📊 Impact

| Metric | Before | After |
|--------|--------|-------|
| Use Case modules | 0 (logic in GenServers) | 8 dedicated modules |
| Observability | None | Logger + Telemetry in all operations |
| Input validation | Runtime errors | Compile-time + factory validation |
| Contract tests | 0 | 5 (3 repository + 2 HTTP integration) |
| SRP compliance | ❌ God Objects | ✅ Single responsibility per module |
| HTTP API | None | REST API with OpenAPI 3.0 + Swagger UI |

### 🎯 Benefits

- **Maintainability** — easier to understand, test, and modify individual operations
- **Observability** — production-ready logging and metrics out of the box
- **Reliability** — validation catches errors early; contract tests prevent regressions
- **Testability** — Use Cases are pure functions (except I/O), easy to unit test

See [AGENTS.md](AGENTS.md) for the current Codex-oriented architectural standards, workflow rules, and project conventions.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all tests pass (`mix test`)
4. Run the linter (`mix credo`)
5. Check formatting (`mix format --check-formatted`)
6. Read [AGENTS.md](AGENTS.md) and the project Codex skills under `.codex/skills/` before completing features
7. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE).
