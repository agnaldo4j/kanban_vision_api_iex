defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  use Agent

  defstruct [:id, :audit, :steps]

  @type t :: %KanbanVisionApi.Domain.Workflow {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               steps: List.t
             }

  def new(steps \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new) do
    initial_state = %KanbanVisionApi.Domain.Workflow{
      id: id,
      audit: audit,
      steps: steps
    }
    KanbanVisionApi.Domain.Workflow.start_link(initial_state)
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Workflow.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Workflow{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

end
