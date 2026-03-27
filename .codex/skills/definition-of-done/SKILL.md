---
name: definition-of-done
description: >
  Use before declaring a task complete in this repository. Verifies tests,
  contracts, observability, rollout safety, and documentation expectations for
  Kanban Vision API changes.
---

# Definition Of Done

Apply this checklist before saying a feature, fix, or refactor is done.

## Verify

- Tests cover success paths, failures, and regressions.
- Integration or contract coverage exists for every changed boundary.
- CI-relevant commands were run, or the reason they were not run is explicit.
- OpenAPI docs or other contracts were updated when public behavior changed.

## Confirm Architecture

- Business logic stays in use cases or domain modules.
- Adapters only translate input and output.
- Domain ports remain infrastructure-agnostic.
- New repository writes keep atomicity with `Agent.get_and_update/3`.

## Confirm Operations

- Logs, telemetry, and correlation-friendly behavior were added where the flow changed.
- No secrets or PII are logged.
- Rollout and rollback risks are known for externally visible changes.

## Confirm Project Hygiene

- README, training docs, or operational notes were updated when the change affects them.
- Final handoff names remaining risks, skipped checks, and next actions if anything is still open.
