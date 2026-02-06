defmodule KanbanVisionApi.Domain.Project do
  @moduledoc false

  defstruct [:id, :name, :order, :tasks]

  @type t :: %KanbanVisionApi.Domain.Project{
               id: String.t(),
               name: String.t(),
               order: Integer.t(),
               tasks: List.t(KanbanVisionApi.Domain.Task.t())
             }

  def new(name, order \\ 0, tasks \\ [], id \\ UUID.uuid4()) do
    %KanbanVisionApi.Domain.Project{
      id: id,
      name: name,
      order: order,
      tasks: tasks
    }
  end
end
