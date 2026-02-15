defmodule KanbanVisionApi.Domain.Board do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.Domain.Workflow

  defstruct [:id, :audit, :name, :simulation_id, :workflow, :workers]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          simulation_id: String.t(),
          workflow: Workflow.t(),
          workers: %{optional(String.t()) => Worker.t()}
        }

  def new(
        name \\ "Default",
        simulation_id \\ "Default Simulation ID",
        workflow \\ %Workflow{},
        workers \\ %{},
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      simulation_id: simulation_id,
      workflow: workflow,
      workers: workers
    }
  end
end
