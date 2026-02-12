defmodule KanbanVisionApi.Usecase.Organization do
  @moduledoc """
  GenServer orchestrating organization use cases.

  Maintains repository state and delegates operations to specialized Use Case modules.
  Follows Single Responsibility Principle by acting as a coordinator, not a business logic container.
  """

  use GenServer

  alias KanbanVisionApi.Agent.Organizations
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery
  alias KanbanVisionApi.Usecase.Organizations.CreateOrganization
  alias KanbanVisionApi.Usecase.Organizations.DeleteOrganization
  alias KanbanVisionApi.Usecase.Organizations.GetAllOrganizations
  alias KanbanVisionApi.Usecase.Organizations.GetOrganizationById
  alias KanbanVisionApi.Usecase.Organizations.GetOrganizationByName

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid, opts \\ []), do: GenServer.call(pid, {:get_all, opts})

  def get_by_id(pid, %GetOrganizationByIdQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_id, query, opts})
  end

  def get_by_name(pid, %GetOrganizationByNameQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_name, query, opts})
  end

  def add(pid, %CreateOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def delete(pid, %DeleteOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:delete, cmd, opts})
  end

  # Server — delegates to Use Cases

  @impl true
  def init(_opts) do
    {:ok, agent_pid} = Organizations.start_link()
    {:ok, %{repository_pid: agent_pid}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    result = GetAllOrganizations.execute(state.repository_pid, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_id, query, opts}, _from, state) do
    result = GetOrganizationById.execute(query, state.repository_pid, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_name, query, opts}, _from, state) do
    result = GetOrganizationByName.execute(query, state.repository_pid, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateOrganization.execute(cmd, state.repository_pid, opts)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:delete, cmd, opts}, _from, state) do
    result = DeleteOrganization.execute(cmd, state.repository_pid, opts)
    {:reply, result, state}
  end
end
