defmodule KanbanVisionApi.Agent.BoardsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Boards

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_boards
    test "should not have any boards by a simulation", %{
           actor_pid: _pid,
           boards: _boards
         } = _context do

      assert nil == nil
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
end