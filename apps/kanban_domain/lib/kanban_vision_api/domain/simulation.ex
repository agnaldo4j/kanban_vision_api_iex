defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Project

  defstruct [:id, :audit, :name, :description, :organization_id, :board, :default_projects]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          description: String.t(),
          organization_id: String.t(),
          board: Board.t() | nil,
          default_projects: [Project.t()]
        }

  def new(
        name,
        description \\ "Default Simulation Name",
        organization_id,
        board \\ Board.new(),
        default_projects \\ [],
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      description: description,
      organization_id: organization_id,
      board: board,
      default_projects: default_projects
    }
  end
end
