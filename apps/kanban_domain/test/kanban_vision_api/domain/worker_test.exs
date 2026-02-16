defmodule KanbanVisionApi.Domain.WorkerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Worker

  describe "new/1" do
    test "creates worker with name and defaults" do
      %Worker{} = worker = Worker.new("Alice")

      assert worker.name == "Alice"
      assert is_binary(worker.id)
      assert %Audit{} = worker.audit
      assert worker.abilities == []
    end

    test "creates worker with abilities" do
      ability = Ability.new("Coding")
      %Worker{} = worker = Worker.new("Alice", [ability])

      assert worker.abilities == [ability]
    end
  end
end
