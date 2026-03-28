defmodule KanbanVisionApi.WebApi.Boards.BoardSerializerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Board
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
end
