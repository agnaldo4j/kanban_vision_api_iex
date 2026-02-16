defmodule KanbanVisionApi.Domain.OrganizationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Tribe

  describe "new/1" do
    test "creates organization with name and defaults" do
      %Organization{} = org = Organization.new("MyOrg")

      assert org.name == "MyOrg"
      assert is_binary(org.id)
      assert %Audit{} = org.audit
      assert org.tribes == []
    end

    test "creates organization with tribes" do
      tribe = Tribe.new("Engineering")
      %Organization{} = org = Organization.new("MyOrg", [tribe])

      assert org.tribes == [tribe]
    end

    test "generates unique UUIDs" do
      org1 = Organization.new("Org1")
      org2 = Organization.new("Org2")

      refute org1.id == org2.id
    end
  end
end
