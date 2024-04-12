# Persistence

## Overview

The `persistence` application is a crucial component of the Kanban Vision API. It's responsible for managing the persistence layer of the application, ensuring that the state of the system is maintained across sessions. The application is built with Elixir and leverages the power of event sourcing and CQRS (Command Query Responsibility Segregation) to provide a robust and scalable solution for data persistence.

This application is inspired by the concepts of event logs and snapshots from the Akka actor model, and the prevalence system from the [Prevayler](http://prevayler.org/) project.

## Structure

The `persistence` application is structured around the concepts of event logs and snapshots.

### Event Logs

Event logs are a record of all the events that have occurred in the system. Each event represents a change in the state of the system. By replaying these events, we can reconstruct the current state of the system. This approach is known as event sourcing.

### Snapshots

While event sourcing provides a robust way to maintain and reconstruct system state, replaying a long list of events can be time-consuming. To mitigate this, the `persistence` application uses snapshots. A snapshot is a saved state of a particular entity at a specific point in time. By saving snapshots periodically, we can reduce the number of events that need to be replayed to reconstruct the current state.

### CQRS

CQRS stands for Command Query Responsibility Segregation. It's a pattern that separates reading data from writing data. In the context of the `persistence` application, we use CQRS to ensure that our event sourcing and snapshotting mechanisms can operate efficiently and independently of the query operations.

## Contributing

Contributions to the `persistence` application are welcome. Please ensure that you have tested your changes thoroughly before submitting a pull request. When adding new functionality, consider whether it might be necessary to add corresponding tests to ensure the continued correct functioning of the `persistence` application.

## License

This project is licensed under the [MIT License](LICENSE).

## References

- [Prevayler](http://prevayler.org/)
- [Akka Persistence](https://doc.akka.io/docs/akka/current/typed/persistence.html)
- [CQRS](https://martinfowler.com/bliki/CQRS.html)