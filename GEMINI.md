# GEMINI.md - Kanban Vision API Context

This file serves as the primary instructional context for Gemini CLI when working in this repository. It complements `CLAUDE.md` and the existing project documentation.

## Project Overview

**Kanban Vision API** is a Kanban board simulator built with **Elixir/OTP**. It implements a **Screaming Architecture** using **Ports & Adapters (Hexagonal)** and **Domain-Driven Design (DDD)** principles.

- **In-Memory State:** Uses the **Object Prevalence** pattern via OTP Agents for high-performance, atomic state management.
- **Umbrella Structure:**
    - `apps/kanban_domain`: Pure business logic, entities (structs), and Port behaviours.
    - `apps/persistence`: Infrastructure adapters (Agents) implementing Domain Ports.
    - `apps/usecase`: Application layer containing explicit Use Case modules and GenServer orchestrators.
    - `apps/web_api`: REST HTTP adapter (Plug + Bandit) exposing use cases as a versioned JSON API with OpenAPI 3.0 docs.
- **Observability:** Built-in structured logging with correlation IDs and Telemetry events for every business operation.

## Core Mandates & Standards

Follow the **Platform Engineering Standards** detailed in `CLAUDE.md`. Key highlights:

1.  **Explicit Use Cases:** Every business flow must be an explicit Use Case module (one operation per file).
2.  **Screaming Architecture:** Logic and folder structure must reveal business capabilities, not technical layers.
3.  **Command/Query Separation:** Use Cases receive a **Command** (write) or **Query** (read) DTO, never both.
4.  **Validation at the Edge:** Commands/Queries use factory functions (e.g., `NewCommand.new(...)`) that validate input before construction.
5.  **Ports & Adapters:** The domain (`kanban_domain`) defines Port behaviours; infrastructure (`persistence`) implements them.
6.  **Observability First:** A feature is only "Done" if it includes structured logging and Telemetry events.
7.  **Definition of Done:** Before declaring a task complete, refer to `.claude/skills/definition-of-done/SKILL.md`.

## Key Development Commands

| Task | Command |
| :--- | :--- |
| **Setup** | `mix deps.get` |
| **Build** | `mix compile` |
| **Run** | `mix run --no-halt` |
| **All Tests** | `mix test` |
| **App Tests** | `mix test apps/<app_name>/test` |
| **Watch Tests** | `mix test.watch` |
| **Contract Tests** | `mix test --only integration` |
| **Coverage** | `MIX_ENV=test mix coveralls --umbrella` |
| **Linting** | `mix credo` |
| **Types** | `mix dialyzer` |
| **Format** | `mix format` |

## Technical Conventions

- **Entities:** Created via `Module.new(...)` which auto-generates UUIDs and Audit timestamps.
- **Agents:** Use pid-based access (no atom registration) and `Agent.get_and_update` for atomic mutations.
- **GenServers:** Act only as orchestrators; business logic belongs in Use Cases.
- **Telemetry:** Follow the standard naming convention (e.g., `[:kanban_vision_api, :usecase, :organization, :created]`).

## Repository Map

- `apps/kanban_domain/lib/kanban_vision_api/domain/`: Entities (`organization.ex`, `board.ex`, etc.) and `ports/`.
- `apps/persistence/lib/kanban_vision_api/agent/`: Agent-based repository adapters.
- `apps/usecase/lib/kanban_vision_api/usecase/`: GenServers and business operation subdirectories (e.g., `organizations/`, `simulations/`).
- `apps/web_api/lib/kanban_vision_api/web_api/`: HTTP adapters — `router.ex`, `plugs/`, `organizations/`, `simulations/`, `open_api/`.
- `training/`: Documentation and exercises for the Elixir/OTP and Architecture modules.

## HTTP API (web_api)

- **Server:** Bandit `~> 1.0` (pure Elixir, no native deps)
- **Base path:** `/api/v1`
- **Docs:** Swagger UI at `/api/swagger`, OpenAPI JSON at `/api/openapi`
- **Key routes:**
  - `GET /api/v1/organizations` — list all
  - `POST /api/v1/organizations` — create (body: `{"name": "..."}`)
  - `GET /api/v1/organizations/:id` — get by ID
  - `GET /api/v1/organizations/search?name=X` — search by name
  - `DELETE /api/v1/organizations/:id` — delete
  - `GET /api/v1/simulations` — list all
  - `POST /api/v1/simulations` — create (body: `{"name": "...", "description": "...", "organization_id": "..."}`)
  - `GET /api/v1/simulations/search?org_id=X&name=Y` — search
  - `DELETE /api/v1/simulations/:id` — delete
- **Test isolation:** Controllers inject the usecase module via `Application.get_env/3`; Mox mocks swap it in tests. Set `config :web_api, start_server: false` in `config/test.exs` to skip Bandit in tests.
- **Coverage threshold:** 80% (enforced in `apps/web_api/coveralls.json`).
