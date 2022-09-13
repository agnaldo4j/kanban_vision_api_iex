defmodule KanbanVisionApi.Domain.Step do
  @moduledoc false

  @behaviour GenServer

  defstruct [:id, :audit, :name, :order, :requiredAbility, :tasks]

  @type t :: %KanbanVisionApi.Domain.Step {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t,
               order: Integer.t,
               requiredAbility: KanbanVisionApi.Domain.Ability.t,
               tasks: List.t
             }

  def new(
        name,
        order,
        requiredAbility \\ %KanbanVisionApi.Domain.Ability{},
        tasks,
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new
      ) do
    initial_state = %KanbanVisionApi.Domain.Step{
      id: id,
      audit: audit,
      name: name,
      order: order,
      requiredAbility: requiredAbility,
      tasks: tasks
    }
    KanbanVisionApi.Domain.Step.start_link(initial_state)
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Step.t) :: GenServer.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Step{}) do
    GenServer.start_link(__MODULE__, default, name: String.to_atom(default.id))
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

end
