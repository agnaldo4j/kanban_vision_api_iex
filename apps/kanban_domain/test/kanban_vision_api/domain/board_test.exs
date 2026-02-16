defmodule KanbanVisionApi.Domain.BoardTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Board

  describe "new/0" do
    test "creates board with defaults" do
      %Board{} = board = Board.new()

      assert board.name == "Default"
      assert board.simulation_id == "Default Simulation ID"
      assert is_binary(board.id)
      assert %Audit{} = board.audit
      assert board.workers == %{}
    end
  end

  describe "new/2" do
    test "creates board with name and simulation_id" do
      %Board{} = board = Board.new("Dev Board", "sim-123")

      assert board.name == "Dev Board"
      assert board.simulation_id == "sim-123"
    end

    test "generates unique UUIDs" do
      b1 = Board.new("Board1", "sim-1")
      b2 = Board.new("Board2", "sim-1")

      refute b1.id == b2.id
    end
  end
end
