defmodule KanbanVisionApi.Agent.Boards do
  @moduledoc false

  use Agent

  defstruct [:id, :workflow]

  @type t :: %KanbanVisionApi.Agent.Boards {
               id: String.t,
               workflow: KanbanVisionApi.Domain.Workflow.t
             }

  def new(workflow \\ %KanbanVisionApi.Domain.Workflow{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Agent.Boards{
      id: id,
      workflow: workflow
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Agent.Boards.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Agent.Boards.new) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end
  
end
