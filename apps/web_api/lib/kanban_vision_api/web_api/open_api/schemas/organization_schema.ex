defmodule KanbanVisionApi.WebApi.OpenApi.Schemas.OrganizationSchema do
  @moduledoc false

  require OpenApiSpex

  OpenApiSpex.schema(%{
    title: "Organization",
    description: "A Kanban organization entity",
    type: :object,
    properties: %{
      id: %OpenApiSpex.Schema{type: :string, description: "Organization UUID"},
      name: %OpenApiSpex.Schema{type: :string, description: "Organization name"},
      tribes: %OpenApiSpex.Schema{
        type: :array,
        items: %OpenApiSpex.Schema{type: :object},
        description: "List of tribes"
      },
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
    required: [:id, :name]
  })
end
