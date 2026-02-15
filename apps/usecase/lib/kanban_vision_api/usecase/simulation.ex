defmodule KanbanVisionApi.Usecase.Simulation do
  @moduledoc """
  GenServer orchestrating simulation use cases.

  Maintains repository state and delegates operations to specialized Use Case modules.
  Follows Single Responsibility Principle by acting as a coordinator, not a business logic container.
  """

  use GenServer

  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery
  alias KanbanVisionApi.Usecase.Simulations.CreateSimulation
  alias KanbanVisionApi.Usecase.Simulations.GetAllSimulations
  alias KanbanVisionApi.Usecase.Simulations.GetSimulationByOrgAndName

  @default_repository KanbanVisionApi.Agent.Simulations

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid, opts \\ []), do: GenServer.call(pid, {:get_all, opts})

  def add(pid, %CreateSimulationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def get_by_org_and_name(pid, %GetSimulationByOrgAndNameQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_org_and_name, query, opts})
  end

  # Server — delegates to Use Cases

  @impl true
  def init(opts) do
    repository = Keyword.get(opts, :repository, @default_repository)
    {:ok, agent_pid} = repository.start_link()
    {:ok, %{repository_pid: agent_pid, repository: repository}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    result = GetAllSimulations.execute(state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateSimulation.execute(cmd, state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_org_and_name, query, opts}, _from, state) do
    result =
      GetSimulationByOrgAndName.execute(query, state.repository_pid, enrich_opts(opts, state))

    {:reply, result, state}
  end

  defp enrich_opts(opts, state) do
    Keyword.put_new(opts, :repository, state.repository)
  end
end
