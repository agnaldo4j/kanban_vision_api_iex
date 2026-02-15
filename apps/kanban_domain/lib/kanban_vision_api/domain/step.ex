defmodule KanbanVisionApi.Domain.Step do
  @moduledoc false

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Task

  defstruct [:id, :audit, :name, :order, :required_ability, :tasks]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          order: non_neg_integer(),
          required_ability: Ability.t(),
          tasks: [Task.t()]
        }

  def new(
        name,
        order,
        required_ability \\ %Ability{},
        tasks,
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      order: order,
      required_ability: required_ability,
      tasks: tasks
    }
  end
end
