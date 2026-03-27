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
      {:ok, repository_runtime} = Boards.start_link()
      [repository_runtime: repository_runtime]
    end

    test "implements get_all/1 callback", %{repository_runtime: repository_runtime} do
      assert function_exported?(Boards, :get_all, 1)
      assert is_map(Boards.get_all(repository_runtime))
    end

    test "implements get_by_id/2 callback", %{repository_runtime: repository_runtime} do
      assert function_exported?(Boards, :get_by_id, 2)

      board = Board.new("TestBoard", "sim-123")
      {:ok, created} = Boards.add(repository_runtime, board)

      assert {:ok, ^created} = Boards.get_by_id(repository_runtime, created.id)
      assert {:error, _} = Boards.get_by_id(repository_runtime, "non-existent-id")
    end

    test "implements add/2 callback", %{repository_runtime: repository_runtime} do
      assert function_exported?(Boards, :add, 2)

      board = Board.new("NewBoard", "sim-456")
      assert {:ok, added} = Boards.add(repository_runtime, board)
      assert added.id == board.id
      assert added.name == "NewBoard"

      duplicate = Board.new("NewBoard", "sim-456")
      assert {:error, _} = Boards.add(repository_runtime, duplicate)
    end

    test "implements delete/2 callback", %{repository_runtime: repository_runtime} do
      assert function_exported?(Boards, :delete, 2)

      board = Board.new("ToDelete", "sim-789")
      {:ok, created} = Boards.add(repository_runtime, board)

      assert {:ok, deleted} = Boards.delete(repository_runtime, created.id)
      assert deleted.id == created.id

      assert {:error, _} = Boards.delete(repository_runtime, "non-existent-id")
    end

    test "implements get_all_by_simulation_id/2 callback", %{
      repository_runtime: repository_runtime
    } do
      assert function_exported?(Boards, :get_all_by_simulation_id, 2)

      board = Board.new("SimBoard", "sim-abc")
      {:ok, _} = Boards.add(repository_runtime, board)

      assert {:ok, [_]} = Boards.get_all_by_simulation_id(repository_runtime, "sim-abc")
      assert {:error, _} = Boards.get_all_by_simulation_id(repository_runtime, "non-existent")
    end

    test "satisfies @behaviour BoardRepository" do
      behaviours = Boards.module_info(:attributes)[:behaviour] || []
      assert BoardRepository in behaviours
    end
  end
end
