defmodule KanbanVisionApi.Agent.BoardsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Boards

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_boards
    test "should not have any boards by any simulation", %{
           actor_pid: pid,
           boards: _boards
         } = _context do

      template = %{}
      assert KanbanVisionApi.Agent.Boards.get_all(pid) == template
    end

    @tag :domain_boards
    test "should not have any board by simulation_id", %{
           actor_pid: pid,
           boards: _boards
         } = _context do

      template = {:error, "Boards by simulation_id: nada not found"}
      assert KanbanVisionApi.Agent.Boards.get_all_by_simulation_id(pid, "nada") == template
    end
  end

  describe "When start the system with board data" do
    setup [:prepare_context_with_data]

    @tag :domain_boards
    test "should return boards by simulation_id", %{
      actor_pid: pid,
      board: board
    } do
      assert KanbanVisionApi.Agent.Boards.get_all_by_simulation_id(pid, board.simulation_id) ==
               {:ok, [board]}
    end

    @tag :domain_boards
    test "should not allow duplicate board name in the same simulation", %{
      actor_pid: pid,
      board: board
    } do
      assert KanbanVisionApi.Agent.Boards.add(pid, board) ==
               {:error,
                """
                Board with name: #{board.name}
                from simulation_id: #{board.simulation_id} already exist
                """}
    end

    @tag :domain_boards
    test "should allow same board name in different simulations", %{
      actor_pid: pid,
      board: board
    } do
      new_board = KanbanVisionApi.Domain.Board.new(board.name, "another-simulation")

      assert KanbanVisionApi.Agent.Boards.add(pid, new_board) == {:ok, new_board}
    end
  end

  defp prepare_empty_context(_context) do
    boards_domain = KanbanVisionApi.Agent.Boards.new()
    workflow_domain = KanbanVisionApi.Domain.Workflow.new("ExampleWorkflow")
    {:ok, pid} = KanbanVisionApi.Agent.Boards.start_link(boards_domain)
    [
      actor_pid: pid,
      boards: boards_domain,
      workflow: workflow_domain
    ]
  end

  defp prepare_context_with_data(_context) do
    board = KanbanVisionApi.Domain.Board.new("Main board", "simulation-1")
    boards_domain = KanbanVisionApi.Agent.Boards.new(%{board.id => board})
    {:ok, pid} = KanbanVisionApi.Agent.Boards.start_link(boards_domain)

    [
      actor_pid: pid,
      boards: boards_domain,
      board: board
    ]
  end
end
