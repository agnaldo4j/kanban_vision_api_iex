defmodule KanbanVisionApi.Usecase.Simulation do
  @moduledoc """
  GenServer orchestrating simulation use cases.

  Maintains repository state and delegates operations to specialized Use Case modules.
  Follows Single Responsibility Principle by acting as a coordinator, not a business logic container.
  """

  use GenServer

  alias KanbanVisionApi.Usecase.RepositoryConfig
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery
  alias KanbanVisionApi.Usecase.Simulations.CreateSimulation
  alias KanbanVisionApi.Usecase.Simulations.DeleteSimulation
  alias KanbanVisionApi.Usecase.Simulations.GetAllSimulations
  alias KanbanVisionApi.Usecase.Simulations.GetSimulationByOrgAndName

  # Client API

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :repository, RepositoryConfig.fetch!(:simulation))
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid, opts \\ []), do: GenServer.call(pid, {:get_all, opts})

  def add(pid, %CreateSimulationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def delete(pid, %DeleteSimulationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:delete, cmd, opts})
  end

  def get_by_org_and_name(pid, %GetSimulationByOrgAndNameQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_org_and_name, query, opts})
  end

  # Server — delegates to Use Cases

  @impl true
  def init(opts) do
    repository = Keyword.fetch!(opts, :repository)
    {:ok, repository_pid} = repository.start_link()
    repository_runtime = repository.runtime(repository_pid)
    {:ok, %{repository_runtime: repository_runtime, repository: repository}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    result = GetAllSimulations.execute(state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateSimulation.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:delete, cmd, opts}, _from, state) do
    result = DeleteSimulation.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_org_and_name, query, opts}, _from, state) do
    result =
      GetSimulationByOrgAndName.execute(query, state.repository_runtime, enrich_opts(opts, state))

    {:reply, result, state}
  end

  defp enrich_opts(opts, state) do
    Keyword.put_new(opts, :repository, state.repository)
  end
end
