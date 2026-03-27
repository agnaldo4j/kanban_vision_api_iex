# Persistence

## Overview

The `persistence` application is responsible for the persistence boundary of the Kanban Vision API. Today it keeps application state in memory for the lifetime of the process to simplify the project runtime. The design should stay ready for future evolution toward persisted commands plus snapshots in a prevalence-style model without changing the core use cases.

This application is influenced by the prevalence system from the [Prevayler](http://prevayler.org/) project and by event log and snapshot ideas, but those mechanisms are not implemented yet in the current in-memory adapter.

## Structure

The `persistence` application is currently structured as in-memory adapters behind repository ports.

### Current State

State lives only during process execution. Agent-backed adapters provide a simple persistence mechanism for development, tests, and architectural exploration.

### Future Direction

The intended evolution is a prevalence-style persistence model with command persistence and snapshots. The application layer should continue to depend on ports so this change remains isolated to adapters.

### CQS

At the application boundary, the project follows CQS: use cases accept either a Command or a Query DTO. This is distinct from CQRS and does not imply separate read and write models.

## Contributing

Contributions to the `persistence` application are welcome. Please ensure that you have tested your changes thoroughly before submitting a pull request. When adding new functionality, consider whether it might be necessary to add corresponding tests to ensure the continued correct functioning of the `persistence` application.

## License

This project is licensed under the [MIT License](LICENSE).

## References

- [Prevayler](http://prevayler.org/)
- [Akka Persistence](https://doc.akka.io/docs/akka/current/typed/persistence.html)
- [CQS](https://martinfowler.com/bliki/CommandQuerySeparation.html)
