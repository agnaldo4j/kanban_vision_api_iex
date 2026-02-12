defmodule KanbanVisionApi.Usecase.Simulation do
  @moduledoc false

  use GenServer

  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid), do: GenServer.call(pid, :get_all)

  def add(pid, %CreateSimulationCommand{} = cmd) do
    simulation =
      KanbanVisionApi.Domain.Simulation.new(cmd.name, cmd.description, cmd.organization_id)

    GenServer.call(pid, {:add, simulation})
  end

  def get_by_org_and_name(pid, %GetSimulationByOrgAndNameQuery{} = query) do
    GenServer.call(pid, {:get_by_org_and_name, query.organization_id, query.name})
  end

  # Server — delegates to Agent

  @impl true
  def init(_opts) do
    {:ok, agent_pid} = KanbanVisionApi.Agent.Simulations.start_link()
    {:ok, %{agent_pid: agent_pid}}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    result = KanbanVisionApi.Agent.Simulations.get_all(state.agent_pid)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:add, simulation}, _from, state) do
    result = KanbanVisionApi.Agent.Simulations.add(state.agent_pid, simulation)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_org_and_name, organization_id, name}, _from, state) do
    result =
      KanbanVisionApi.Agent.Simulations.get_by_organization_id_and_simulation_name(
        state.agent_pid,
        organization_id,
        name
      )

    {:reply, result, state}
  end
end
