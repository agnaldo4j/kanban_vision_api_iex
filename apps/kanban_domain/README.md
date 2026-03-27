# Kanban Domain

## Overview

The `kanban_domain` is the business core of the Kanban Vision API. It defines domain entities, value objects, and domain rules independently of HTTP, processes, or persistence mechanisms.

## Structure

The `kanban_domain` is structured around pure domain modules and port contracts.

### Domain

The `Domain` part of the `kanban_domain` defines the data structures and business logic of the application. It includes modules like `Board`, `Workflow`, `Ability`, `Audit`, `Organization`, `Project`, `ServiceClass`, `Simulation`, `Step`, `Task`, and `Worker` which define the structure of these entities and how they behave.

For example, the `Board` module defines a data structure with fields like `id`, `name`, `workflow`, and `workers`. It also includes a `new` function to create a new instance of a board.

## Contributing

Contributions to the `kanban_domain` are welcome. Please ensure that you have tested your changes thoroughly before submitting a pull request. When adding new functionality, consider whether it might be necessary to add corresponding tests to ensure the continued correct functioning of the `kanban_domain`.

## License

This project is licensed under the [MIT License](LICENSE).
