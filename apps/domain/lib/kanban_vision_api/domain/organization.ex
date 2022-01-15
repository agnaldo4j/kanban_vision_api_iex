defmodule KanbanVisionApi.Domain.Organization do
  @moduledoc false

  @behaviour GenServer

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
    KanbanVisionApi.Domain.Organization.start_link(initial_state)
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Organization.t) :: GenServer.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Organization{}) do
    GenServer.start_link(__MODULE__, default, name: String.to_atom(default.id))
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

end
