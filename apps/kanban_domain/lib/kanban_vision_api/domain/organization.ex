defmodule KanbanVisionApi.Domain.Organization do
  @moduledoc false

  use Agent

  defstruct [:id, :audit, :name, :simulations]

  @type t :: %KanbanVisionApi.Domain.Organization {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t,
               simulations: Map.t
             }

  def new(name, simulations \\ %{}, id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new) do
    initial_state = %KanbanVisionApi.Domain.Organization{
      id: id,
      audit: audit,
      name: name,
      simulations: simulations
    }
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Organization.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Organization{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end
end
