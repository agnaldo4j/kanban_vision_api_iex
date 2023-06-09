defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  defstruct [:id, :name, :description, :board, :defualt_projects]

  @type t :: %KanbanVisionApi.Domain.Simulation{
               id: String.t(),
               name: String.t(),
               description: String.t(),
               board: KanbanVisionApi.Domain.Board.t(),
               defualt_projects: List.t(KanbanVisionApi.Domain.Project.t())
             }

  def new(name) do
    %KanbanVisionApi.Domain.Simulation{
      name: name
    }
  end

end
