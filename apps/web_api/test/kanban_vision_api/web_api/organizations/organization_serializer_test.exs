defmodule KanbanVisionApi.WebApi.Organizations.OrganizationSerializerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Squad
  alias KanbanVisionApi.Domain.Tribe
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.WebApi.Organizations.OrganizationSerializer

  setup do
    org = Organization.new("Acme Corp")
    %{org: org}
  end

  describe "serialize/1" do
    test "returns a map with all expected fields", %{org: org} do
      result = OrganizationSerializer.serialize(org)

      assert result.id == org.id
      assert result.name == "Acme Corp"
      assert is_list(result.tribes)
      assert is_binary(result.created_at)
      assert is_binary(result.updated_at)
    end

    test "formats dates as ISO8601", %{org: org} do
      result = OrganizationSerializer.serialize(org)

      assert String.contains?(result.created_at, "T")
      assert String.contains?(result.updated_at, "T")
    end

    test "serializes tribes as JSON-safe maps (not raw structs)" do
      ability = Ability.new("Elixir")
      worker = Worker.new("Alice", [ability])
      squad = Squad.new("Squad Alpha", [worker])
      tribe = Tribe.new("Engineering", [squad])
      org = Organization.new("Acme Corp", [tribe])

      result = OrganizationSerializer.serialize(org)

      assert Jason.encode!(result) =~ "Engineering"

      [tribe_map] = result.tribes
      assert tribe_map.name == "Engineering"

      [squad_map] = tribe_map.squads
      assert squad_map.name == "Squad Alpha"

      [worker_map] = squad_map.workers
      assert worker_map.name == "Alice"

      [ability_map] = worker_map.abilities
      assert ability_map.name == "Elixir"
    end

    test "produces JSON-encodable output even with empty tribes", %{org: org} do
      assert Jason.encode!(OrganizationSerializer.serialize(org)) =~ "Acme Corp"
    end
  end

  describe "serialize_many/1" do
    test "converts a map of orgs to a list", %{org: org} do
      orgs_map = %{org.id => org}
      result = OrganizationSerializer.serialize_many(orgs_map)

      assert length(result) == 1
      assert hd(result).name == "Acme Corp"
    end

    test "returns empty list for empty map" do
      assert OrganizationSerializer.serialize_many(%{}) == []
    end
  end

  describe "serialize_many_list/1" do
    test "converts a list of orgs", %{org: org} do
      result = OrganizationSerializer.serialize_many_list([org])

      assert length(result) == 1
      assert hd(result).name == "Acme Corp"
    end

    test "returns empty list for empty list" do
      assert OrganizationSerializer.serialize_many_list([]) == []
    end
  end
end
