defmodule KanbanVisionApi.Usecase.Simulation do
  @moduledoc false

  use GenServer

  # Client

  @spec start_link(map | keyword) :: GenServer.on_start()
  def start_link() do
    start_link(%{})
  end

  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def start_link(opts) when is_list(opts) do
    {initial, opts} = Keyword.pop(opts, :initial, %{})
    GenServer.start_link(__MODULE__, initial, opts)
  end

  def push(pid, element) do
    GenServer.call(pid, {:push, element})
  end

  def fetch(pid) do
    GenServer.call(pid, :fetch)
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:fetch, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:push, element}, _from, state) do
    new_state = Map.put(state, element.id, element)
    {:reply, {:ok, element}, new_state}
  end
end
