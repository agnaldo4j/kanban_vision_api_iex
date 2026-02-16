defmodule KanbanVisionApi.Agent.Simulations do
  @moduledoc false

  use Agent

  @behaviour KanbanVisionApi.Domain.Ports.SimulationRepository

  defstruct [:id, :simulations_by_organization]

  @type t :: %__MODULE__{
          id: String.t(),
          simulations_by_organization: map()
        }

  def new(simulations_by_organization \\ %{}, id \\ UUID.uuid4()) do
    %__MODULE__{
      id: id,
      simulations_by_organization: simulations_by_organization
    }
  end

  # Client

  @spec start_link(t()) :: Agent.on_start()
  def start_link(default \\ __MODULE__.new()) do
    Agent.start_link(fn -> default end)
  end

  def get_all(pid) do
    Agent.get(pid, fn state -> state.simulations_by_organization end)
  end

  def add(pid, %KanbanVisionApi.Domain.Simulation{} = new_simulation) do
    Agent.get_and_update(pid, fn state ->
      result =
        internal_find_by_org_and_name(
          state,
          new_simulation.organization_id,
          new_simulation.name
        )

      case result do
        {:error, _} ->
          map_of_simulations =
            Map.get(
              state.simulations_by_organization,
              new_simulation.organization_id,
              %{}
            )

          new_simulations_map =
            Map.put_new(
              map_of_simulations,
              new_simulation.id,
              new_simulation
            )

          new_state =
            put_in(
              state.simulations_by_organization,
              Map.put(
                state.simulations_by_organization,
                new_simulation.organization_id,
                new_simulations_map
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

  def delete(pid, simulation_id) do
    Agent.get_and_update(pid, fn state ->
      case internal_find_by_id(state, simulation_id) do
        {:ok, simulation} ->
          new_state = internal_remove_simulation(state, simulation, simulation_id)
          {{:ok, simulation}, new_state}

        {:error, _} = error ->
          {error, state}
      end
    end)
  end

  def get_by_organization_id_and_simulation_name(pid, organization_id, simulation_name) do
    Agent.get(pid, fn state ->
      internal_find_by_org_and_name(state, organization_id, simulation_name)
    end)
  end

  defp internal_remove_simulation(state, simulation, simulation_id) do
    org_sims = Map.get(state.simulations_by_organization, simulation.organization_id, %{})
    updated_org_sims = Map.delete(org_sims, simulation_id)

    updated_by_org =
      if map_size(updated_org_sims) == 0 do
        Map.delete(state.simulations_by_organization, simulation.organization_id)
      else
        Map.put(state.simulations_by_organization, simulation.organization_id, updated_org_sims)
      end

    put_in(state.simulations_by_organization, updated_by_org)
  end

  defp internal_find_by_id(state, simulation_id) do
    result =
      state.simulations_by_organization
      |> Map.values()
      |> Enum.flat_map(&Map.values/1)
      |> Enum.find(fn sim -> sim.id == simulation_id end)

    case result do
      nil -> {:error, "Simulation with id: #{simulation_id} not found"}
      simulation -> {:ok, simulation}
    end
  end

  defp internal_find_by_org_and_name(state, organization_id, simulation_name) do
    case Map.get(state.simulations_by_organization, organization_id) do
      nil ->
        {:error, "Simulation with organization id: #{organization_id} not found"}

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
