defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  defstruct [:id, :audit, :name, :description, :organization_id, :board, :defualt_projects]

  @type t :: %KanbanVisionApi.Domain.Simulation{
               id: String.t(),
               audit: KanbanVisionApi.Domain.Audit.t(),
               name: String.t(),
               description: String.t(),
               organization_id: String.t(),
               board: KanbanVisionApi.Domain.Board.t(),
               defualt_projects: List.t(KanbanVisionApi.Domain.Project.t())
             }

  def new(
        name,
        description \\ "Default Simulation Name",
        organization_id,
        board \\ KanbanVisionApi.Domain.Board.new(),
        default_projects \\ [],
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new
      ) do
    %KanbanVisionApi.Domain.Simulation{
      id: id,
      audit: audit,
      name: name,
      description: description,
      organization_id: organization_id,
      board: board,
      defualt_projects: default_projects
    }
  end
end
