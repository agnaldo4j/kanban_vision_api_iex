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

  defp prepare_empty_context(_context) do
    boards_domain = KanbanVisionApi.Agent.Boards.new()
    workflow_domain = KanbanVisionApi.Domain.Workflow.new()
    {:ok, pid} = KanbanVisionApi.Agent.Boards.start_link(boards_domain)
    [
      actor_pid: pid,
      boards: boards_domain,
      workflow: workflow_domain
    ]
  end
end