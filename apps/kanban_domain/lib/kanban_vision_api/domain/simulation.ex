defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  use Agent

  defstruct [:id, :audit, :name, :description, :board, :defualt_projects]

  @type t :: %KanbanVisionApi.Domain.Simulation{
               id: String.t(),
               audit: KanbanVisionApi.Domain.Audit.t(),
               name: String.t(),
               description: String.t(),
               board: KanbanVisionApi.Domain.Board.t(),
               defualt_projects: List.t(KanbanVisionApi.Domain.Project.t())
             }

  def new(
        name,
        description \\ "Default Simulation Name",
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
      board: board,
      defualt_projects: default_projects
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Simulation.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Simulation{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end
end
