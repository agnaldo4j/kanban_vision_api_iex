---
name: elixir
description: >
  Use when editing Elixir code in this repository. Covers umbrella structure,
  Elixir 1.18 / OTP 28 conventions, testing patterns, and project-specific
  rules for domain, usecase, persistence, and web_api apps.
---

# Elixir Skill

This project uses Elixir 1.18, OTP 28, and an umbrella layout.

## Work From The Root

Run commands from the repository root:

```bash
mix deps.get
mix compile
mix test
mix test --only integration
mix credo
mix dialyzer
mix format
```

## Repository-Specific Rules

- `apps/kanban_domain` stays pure: no HTTP, Agent, or GenServer dependencies.
- `apps/persistence` implements domain ports with Agents and pid-based access.
- `apps/usecase` contains one use case per operation; GenServers orchestrate only.
- `apps/web_api` adapts HTTP requests to commands and queries through Plug + Bandit.
- Commands and queries should validate at construction time through factory functions.

## Testing

- Prefer `use ExUnit.Case, async: true` for isolated tests.
- Use tags such as `:integration` when crossing boundaries.
- Add regression coverage for bug fixes.
- Keep HTTP contract behavior aligned with OpenAPI.

## When Changing Business Flows

- Add structured logs and telemetry.
- Preserve UUID-based factory creation through `Module.new(...)`.
- Avoid generic "service" modules when a specific use case name is clearer.
