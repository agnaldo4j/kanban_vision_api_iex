defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  defstruct [:id, :audit, :steps]

  @type t :: %KanbanVisionApi.Domain.Workflow{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          steps: [KanbanVisionApi.Domain.Step.t()]
        }

  def new(steps \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Workflow{
      id: id,
      audit: audit,
      steps: steps
    }
  end
end
