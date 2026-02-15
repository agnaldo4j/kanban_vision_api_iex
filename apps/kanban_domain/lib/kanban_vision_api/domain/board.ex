defmodule KanbanVisionApi.Domain.Board do
  @moduledoc false

  defstruct [:id, :audit, :name, :simulation_id, :workflow, :workers]

  @type t :: %KanbanVisionApi.Domain.Board{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          simulation_id: String.t(),
          workflow: KanbanVisionApi.Domain.Workflow.t(),
          workers: %{optional(String.t()) => KanbanVisionApi.Domain.Worker.t()}
        }

  def new(
        name \\ "Default",
        simulation_id \\ "Default Simulation ID",
        workflow \\ %KanbanVisionApi.Domain.Workflow{},
        workers \\ %{},
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new()
      ) do
    %KanbanVisionApi.Domain.Board{
      id: id,
      audit: audit,
      name: name,
      simulation_id: simulation_id,
      workflow: workflow,
      workers: workers
    }
  end
end
