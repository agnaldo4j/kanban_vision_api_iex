defmodule KanbanVisionApi.Agent.BoardsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Boards

  alias KanbanVisionApi.Agent.Boards
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Workflow

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_boards
    test "should not have any boards by any simulation",
         %{
           actor_pid: pid,
           boards: _boards
         } = _context do
      template = %{}
      assert Boards.get_all(pid) == template
    end

    @tag :domain_boards
    test "should not have any board by simulation_id",
         %{
           actor_pid: pid,
           boards: _boards
         } = _context do
      template = {:error, "Boards by simulation_id: nada not found"}
      assert Boards.get_all_by_simulation_id(pid, "nada") == template
    end

    @tag :domain_boards
    test "should be able to add a new board",
         %{
           actor_pid: pid
         } = _context do
      board = Board.new("Dev Board", "sim-123")
      assert {:ok, ^board} = Boards.add(pid, board)
      assert %{} = Boards.get_all(pid)
    end

    @tag :domain_boards
    test "should not add a board with same name and simulation_id",
         %{
           actor_pid: pid
         } = _context do
      board = Board.new("Dev Board", "sim-123")
      assert {:ok, ^board} = Boards.add(pid, board)

      duplicate = Board.new("Dev Board", "sim-123")
      assert {:error, _msg} = Boards.add(pid, duplicate)
    end
  end

  describe "When start the system with existing boards" do
    setup [:prepare_context_with_boards]

    @tag :domain_boards
    test "should get boards by simulation_id",
         %{
           actor_pid: pid,
           board: board
         } = _context do
      assert {:ok, boards} =
               Boards.get_all_by_simulation_id(pid, board.simulation_id)

      assert length(boards) == 1
    end

    @tag :domain_boards
    test "should allow adding board with a different name for the same simulation_id",
         %{
           actor_pid: pid,
           board: board
         } = _context do
      new_board = Board.new("QA Board", board.simulation_id)
      assert {:ok, ^new_board} = Boards.add(pid, new_board)
      assert 2 = map_size(Boards.get_all(pid))
    end

    @tag :domain_boards
    test "should return error for unknown simulation_id",
         %{
           actor_pid: pid
         } = _context do
      assert {:error, _msg} =
               Boards.get_all_by_simulation_id(pid, "unknown")
    end

    @tag :domain_boards
    test "should get a board by its id",
         %{
           actor_pid: pid,
           board: board
         } = _context do
      assert {:ok, ^board} = Boards.get_by_id(pid, board.id)
    end

    @tag :domain_boards
    test "should return error when getting board by unknown id",
         %{
           actor_pid: pid
         } = _context do
      assert {:error, "Board with id: unknown-id not found"} =
               Boards.get_by_id(pid, "unknown-id")
    end

    @tag :domain_boards
    test "should delete a board by its id",
         %{
           actor_pid: pid,
           board: board
         } = _context do
      assert {:ok, ^board} = Boards.delete(pid, board.id)
      assert %{} == Boards.get_all(pid)
    end

    @tag :domain_boards
    test "should return error when deleting board with unknown id",
         %{
           actor_pid: pid
         } = _context do
      assert {:error, "Board with id: unknown-id not found"} =
               Boards.delete(pid, "unknown-id")
    end
  end

  defp prepare_empty_context(_context) do
    boards_domain = Boards.new()
    workflow_domain = Workflow.new()
    {:ok, pid} = Boards.start_link(boards_domain)

    [
      actor_pid: pid,
      boards: boards_domain,
      workflow: workflow_domain
    ]
  end

  defp prepare_context_with_boards(_context) do
    board = Board.new("Dev Board", "sim-123")
    boards_domain = Boards.new(%{board.id => board})
    {:ok, pid} = Boards.start_link(boards_domain)

    [
      actor_pid: pid,
      boards: boards_domain,
      board: board
    ]
  end
end
