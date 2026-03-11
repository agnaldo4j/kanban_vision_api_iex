defmodule KanbanVisionApi.WebApi.OpenApi.Schemas.ErrorSchema do
  @moduledoc false

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Error",
    description: "API error response",
    type: :object,
    properties: %{
      error: %OpenApiSpex.Schema{type: :string, description: "Human-readable error message"}
    },
    required: [:error]
  })
end
