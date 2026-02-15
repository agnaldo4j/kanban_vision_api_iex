defmodule KanbanVisionApi.Domain.Step do
  @moduledoc false

  defstruct [:id, :audit, :name, :order, :required_ability, :tasks]

  @type t :: %KanbanVisionApi.Domain.Step{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          order: non_neg_integer(),
          required_ability: KanbanVisionApi.Domain.Ability.t(),
          tasks: [KanbanVisionApi.Domain.Task.t()]
        }

  def new(
        name,
        order,
        required_ability \\ %KanbanVisionApi.Domain.Ability{},
        tasks,
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new()
      ) do
    %KanbanVisionApi.Domain.Step{
      id: id,
      audit: audit,
      name: name,
      order: order,
      required_ability: required_ability,
      tasks: tasks
    }
  end
end
