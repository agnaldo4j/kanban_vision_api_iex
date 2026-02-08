[![Elixir CI](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml/badge.svg)](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/agnaldo4j/kanban_vision_api_iex/badge.svg?branch=main)](https://coveralls.io/github/agnaldo4j/kanban_vision_api_iex?branch=main)

# Kanban Vision API

A Kanban board simulator built with **Elixir/OTP** that uses the [Object Prevalence](https://en.wikipedia.org/wiki/Object_prevalence) pattern for in-memory state management. Designed to integrate with real data from tools like Jira, enabling flow simulation and analysis of Kanban workflows.

## Features

- **Kanban Simulation** — Model organizations, teams, and workflows to simulate how work items flow through a Kanban board
- **Object Prevalence** — In-memory state managed by OTP Agents (inspired by [Prevayler](https://prevayler.org/)), providing fast reads and atomic mutations
- **Real Data Integration** — Import project data from tools like Jira to simulate with actual workflow metrics
- **JS/TS AST Parser** — Built-in JavaScript and TypeScript parser via Node.js Port, producing ESTree-compatible ASTs
- **Event Sourcing Ready** — Persistence layer designed for CQRS with event logs and snapshots

## Architecture

Elixir **umbrella project** with four applications:

```
Client -> GenServer (usecase) -> Agent (kanban_domain) -> In-Memory Map
```

| App | Description |
|-----|-------------|
| **kanban_domain** | Core domain structs and Agent-based state stores. Agents hold the entire object graph in memory using `Agent.get_and_update` for atomic operations. |
| **usecase** | GenServer-based application layer that orchestrates domain operations. Contains the OTP Application supervisor. |
| **persistence** | Event sourcing / CQRS persistence layer with event logs and snapshots (inspired by Prevayler and Akka Persistence). |
| **ast** | JavaScript/TypeScript AST parser via Node.js Port. Uses [Acorn](https://github.com/acornjs/acorn) for JS and the [TypeScript Compiler API](https://www.typescriptlang.org/) for TS. |

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

## Prerequisites

- **Elixir** >= 1.18 with **OTP** >= 28
- **Node.js** >= 20 (for the AST parser)

## Getting Started

```bash
# Clone the repository
git clone https://github.com/agnaldo4j/kanban_vision_api_iex.git
cd kanban_vision_api_iex

# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies (for AST parser)
cd apps/ast/asset && npm ci && cd ../../..

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
mix test --app kanban_domain
mix test --app usecase
mix test --app ast

# Run a single test file
mix test apps/kanban_domain/test/kanban_vision_api/agent/organizations_test.exs

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
| `:integration` | Integration tests (excluded by default) |

## Code Quality

```bash
# Static analysis
mix credo

# Code formatting
mix format
```

### Coverage Thresholds

| App | Minimum |
|-----|---------|
| kanban_domain | 61% |
| usecase | 12% |
| persistence | 100% |

## CI

GitHub Actions runs on every push and PR to `main`:

**Elixir 1.18.4** | **OTP 28** | **Node.js 20** | **Ubuntu**

Pipeline: `npm ci` -> `mix deps.get` -> `mix credo` -> `mix coveralls` -> `mix test --cover`

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Ensure all tests pass (`mix test`)
4. Run the linter (`mix credo`)
5. Submit a pull request

## License

This project is licensed under the [MIT License](LICENSE).