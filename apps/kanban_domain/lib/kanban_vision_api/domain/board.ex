defmodule KanbanVisionApi.Domain.Board do
  @moduledoc false

  use Agent

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

  # Client

  @spec start_link(KanbanVisionApi.Domain.Board.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Board{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

end
