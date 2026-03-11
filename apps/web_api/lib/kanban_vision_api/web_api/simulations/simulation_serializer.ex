defmodule KanbanVisionApi.WebApi.Simulations.SimulationSerializer do
  @moduledoc """
  Serializer: converts Domain.Simulation structs to JSON-safe maps.

  Pure functions — no side effects. Formats DateTime fields as ISO8601.
  """

  alias KanbanVisionApi.Domain.Simulation

  @spec serialize(Simulation.t()) :: map()
  def serialize(%Simulation{} = sim) do
    %{
      id: sim.id,
      name: sim.name,
      description: sim.description,
      organization_id: sim.organization_id,
      created_at: DateTime.to_iso8601(sim.audit.created),
      updated_at: DateTime.to_iso8601(sim.audit.updated)
    }
  end

  @spec serialize_many(map()) :: list(map())
  def serialize_many(simulations) when is_map(simulations) do
    simulations
    |> Map.values()
    |> Enum.flat_map(fn org_sims -> Map.values(org_sims) end)
    |> Enum.map(&serialize/1)
  end

  @spec serialize_many_list(list()) :: list(map())
  def serialize_many_list(simulations) when is_list(simulations) do
    Enum.map(simulations, &serialize/1)
  end
end
