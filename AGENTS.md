# Repository Guidelines

This file is the primary Codex instruction source for this repository. Project-specific Codex guidance lives here and in `.codex/skills/`.

## Architecture

This is an Elixir umbrella project built around Screaming Architecture, Ports & Adapters, and DDD.

- `apps/kanban_domain`: pure domain entities, value objects, and port behaviours.
- `apps/persistence`: Agent-based repository adapters that implement domain ports.
- `apps/usecase`: explicit use cases plus GenServer orchestrators and OTP supervision.
- `apps/web_api`: Plug + Bandit HTTP adapter with OpenAPI docs.
- `training/`: workshop material and repository documentation.

Keep business logic in use cases and domain modules. Controllers, routers, jobs, and adapters only translate inputs and outputs.

## Non-Negotiable Project Rules

- Every business operation must have an explicit use case module.
- Follow CQS, not CQRS for now: use cases receive either a command or a query DTO, never mixed ad-hoc parameters from adapters.
- Domain code must not depend on HTTP, Plug, Agent, GenServer, or persistence details.
- Repository mutations must use `Agent.get_and_update/3` for atomicity.
- Agent access stays internal to persistence adapters; do not expose raw `pid` in domain ports or introduce atom registration.
- GenServers orchestrate and delegate. They do not own business rules.
- Application-visible failures must use structured errors; adapters must not infer behavior by parsing error message text.
- New business flows must include structured logging and telemetry.

## Build, Test, and Verification

Run commands from the repository root:

```bash
mix deps.get
mix compile
mix test
mix test --only integration
mix credo
mix dialyzer
MIX_ENV=test mix coveralls.github --umbrella
mix format
```

CI runs `mix credo`, `mix dialyzer`, and `MIX_ENV=test mix coveralls.github --umbrella` in `.github/workflows/elixir.yml`.

## Testing Expectations

- Prefer fast unit tests with `use ExUnit.Case, async: true` when no shared state exists.
- Add integration or contract tests for boundaries such as Agents, HTTP adapters, and port implementations.
- For bug fixes, add a regression test that would have caught the issue.
- Respect existing tags like `:integration` and domain-specific module tags.

Coverage thresholds enforced per app:

- `kanban_domain`: 70%
- `persistence`: 100%
- `usecase`: 50%
- `web_api`: 80%

## Conventions

- Entities are created through `Module.new(...)` factories with UUIDs and audit timestamps.
- Use descriptive business names; avoid generic `Service`, `Manager`, or CRUD-first modules when a use-case name is clearer.
- Keep OpenAPI docs updated when HTTP contracts change.
- Never log secrets or PII.

## Project Skills

Project-local Codex skills live under `.codex/skills/`. Each skill follows the official Codex shape:

- `SKILL.md`: trigger metadata plus instructions
- `agents/openai.yaml`: UI-facing metadata for Codex skill discovery

Current project skills:

- `adr`: guidance for creating and maintaining ADRs in the local repository convention.
- `definition-of-done`: closure checklist before calling work complete.
- `clean-hexagonal-architecture`: guidance for refactoring toward clean domain boundaries, explicit ports/adapters, and use-case-first structure.
- `elixir`: Elixir/OTP and repository-specific coding guidance.
- `flow`: reference for Flow-based data pipelines.
- `gen-stage`: reference for GenStage and back-pressure pipelines.

Use them as supporting references, not as a substitute for the architectural rules above.
