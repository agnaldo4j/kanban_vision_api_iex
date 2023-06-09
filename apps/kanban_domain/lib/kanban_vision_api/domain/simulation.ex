defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  use Agent

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

  # Client

  @spec start_link(KanbanVisionApi.Domain.Simulation.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Simulation{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end
end
