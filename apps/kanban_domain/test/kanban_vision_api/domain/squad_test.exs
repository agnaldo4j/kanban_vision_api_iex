defmodule KanbanVisionApi.Domain.SquadTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Squad
  alias KanbanVisionApi.Domain.Worker

  describe "new/1" do
    test "creates squad with name and defaults" do
      %Squad{} = squad = Squad.new("Alpha")

      assert squad.name == "Alpha"
      assert is_binary(squad.id)
      assert %Audit{} = squad.audit
      assert squad.workers == []
    end

    test "creates squad with workers" do
      worker = Worker.new("Alice")
      %Squad{} = squad = Squad.new("Alpha", [worker])

      assert squad.workers == [worker]
    end
  end
end
