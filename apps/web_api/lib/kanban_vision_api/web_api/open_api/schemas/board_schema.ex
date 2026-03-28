defmodule KanbanVisionApi.WebApi.OpenApi.Schemas.BoardSchema do
  @moduledoc false

  @spec summary() :: OpenApiSpex.Schema.t()
  def summary do
    %OpenApiSpex.Schema{
      title: "BoardSummary",
      description: "Board summary representation",
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :string},
        name: %OpenApiSpex.Schema{type: :string},
        simulation_id: %OpenApiSpex.Schema{type: :string},
        created_at: %OpenApiSpex.Schema{type: :string, format: :"date-time"},
        updated_at: %OpenApiSpex.Schema{type: :string, format: :"date-time"}
      },
      required: [:id, :name, :simulation_id, :created_at, :updated_at]
    }
  end

  @spec detail() :: OpenApiSpex.Schema.t()
  def detail do
    %OpenApiSpex.Schema{
      title: "BoardDetail",
      description: "Board detail representation with workflow and workers",
      type: :object,
      properties:
        Map.merge(summary().properties, %{
          workflow: workflow_schema(),
          workers: %OpenApiSpex.Schema{type: :array, items: worker_schema()}
        }),
      required: summary().required ++ [:workflow, :workers]
    }
  end

  @spec rename_request() :: OpenApiSpex.Schema.t()
  def rename_request do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{name: %OpenApiSpex.Schema{type: :string}},
      required: [:name]
    }
  end

  @spec add_step_request() :: OpenApiSpex.Schema.t()
  def add_step_request do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        name: %OpenApiSpex.Schema{type: :string},
        order: %OpenApiSpex.Schema{type: :integer, minimum: 0},
        required_ability_name: %OpenApiSpex.Schema{type: :string}
      },
      required: [:name, :order, :required_ability_name]
    }
  end

  @spec reorder_step_request() :: OpenApiSpex.Schema.t()
  def reorder_step_request do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{order: %OpenApiSpex.Schema{type: :integer, minimum: 0}},
      required: [:order]
    }
  end

  @spec allocate_worker_request() :: OpenApiSpex.Schema.t()
  def allocate_worker_request do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        name: %OpenApiSpex.Schema{type: :string},
        abilities: %OpenApiSpex.Schema{type: :array, items: %OpenApiSpex.Schema{type: :string}}
      },
      required: [:name, :abilities]
    }
  end

  defp workflow_schema do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        steps: %OpenApiSpex.Schema{type: :array, items: step_schema()}
      },
      required: [:steps]
    }
  end

  defp step_schema do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :string},
        name: %OpenApiSpex.Schema{type: :string},
        order: %OpenApiSpex.Schema{type: :integer},
        required_ability: ability_schema()
      },
      required: [:id, :name, :order, :required_ability]
    }
  end

  defp worker_schema do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :string},
        name: %OpenApiSpex.Schema{type: :string},
        abilities: %OpenApiSpex.Schema{type: :array, items: ability_schema()}
      },
      required: [:id, :name, :abilities]
    }
  end

  defp ability_schema do
    %OpenApiSpex.Schema{
      type: :object,
      properties: %{
        id: %OpenApiSpex.Schema{type: :string},
        name: %OpenApiSpex.Schema{type: :string}
      },
      required: [:id, :name]
    }
  end
end
