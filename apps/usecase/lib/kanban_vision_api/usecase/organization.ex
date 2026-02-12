defmodule KanbanVisionApi.Usecase.Organization do
  @moduledoc false

  use GenServer

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid), do: GenServer.call(pid, :get_all)

  def get_by_id(pid, %GetOrganizationByIdQuery{} = query) do
    GenServer.call(pid, {:get_by_id, query.id})
  end

  def get_by_name(pid, %GetOrganizationByNameQuery{} = query) do
    GenServer.call(pid, {:get_by_name, query.name})
  end

  def add(pid, %CreateOrganizationCommand{} = cmd) do
    organization = KanbanVisionApi.Domain.Organization.new(cmd.name, cmd.tribes)
    GenServer.call(pid, {:add, organization})
  end

  def delete(pid, %DeleteOrganizationCommand{} = cmd) do
    GenServer.call(pid, {:delete, cmd.id})
  end

  # Server — delegates to Agent

  @impl true
  def init(_opts) do
    {:ok, agent_pid} = KanbanVisionApi.Agent.Organizations.start_link()
    {:ok, %{agent_pid: agent_pid}}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    result = KanbanVisionApi.Agent.Organizations.get_all(state.agent_pid)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:get_by_id, id}, _from, state) do
    result = KanbanVisionApi.Agent.Organizations.get_by_id(state.agent_pid, id)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_name, name}, _from, state) do
    result = KanbanVisionApi.Agent.Organizations.get_by_name(state.agent_pid, name)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, organization}, _from, state) do
    result = KanbanVisionApi.Agent.Organizations.add(state.agent_pid, organization)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:delete, id}, _from, state) do
    result = KanbanVisionApi.Agent.Organizations.delete(state.agent_pid, id)
    {:reply, result, state}
  end
end
