defmodule KanbanVisionApi.WebApi.Organizations.OrganizationSerializer do
  @moduledoc """
  Serializer: converts Domain.Organization structs to JSON-safe maps.

  Pure functions — no side effects. Formats DateTime fields as ISO8601.
  """

  alias KanbanVisionApi.Domain.Organization

  @spec serialize(Organization.t()) :: map()
  def serialize(%Organization{} = org) do
    %{
      id: org.id,
      name: org.name,
      tribes: org.tribes,
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
end
