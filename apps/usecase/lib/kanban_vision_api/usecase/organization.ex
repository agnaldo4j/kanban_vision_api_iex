defmodule KanbanVisionApi.Usecase.Organization do
  @moduledoc false

  use GenServer

  # Client

  @spec start_link(map) :: GenServer.on_start()
  def start_link(default \\ %{}) when is_map(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def get_all(pid) do
    GenServer.call(pid, :get_all)
  end

  def get_by_id(pid, domain_id) do
    GenServer.call(pid, {:get_by_id, domain_id})
  end

  def get_by_name(pid, domain_name) do
    GenServer.call(pid, {:get_by_name, domain_name})
  end

  def add(pid, new_organization = %KanbanVisionApi.Domain.Organization{}) do
    GenServer.call(pid, {:add, new_organization})
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:get_by_id, domain_id}, _from, state) do
    result = case Map.get(state, domain_id) do
      nil -> {:error, "Organization with id: #{domain_id} not found"}
      domain -> {:ok, domain}
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_name, domain_name}, _from, state) do
    result = internal_get_by_name(state, domain_name)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, new_organization}, _from, state) do
    case internal_get_by_name(state, new_organization.name) do
      {:error, _} ->
        new_state = Map.put(state, new_organization.id, new_organization)
        {:reply, {:ok, new_organization}, new_state}
      {:ok, _} ->
        {:reply, {:error, "Organization with name #{new_organization.name} already exists"}, state}
    end
  end

  defp internal_get_by_name(state, domain_name) do
    Map.values(state)
    |> Enum.filter(fn domain -> domain.name == domain_name end)
    |> prepare_by_name_result(domain_name)
  end

  defp prepare_by_name_result(result_list, domain_name) do
    case result_list do
      values when values == [] -> {:error, "Organization with name: #{domain_name} not found"}
      values -> {:ok, values}
    end
  end
end