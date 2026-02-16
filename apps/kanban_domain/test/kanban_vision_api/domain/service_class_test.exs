defmodule KanbanVisionApi.Domain.ServiceClassTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.ServiceClass

  describe "new/1" do
    test "creates service class with name and defaults" do
      %ServiceClass{} = sc = ServiceClass.new("Expedite")

      assert sc.name == "Expedite"
      assert is_binary(sc.id)
      assert %Audit{} = sc.audit
    end

    test "generates unique UUIDs" do
      sc1 = ServiceClass.new("Standard")
      sc2 = ServiceClass.new("Expedite")

      refute sc1.id == sc2.id
    end
  end
end
