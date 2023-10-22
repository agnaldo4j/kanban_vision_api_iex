defmodule KanbanVisionApi.Domain.Board do
  @moduledoc false

  defstruct [:id, :audit, :name, :workflow, :workers]

  @type t :: %KanbanVisionApi.Domain.Board {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t, 
               workflow: KanbanVisionApi.Domain.Workflow.t, 
               workers: List.t
             }

  def new(
        name \\ "Default",
        workflow  \\ %KanbanVisionApi.Domain.Workflow{}, 
        workers \\ %{}, 
        id \\ UUID.uuid4(), 
        audit \\ KanbanVisionApi.Domain.Audit.new
      ) do
    initial_state = %KanbanVisionApi.Domain.Board{
      id: id,
      audit: audit,
      name: name, 
      workflow: workflow, 
      workers: workers
    }
    KanbanVisionApi.Domain.Board.start_link(initial_state)
    initial_state
  end
end
