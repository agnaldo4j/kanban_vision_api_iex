defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  @behaviour GenServer

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

  @spec start_link(KanbanVisionApi.Domain.Workflow.t) :: GenServer.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Workflow{}) do
    GenServer.start_link(__MODULE__, default, name: String.to_atom(default.id))
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

end
