defmodule KanbanVisionApi.Domain.Organization do
  @moduledoc false

  use Agent

  defstruct [:id, :audit, :name, :simulations]

  @type t :: %KanbanVisionApi.Domain.Organization {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t,
               simulations: Map.t
             }

  def new(name, simulations \\ %{}, id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new) do
    %KanbanVisionApi.Domain.Organization{
      id: id,
      audit: audit,
      name: name,
      simulations: simulations
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Organization.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Organization{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

  def add_simulation(pid, new_simulation = %KanbanVisionApi.Domain.Simulation{}) do
    Agent.update(pid, fn state ->
      case internal_get_by_name(state.simulations, new_simulation.name) do
        {:error, _} ->
          put_in(
            state.simulations,
            Map.put(state.simulations, new_simulation.id, new_simulation)
          )
        {:ok, _} ->
          state
      end
    end)
  end

  def get_simulation_by_name(pid, simulation_name) do
    Agent.get(pid, fn state ->
      internal_get_by_name(state.simulations, simulation_name)
    end)
  end

  defp internal_get_by_name(state, domain_name) do
    Map.values(state)
    |> Enum.filter(fn domain -> domain.name == domain_name end)
    |> prepare_by_name_result(domain_name)
  end

  defp prepare_by_name_result(result_list, domain_name) do
    case result_list do
      values when values == [] -> {:error, "Simulation with name: #{domain_name} not found"}
      values -> {:ok, values}
    end
  end
end
