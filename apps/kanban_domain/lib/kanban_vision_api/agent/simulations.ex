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
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_all(id) do
    Agent.get(id, fn state -> state.simulations_by_organization end)
  end

  def add(pid, new_simulation = %KanbanVisionApi.Domain.Simulation{}) do
    result = get_by_organization_id_and_simulation_name(
      pid,
      new_simulation.organization_id,
      new_simulation.name)

    Agent.update(pid, fn state ->

      map_of_simulations = Map.get(state.simulations_by_organization, new_simulation.organization_id, %{})
      new_simulations_by_organization = Map.put_new(map_of_simulations, new_simulation.id, new_simulation)

      case result do
        {:error, _} -> put_in(
                         state.simulations_by_organization,
                         Map.put(
                           state.simulations_by_organization,
                           new_simulation.organization_id, new_simulations_by_organization
                         )
                       )
        {:ok, _} -> state
      end
    end)

    case result do
      {:error, _} -> {:ok, new_simulation}
      {:ok, _} -> {
                    :error,
                    """
                    Simulation with organization_id: #{new_simulation.organization_id}
                    name: #{new_simulation.name} already exist
                    """
                  }
    end
  end

  defp get_by_organization_id_and_simulation_name(pid, organization_id, simulation_name) do
    result = get_by_organization_id(pid, organization_id)

    case result do
      {:error, _} -> result
      {:ok, map_of_simulations} ->
        case Map.values(map_of_simulations) do
          [] -> {:error, "Simulation with organization id: #{organization_id} not found"}
          list_of_simulations ->
            case Enum.find(
                   list_of_simulations,
                   fn simulation -> simulation.name == simulation_name end
                 ) do
              nil -> {:error, "Simulation with name: #{simulation_name} not found"}
              simulation -> {:ok, simulation}
            end
        end
    end
  end

  defp get_by_organization_id(pid, organization_id) do
    Agent.get(pid, fn state ->
      case Map.get(state.simulations_by_organization, organization_id) do
        nil -> {:error, "Simulation with organization id: #{organization_id} not found"}
        map_of_simulations -> {:ok, map_of_simulations}
      end
    end)
  end
end
