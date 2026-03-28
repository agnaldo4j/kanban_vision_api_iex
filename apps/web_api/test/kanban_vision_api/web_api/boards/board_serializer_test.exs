defmodule KanbanVisionApi.WebApi.Boards.BoardSerializerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.WebApi.Boards.BoardSerializer

  setup do
    board = Board.new("Dev Board", "sim-123")
    %{board: board}
  end

  describe "serialize/1" do
    test "returns a map with all expected fields", %{board: board} do
      result = BoardSerializer.serialize(board)

      assert result.id == board.id
      assert result.name == "Dev Board"
      assert result.simulation_id == "sim-123"
      assert is_binary(result.created_at)
      assert is_binary(result.updated_at)
    end

    test "formats dates as ISO8601", %{board: board} do
      result = BoardSerializer.serialize(board)

      assert String.contains?(result.created_at, "T")
      assert String.contains?(result.updated_at, "T")
    end
  end

  describe "serialize_many_list/1" do
    test "converts a list of boards", %{board: board} do
      result = BoardSerializer.serialize_many_list([board])

      assert length(result) == 1
      assert hd(result).name == "Dev Board"
    end

    test "returns empty list for empty list" do
      assert BoardSerializer.serialize_many_list([]) == []
    end
  end

  describe "serialize_detail/1" do
    test "returns workflow and workers in a detail representation", %{board: board} do
      step = Step.new("In Progress", 0, [], Ability.new("Coding"))
      worker_a = Worker.new("Alice", [Ability.new("Coding"), Ability.new("Review")], "worker-a")
      worker_b = Worker.new("Bob", [Ability.new("Testing")], "worker-b")

      detailed_board = %{
        board
        | workflow: %{board.workflow | steps: [step]},
          workers: %{worker_b.id => worker_b, worker_a.id => worker_a}
      }

      result = BoardSerializer.serialize_detail(detailed_board)

      assert result.name == "Dev Board"
      assert Enum.map(result.workers, & &1.id) == ["worker-a", "worker-b"]
      assert Enum.map(result.workers, & &1.name) == ["Alice", "Bob"]
      assert [%{name: "In Progress", order: 0}] = result.workflow.steps
      assert hd(result.workflow.steps).required_ability.name == "Coding"
    end
  end
end
