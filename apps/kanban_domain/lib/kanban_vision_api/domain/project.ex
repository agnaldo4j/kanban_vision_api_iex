defmodule KanbanVisionApi.Domain.Project do
  @moduledoc false

  defstruct [:id, :name, :order, :tasks]

  @type t :: %KanbanVisionApi.Domain.Project{
               id: String.t(),
               name: String.t(),
               order: Integer.t(),
               tasks: List.t(KanbanVisionApi.Domain.Task.t())
             }

  def new(name) do
    %KanbanVisionApi.Domain.Project{
      name: name
    }
  end

end
