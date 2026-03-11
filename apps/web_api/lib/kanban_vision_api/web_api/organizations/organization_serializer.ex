defmodule KanbanVisionApi.WebApi.Organizations.OrganizationSerializer do
  @moduledoc """
  Serializer: converts Domain.Organization structs to JSON-safe maps.

  Pure functions — no side effects. Formats DateTime fields as ISO8601.
  Recursively serializes the full hierarchy: Organization → Tribe → Squad → Worker → Ability.
  """

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Squad
  alias KanbanVisionApi.Domain.Tribe
  alias KanbanVisionApi.Domain.Worker

  @spec serialize(Organization.t()) :: map()
  def serialize(%Organization{} = org) do
    %{
      id: org.id,
      name: org.name,
      tribes: Enum.map(org.tribes, &serialize_tribe/1),
      created_at: DateTime.to_iso8601(org.audit.created),
      updated_at: DateTime.to_iso8601(org.audit.updated)
    }
  end

  @spec serialize_many(map()) :: list(map())
  def serialize_many(organizations) when is_map(organizations) do
    organizations
    |> Map.values()
    |> Enum.map(&serialize/1)
  end

  @spec serialize_many_list(list()) :: list(map())
  def serialize_many_list(organizations) when is_list(organizations) do
    Enum.map(organizations, &serialize/1)
  end

  defp serialize_tribe(%Tribe{} = tribe) do
    %{
      id: tribe.id,
      name: tribe.name,
      squads: Enum.map(tribe.squads, &serialize_squad/1)
    }
  end

  defp serialize_squad(%Squad{} = squad) do
    %{
      id: squad.id,
      name: squad.name,
      workers: Enum.map(squad.workers, &serialize_worker/1)
    }
  end

  defp serialize_worker(%Worker{} = worker) do
    %{
      id: worker.id,
      name: worker.name,
      abilities: Enum.map(worker.abilities, &serialize_ability/1)
    }
  end

  defp serialize_ability(%Ability{} = ability) do
    %{
      id: ability.id,
      name: ability.name
    }
  end
end
