# Clean + Screaming Architecture Notes

This reference condenses the architectural ideas requested for this repository.

## Clean Architecture

- The core business rules stay at the center and must not depend on frameworks,
  databases, UI, or delivery mechanisms.
- Source-code dependencies point inward. Outer layers can depend on inner
  policies; inner layers must not know the outer mechanisms.
- Boundaries are crossed through simple data structures or interfaces defined by
  the core, so adapters can be replaced without changing business rules.
- Use cases coordinate domain objects and represent application-specific actions.
- Databases and web frameworks are tools. They should be replaceable details.

## Screaming Architecture

- The repository should "scream" the business domain and use cases, not the
  framework or transport mechanism.
- The top-level organization should help a reader infer what the system does.
- Delivery mechanisms such as web, database, or jobs should remain secondary.
- A healthy architecture keeps frameworks at arm's length so use cases stay
  testable without infrastructure.

## Mapping To This Repository

- `kanban_domain` is the inner business core.
- `usecase` is the application boundary where business actions are executed.
- `persistence` and `web_api` are adapters on the outside.
- GenServers coordinate work but should not absorb business policy.
- Agent-backed repositories are infrastructure details behind repository ports.

## Practical Review Questions

- If the adapter changed, would the business rule code remain intact?
- If the web layer disappeared, could the use case still run in a test?
- If the storage mechanism changed, would the port contract remain stable?
- Does the module naming highlight the business capability first?
