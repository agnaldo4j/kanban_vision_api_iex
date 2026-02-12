defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  defstruct [:id, :audit, :steps]

  @type t :: %KanbanVisionApi.Domain.Workflow{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          steps: List.t()
        }

  def new(steps \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    initial_state = %KanbanVisionApi.Domain.Workflow{
      id: id,
      audit: audit,
      steps: steps
    }

    initial_state
  end
end
