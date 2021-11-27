defmodule KanbanVisionApi.Usecase.Organization do
  @moduledoc false

  @behaviour GenServer

  # Client

  @spec start_link(list) :: GenServer.on_start()
  def start_link(default \\ %{}) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
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
    {:reply, {:ok, element}, state}
  end
end
