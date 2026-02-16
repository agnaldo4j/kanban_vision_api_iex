defmodule KanbanVisionApi.Agent.BoardRepositoryContractTest do
  @moduledoc """
  Integration test verifying that Agent.Boards correctly implements
  the BoardRepository port contract.
  """
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Agent.Boards
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.BoardRepository

  @moduletag :integration

  describe "BoardRepository contract" do
    setup do
      {:ok, pid} = Boards.start_link()
      [repository_pid: pid]
    end

    test "implements get_all/1 callback", %{repository_pid: pid} do
      assert function_exported?(Boards, :get_all, 1)
      assert is_map(Boards.get_all(pid))
    end

    test "implements get_by_id/2 callback", %{repository_pid: pid} do
      assert function_exported?(Boards, :get_by_id, 2)

      board = Board.new("TestBoard", "sim-123")
      {:ok, created} = Boards.add(pid, board)

      assert {:ok, ^created} = Boards.get_by_id(pid, created.id)
      assert {:error, _} = Boards.get_by_id(pid, "non-existent-id")
    end

    test "implements add/2 callback", %{repository_pid: pid} do
      assert function_exported?(Boards, :add, 2)

      board = Board.new("NewBoard", "sim-456")
      assert {:ok, added} = Boards.add(pid, board)
      assert added.id == board.id
      assert added.name == "NewBoard"

      duplicate = Board.new("NewBoard", "sim-456")
      assert {:error, _} = Boards.add(pid, duplicate)
    end

    test "implements delete/2 callback", %{repository_pid: pid} do
      assert function_exported?(Boards, :delete, 2)

      board = Board.new("ToDelete", "sim-789")
      {:ok, created} = Boards.add(pid, board)

      assert {:ok, deleted} = Boards.delete(pid, created.id)
      assert deleted.id == created.id

      assert {:error, _} = Boards.delete(pid, "non-existent-id")
    end

    test "implements get_all_by_simulation_id/2 callback", %{repository_pid: pid} do
      assert function_exported?(Boards, :get_all_by_simulation_id, 2)

      board = Board.new("SimBoard", "sim-abc")
      {:ok, _} = Boards.add(pid, board)

      assert {:ok, [_]} = Boards.get_all_by_simulation_id(pid, "sim-abc")
      assert {:error, _} = Boards.get_all_by_simulation_id(pid, "non-existent")
    end

    test "satisfies @behaviour BoardRepository" do
      behaviours = Boards.module_info(:attributes)[:behaviour] || []
      assert BoardRepository in behaviours
    end
  end
end
