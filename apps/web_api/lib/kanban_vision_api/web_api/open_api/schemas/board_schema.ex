defmodule KanbanVisionApi.WebApi.OpenApi.Schemas.BoardSchema do
  @moduledoc false

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Board",
    description: "Board representation",
    type: :object,
    properties: %{
      id: %OpenApiSpex.Schema{type: :string},
      name: %OpenApiSpex.Schema{type: :string},
      simulation_id: %OpenApiSpex.Schema{type: :string},
      created_at: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
      updated_at: %OpenApiSpex.Schema{type: :string, format: :"date-time"}
    },
    required: [:id, :name, :simulation_id, :created_at, :updated_at]
  })
end
