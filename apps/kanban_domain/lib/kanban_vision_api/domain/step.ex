defmodule KanbanVisionApi.Domain.Step do
  @moduledoc false

  use Agent

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

  @spec start_link(KanbanVisionApi.Domain.Step.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Step{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

end
