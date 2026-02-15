defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Step

  defstruct [:id, :audit, :steps]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          steps: [Step.t()]
        }

  def new(steps \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      steps: steps
    }
  end
end
