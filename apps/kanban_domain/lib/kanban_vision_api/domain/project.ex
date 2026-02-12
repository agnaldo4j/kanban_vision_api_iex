defmodule KanbanVisionApi.Domain.Project do
  @moduledoc false

  defstruct [:id, :audit, :name, :order, :tasks]

  @type t :: %KanbanVisionApi.Domain.Project{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          order: Integer.t(),
          tasks: List.t(KanbanVisionApi.Domain.Task.t())
        }

  def new(
        name,
        order \\ 0,
        tasks \\ [],
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new()
      ) do
    %KanbanVisionApi.Domain.Project{
      id: id,
      audit: audit,
      name: name,
      order: order,
      tasks: tasks
    }
  end
end
