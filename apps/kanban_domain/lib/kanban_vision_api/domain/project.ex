defmodule KanbanVisionApi.Domain.Project do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Task

  defstruct [:id, :audit, :name, :order, :tasks]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          order: non_neg_integer(),
          tasks: [Task.t()]
        }

  def new(
        name,
        order \\ 0,
        tasks \\ [],
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      order: order,
      tasks: tasks
    }
  end
end
