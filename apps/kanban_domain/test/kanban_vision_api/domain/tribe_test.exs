defmodule KanbanVisionApi.Domain.TribeTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Squad
  alias KanbanVisionApi.Domain.Tribe

  describe "new/1" do
    test "creates tribe with name and defaults" do
      %Tribe{} = tribe = Tribe.new("Platform")

      assert tribe.name == "Platform"
      assert is_binary(tribe.id)
      assert %Audit{} = tribe.audit
      assert tribe.squads == []
    end

    test "creates tribe with squads" do
      squad = Squad.new("Alpha")
      %Tribe{} = tribe = Tribe.new("Platform", [squad])

      assert tribe.squads == [squad]
    end
  end
end
