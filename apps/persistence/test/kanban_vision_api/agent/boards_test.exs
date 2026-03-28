defmodule KanbanVisionApi.Agent.BoardsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Boards

  alias KanbanVisionApi.Agent.Boards
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Workflow

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_boards
    test "should not have any boards by any simulation",
         %{
           repository_runtime: repository_runtime,
           boards: _boards
         } = _context do
      template = %{}
      assert Boards.get_all(repository_runtime) == template
    end

    @tag :domain_boards
    test "should not have any board by simulation_id",
         %{
           repository_runtime: repository_runtime,
           boards: _boards
         } = _context do
      assert Boards.get_all_by_simulation_id(repository_runtime, "nada") ==
               ApplicationError.not_found(
                 "Boards by simulation_id: nada not found",
                 %{entity: :board, field: :simulation_id, simulation_id: "nada"}
               )
    end

    @tag :domain_boards
    test "should be able to add a new board",
         %{
           repository_runtime: repository_runtime
         } = _context do
      board = Board.new("Dev Board", "sim-123")
      assert {:ok, ^board} = Boards.add(repository_runtime, board)
      assert %{} = Boards.get_all(repository_runtime)
    end

    @tag :domain_boards
    test "should not add a board with same name and simulation_id",
         %{
           repository_runtime: repository_runtime
         } = _context do
      board = Board.new("Dev Board", "sim-123")
      assert {:ok, ^board} = Boards.add(repository_runtime, board)

      duplicate = Board.new("Dev Board", "sim-123")
      assert {:error, _msg} = Boards.add(repository_runtime, duplicate)
    end
  end

  describe "When start the system with existing boards" do
    setup [:prepare_context_with_boards]

    @tag :domain_boards
    test "should get boards by simulation_id",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      assert {:ok, boards} =
               Boards.get_all_by_simulation_id(repository_runtime, board.simulation_id)

      assert length(boards) == 1
    end

    @tag :domain_boards
    test "should allow adding board with a different name for the same simulation_id",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      new_board = Board.new("QA Board", board.simulation_id)
      assert {:ok, ^new_board} = Boards.add(repository_runtime, new_board)
      assert 2 = map_size(Boards.get_all(repository_runtime))
    end

    @tag :domain_boards
    test "should update an existing board",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      renamed_board = Board.rename(board, "Renamed Board")

      assert {:ok, updated_board} = Boards.update(repository_runtime, renamed_board)
      assert updated_board.name == "Renamed Board"
    end

    @tag :domain_boards
    test "should not update a board to a duplicate name in the same simulation",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      other_board = Board.new("QA Board", board.simulation_id)
      {:ok, other_board} = Boards.add(repository_runtime, other_board)

      conflicting_board = Board.rename(other_board, board.name)

      assert {:error, _} = Boards.update(repository_runtime, conflicting_board)
    end

    @tag :domain_boards
    test "should return error when updating board with unknown id",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      unknown_board = %{board | id: "unknown-id", name: "Ghost Board"}

      assert Boards.update(repository_runtime, unknown_board) ==
               ApplicationError.not_found(
                 "Board with id: unknown-id not found",
                 %{entity: :board, id: "unknown-id"}
               )
    end

    @tag :domain_boards
    test "should return error for unknown simulation_id",
         %{
           repository_runtime: repository_runtime
         } = _context do
      assert {:error, _msg} =
               Boards.get_all_by_simulation_id(repository_runtime, "unknown")
    end

    @tag :domain_boards
    test "should get a board by its id",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      assert {:ok, ^board} = Boards.get_by_id(repository_runtime, board.id)
    end

    @tag :domain_boards
    test "should return error when getting board by unknown id",
         %{
           repository_runtime: repository_runtime
         } = _context do
      assert Boards.get_by_id(repository_runtime, "unknown-id") ==
               ApplicationError.not_found(
                 "Board with id: unknown-id not found",
                 %{entity: :board, id: "unknown-id"}
               )
    end

    @tag :domain_boards
    test "should delete a board by its id",
         %{
           repository_runtime: repository_runtime,
           board: board
         } = _context do
      assert {:ok, ^board} = Boards.delete(repository_runtime, board.id)
      assert %{} == Boards.get_all(repository_runtime)
    end

    @tag :domain_boards
    test "should return error when deleting board with unknown id",
         %{
           repository_runtime: repository_runtime
         } = _context do
      assert Boards.delete(repository_runtime, "unknown-id") ==
               ApplicationError.not_found(
                 "Board with id: unknown-id not found",
                 %{entity: :board, id: "unknown-id"}
               )
    end
  end

  defp prepare_empty_context(_context) do
    boards_domain = Boards.new()
    workflow_domain = Workflow.new()
    {:ok, repository_pid} = Boards.start_link(boards_domain)
    repository_runtime = Boards.runtime(repository_pid)

    [
      repository_runtime: repository_runtime,
      boards: boards_domain,
      workflow: workflow_domain
    ]
  end

  defp prepare_context_with_boards(_context) do
    board = Board.new("Dev Board", "sim-123")
    boards_domain = Boards.new(%{board.id => board})
    {:ok, repository_pid} = Boards.start_link(boards_domain)
    repository_runtime = Boards.runtime(repository_pid)

    [
      repository_runtime: repository_runtime,
      boards: boards_domain,
      board: board
    ]
  end
end
