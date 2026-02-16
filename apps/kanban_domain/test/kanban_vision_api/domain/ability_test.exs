defmodule KanbanVisionApi.Domain.AbilityTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit

  describe "new/1" do
    test "creates ability with name and defaults" do
      %Ability{} = ability = Ability.new("Coding")

      assert ability.name == "Coding"
      assert is_binary(ability.id)
      assert %Audit{} = ability.audit
    end

    test "generates unique UUIDs" do
      a1 = Ability.new("Coding")
      a2 = Ability.new("Testing")

      refute a1.id == a2.id
    end
  end
end
