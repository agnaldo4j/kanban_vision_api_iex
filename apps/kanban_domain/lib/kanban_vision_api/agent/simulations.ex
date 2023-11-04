defmodule KanbanVisionApi.Agent.Simulations do
  @moduledoc false

  use Agent

  defstruct [:id, :simulations_by_organization]

  @type t :: %KanbanVisionApi.Agent.Simulations {
               id: String.t,
               simulations_by_organization: Map.t
             }

  def new(simulations_by_organization \\ %{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Agent.Simulations{
      id: id,
      simulations_by_organization: simulations_by_organization
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Agent.Simulations.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Agent.Simulations.new) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_all(id) do
    Agent.get(id, fn state -> state.simulations_by_organization end)
  end
end
