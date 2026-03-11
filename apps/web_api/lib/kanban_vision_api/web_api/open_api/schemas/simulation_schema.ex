defmodule KanbanVisionApi.WebApi.OpenApi.Schemas.SimulationSchema do
  @moduledoc false

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Simulation",
    description: "A Kanban simulation entity",
    type: :object,
    properties: %{
      id: %OpenApiSpex.Schema{type: :string, description: "Simulation UUID"},
      name: %OpenApiSpex.Schema{type: :string, description: "Simulation name"},
      description: %OpenApiSpex.Schema{type: :string, description: "Simulation description"},
      organization_id: %OpenApiSpex.Schema{type: :string, description: "Owner organization UUID"},
      created_at: %OpenApiSpex.Schema{
        type: :string,
        format: :"date-time",
        description: "Creation timestamp (ISO8601)"
      },
      updated_at: %OpenApiSpex.Schema{
        type: :string,
        format: :"date-time",
        description: "Last update timestamp (ISO8601)"
      }
    },
    required: [:id, :name, :organization_id]
  })
end
