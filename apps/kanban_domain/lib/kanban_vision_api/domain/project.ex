defmodule KanbanVisionApi.Domain.Project do
  @moduledoc false

  use Agent

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

  # Client

  @spec start_link(KanbanVisionApi.Domain.Project.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Project{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

end
