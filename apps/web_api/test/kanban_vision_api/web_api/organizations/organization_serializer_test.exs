defmodule KanbanVisionApi.WebApi.Organizations.OrganizationSerializerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Organization
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
