---
name: adr
description: >
  Use when creating, updating, reviewing, or planning Architectural Decision
  Records in this repository. Covers the local `adr/` convention, Nygard-style
  ADR structure, numbering, relations between ADRs, and how to record phased
  architecture decisions without mixing them with implementation work.
---

# ADR Skill

Use this skill when the user wants to register, revise, or assess
architectural decisions for this repository.

## First Step

Read `adr/README.md` and any ADRs directly related to the requested decision
before writing a new one.

## Local Convention

- ADR files live in `adr/`.
- Use file names in the form `NNNN-short-kebab-case-title.md`.
- Keep the `adr/README.md` index updated when adding a new ADR.
- Use Nygard-style sections: `Status`, `Context`, `Decision`, and
  `Consequences`.
- It is acceptable in this repository to add an `Execution Plan` section when a
  decision will be implemented incrementally.

## When To Create vs Update

- Create a new ADR when the decision is materially new, supersedes an older
  one, or defines a new phase of architectural direction.
- Update an existing ADR when you are only clarifying wording, status, or
  execution progress without changing the actual decision.
- If the new document narrows, replaces, or extends an earlier decision, add
  `Related` or `Supersedes` metadata explicitly.

## Writing Rules

- Capture one primary decision per ADR.
- Separate decision from implementation. Record the chosen direction and plan,
  not code-level patch details.
- State clearly whether the ADR is `planned`, `accepted`, `superseded`, or
  another explicit status.
- Keep the context specific to this repository: CQS, clean domain boundaries,
  hexagonal architecture, in-memory persistence now, and prevalence-readiness
  later when relevant.
- When the decision spans multiple iterations, describe phases in priority
  order and mark each phase status explicitly.

## Expected Shape

Most ADRs in this repository should include:

- Title with ADR number.
- Metadata lines for `Status`, `Date`, and optionally `Related` or
  `Supersedes`.
- `Context`
- `Decision`
- `Consequences`
- `Execution Plan` when the work is phased
- `Notes` only when needed

## Review Checklist

Before finishing, verify:

- The ADR explains why the decision matters architecturally.
- The decision is distinct from the implementation mechanics.
- Terminology matches the project direction; for example, prefer `CQS` over
  `CQRS` unless a true CQRS decision is being introduced.
- References to earlier ADRs are accurate.
- The file name, title, and index entry all match.

## References

If needed, read:

- `adr/README.md`
- the directly related ADR files in `adr/`
