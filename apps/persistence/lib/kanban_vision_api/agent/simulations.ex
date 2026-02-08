defmodule KanbanVisionApi.Agent.Simulations do
  @moduledoc false

  use Agent

  defstruct [:id, :simulations_by_organization]

  @type t :: %KanbanVisionApi.Agent.Simulations {
               id: String.t,
               simulations_by_organization: Map.t
             }

  def new(simulations_by_organization \\ %{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Agent.Simulations{
      id: id,
      simulations_by_organization: simulations_by_organization
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Agent.Simulations.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Agent.Simulations.new) do
    Agent.start_link(fn -> default end)
  end

  def get_all(pid) do
    Agent.get(pid, fn state -> state.simulations_by_organization end)
  end

  def add(pid, new_simulation = %KanbanVisionApi.Domain.Simulation{}) do
    Agent.get_and_update(pid, fn state ->
      result = internal_find_by_org_and_name(
        state, new_simulation.organization_id, new_simulation.name
      )

      case result do
        {:error, _} ->
          map_of_simulations = Map.get(
            state.simulations_by_organization,
            new_simulation.organization_id, %{}
          )

          new_simulations_map = Map.put_new(
            map_of_simulations,
            new_simulation.id, new_simulation
          )

          new_state = put_in(
            state.simulations_by_organization,
            Map.put(
              state.simulations_by_organization,
              new_simulation.organization_id, new_simulations_map
            )
          )

          {{:ok, new_simulation}, new_state}

        {:ok, _} ->
          {{:error,
            """
            Simulation with organization_id: #{new_simulation.organization_id}
            name: #{new_simulation.name} already exist
            """}, state}
      end
    end)
  end

  def get_by_organization_id_and_simulation_name(pid, organization_id, simulation_name) do
    Agent.get(pid, fn state ->
      internal_find_by_org_and_name(state, organization_id, simulation_name)
    end)
  end

  defp internal_find_by_org_and_name(state, organization_id, simulation_name) do
    case Map.get(state.simulations_by_organization, organization_id) do
      nil -> {:error, "Simulation with organization id: #{organization_id} not found"}
      map_of_simulations ->
        find_by_simulation_name(map_of_simulations, organization_id, simulation_name)
    end
  end

  defp find_by_simulation_name(map_of_simulations, organization_id, simulation_name) do
    case Map.values(map_of_simulations) do
      [] -> {:error, "Simulation with organization id: #{organization_id} not found"}
      list_of_simulations -> find_by_simulation_name(list_of_simulations, simulation_name)
    end
  end

  defp find_by_simulation_name(list_of_simulations, simulation_name) do
    case Enum.find(
           list_of_simulations,
           fn simulation -> simulation.name == simulation_name end
         ) do
      nil -> {:error, "Simulation with name: #{simulation_name} not found"}
      simulation -> {:ok, simulation}
    end
  end
end