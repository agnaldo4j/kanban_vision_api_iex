defmodule KanbanVisionApi.Usecase.BoardTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Usecase.Board
  alias KanbanVisionApi.Usecase.Board.AddBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.AllocateBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.RenameBoardCommand
  alias KanbanVisionApi.Usecase.Board.ReorderBoardWorkflowStepCommand

  describe "When start with empty state" do
    setup [:start_usecase]

    test "should return empty map", %{pid: pid} do
      assert Board.get_all(pid) == {:ok, %{}}
    end

    test "should add a new board via command", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      assert {:ok, board} = Board.add(pid, cmd)
      assert board.name == "Dev Board"
      assert board.simulation_id == "sim-123"
    end

    test "should find board by id via query", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, query} = GetBoardByIdQuery.new(board.id)
      assert {:ok, ^board} = Board.get_by_id(pid, query)
    end

    test "should find boards by simulation id via query", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, query} = GetBoardsBySimulationIdQuery.new("sim-123")
      assert {:ok, [^board]} = Board.get_by_simulation_id(pid, query)
    end

    test "should delete a board via command", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, delete_cmd} = DeleteBoardCommand.new(board.id)
      assert {:ok, ^board} = Board.delete(pid, delete_cmd)
    end

    test "should return error for non-existent id", %{pid: pid} do
      {:ok, query} = GetBoardByIdQuery.new("invalid")

      assert Board.get_by_id(pid, query) ==
               ApplicationError.not_found(
                 "Board with id: invalid not found",
                 %{entity: :board, id: "invalid"}
               )
    end

    test "should return error for non-existent simulation id", %{pid: pid} do
      {:ok, query} = GetBoardsBySimulationIdQuery.new("sim-999")

      assert Board.get_by_simulation_id(pid, query) ==
               ApplicationError.not_found(
                 "Boards by simulation_id: sim-999 not found",
                 %{entity: :board, field: :simulation_id, simulation_id: "sim-999"}
               )
    end

    test "should not allow duplicate board names in the same simulation", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, _} = Board.add(pid, cmd)

      {:ok, duplicate_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")

      assert Board.add(pid, duplicate_cmd) ==
               ApplicationError.conflict(
                 "Board with name: Dev Board from simulation_id: sim-123 already exists",
                 %{entity: :board, field: :name, name: "Dev Board", simulation_id: "sim-123"}
               )
    end

    test "should reject invalid command", %{pid: _pid} do
      assert {:error, :invalid_name} = CreateBoardCommand.new("", "sim-123")
      assert {:error, :invalid_simulation_id} = CreateBoardCommand.new("Dev Board", "")

      assert {:error, :invalid_order} =
               AddBoardWorkflowStepCommand.new("board-1", "Dev", -1, "Coding")

      assert {:error, :invalid_abilities} =
               AllocateBoardWorkerCommand.new("board-1", "Alice", [1])

      assert {:error, :invalid_id} = GetBoardByIdQuery.new("")
      assert {:error, :invalid_simulation_id} = GetBoardsBySimulationIdQuery.new("")
    end

    test "should rename a board", %{pid: pid} do
      {:ok, create_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, create_cmd)

      {:ok, rename_cmd} = RenameBoardCommand.new(board.id, "Renamed Board")
      assert {:ok, renamed_board} = Board.rename(pid, rename_cmd)
      assert renamed_board.name == "Renamed Board"
    end

    test "should add a workflow step to a board", %{pid: pid} do
      {:ok, create_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, create_cmd)

      {:ok, add_step_cmd} = AddBoardWorkflowStepCommand.new(board.id, "In Progress", 0, "Coding")
      assert {:ok, updated_board} = Board.add_workflow_step(pid, add_step_cmd)
      assert [%{name: "In Progress", order: 0}] = updated_board.workflow.steps
    end

    test "should remove a workflow step from a board", %{pid: pid} do
      {:ok, create_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, create_cmd)
      {:ok, add_step_cmd} = AddBoardWorkflowStepCommand.new(board.id, "In Progress", 0, "Coding")
      {:ok, board_with_step} = Board.add_workflow_step(pid, add_step_cmd)
      step = hd(board_with_step.workflow.steps)

      {:ok, remove_step_cmd} = RemoveBoardWorkflowStepCommand.new(board.id, step.id)
      assert {:ok, updated_board} = Board.remove_workflow_step(pid, remove_step_cmd)
      assert updated_board.workflow.steps == []
    end

    test "should reorder a workflow step in a board", %{pid: pid} do
      {:ok, create_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, create_cmd)
      {:ok, first_step_cmd} = AddBoardWorkflowStepCommand.new(board.id, "Backlog", 0, "Analysis")
      {:ok, _} = Board.add_workflow_step(pid, first_step_cmd)
      {:ok, second_step_cmd} = AddBoardWorkflowStepCommand.new(board.id, "Done", 1, "Review")
      {:ok, board_with_steps} = Board.add_workflow_step(pid, second_step_cmd)
      step = Enum.find(board_with_steps.workflow.steps, &(&1.name == "Done"))

      {:ok, reorder_cmd} = ReorderBoardWorkflowStepCommand.new(board.id, step.id, 0)
      assert {:ok, updated_board} = Board.reorder_workflow_step(pid, reorder_cmd)
      assert Enum.map(updated_board.workflow.steps, & &1.name) == ["Done", "Backlog"]
    end

    test "should allocate and remove a worker from a board", %{pid: pid} do
      {:ok, create_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, create_cmd)

      {:ok, allocate_cmd} =
        AllocateBoardWorkerCommand.new(board.id, "Alice", ["Coding", "Review"])

      assert {:ok, board_with_worker} = Board.allocate_worker(pid, allocate_cmd)
      [%{id: worker_id, name: "Alice"}] = Map.values(board_with_worker.workers)

      {:ok, remove_cmd} = RemoveBoardWorkerCommand.new(board.id, worker_id)
      assert {:ok, updated_board} = Board.remove_worker(pid, remove_cmd)
      assert updated_board.workers == %{}
    end
  end

  defp start_usecase(_context) do
    {:ok, pid} = Board.start_link()
    [pid: pid]
  end
end
