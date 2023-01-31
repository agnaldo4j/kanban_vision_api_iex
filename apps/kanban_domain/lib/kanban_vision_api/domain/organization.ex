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
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Organization.t) :: GenServer.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Organization{}) do
    GenServer.start_link(__MODULE__, default, name: String.to_atom(default.id))
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end
end
