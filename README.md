[![Elixir CI](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml/badge.svg)](https://github.com/agnaldo4j/kanban_vision_api_iex/actions/workflows/elixir.yml)
[![Coverage Status](https://coveralls.io/repos/github/agnaldo4j/kanban_vision_api_iex/badge.svg?branch=main)](https://coveralls.io/github/agnaldo4j/kanban_vision_api_iex?branch=main)

# Kanban Vision API

## Overview

The Kanban Vision API is a project designed to simulate a Kanban system, loaded with real data from tools like Jira and others. It's built with Elixir and leverages the power of functional programming to provide a robust and scalable solution for Kanban simulation.

## Features

- **Real Data Integration**: The API is designed to integrate with real-world project management tools like Jira, enabling you to simulate a Kanban system with actual project data.

- **Kanban Simulation**: The core functionality of the API is to simulate a Kanban system, allowing you to visualize and manage your project workflow in a Kanban style.

- **Elixir Powered**: The API is built with Elixir, a dynamic, functional language designed for building scalable and maintainable applications.

## Getting Started

To get started with the Kanban Vision API, you'll need to have Elixir installed on your machine. Once you have Elixir installed, you can clone this repository and install the project's dependencies.

```bash
git clone https://github.com/your-repo/kanban_vision_api.git
cd kanban_vision_api
mix deps.get
```

You can then compile the project and start the server.

```bash
mix compile
mix run --no-halt
```

## Testing

The project includes a suite of tests to ensure its functionality. You can run these tests using the following command:

```bash
mix test
```

### Running tests with @moduletag/@tag

You can organize and filter tests using ExUnit tags. For example, to group slower or external dependency tests as integration:

In a test module:

```elixir
defmodule MyModuleTest do
  use ExUnit.Case

  @moduletag :integration

  test "something", do: assert true
end
```

Or on a single test:

```elixir
  @tag :integration
  test "only this is integration", do: assert true
```

By default, this repo excludes :integration tests in apps/ast/test/test_helper.exs. You can control what to run:

- Run only integration tests:

```bash
mix test --only integration
```

- Exclude integration tests explicitly (default behavior):

```bash
mix test --exclude integration
```

- Run a specific tag key/value (e.g., @tag :slow true):

```bash
mix test --only slow
# or
mix test --only slow:true
```

Tip: multiple @moduletag lines are allowed (e.g., @moduletag :capture_log and @moduletag :integration).

## Contributing

Contributions to the Kanban Vision API are welcome. Please ensure that you have tested your changes thoroughly before submitting a pull request.

## License

This project is licensed under the [MIT License](LICENSE).

