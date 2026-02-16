defmodule KanbanVisionApi.Domain.BoardTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.Domain.Workflow

  describe "new/0" do
    test "creates board with all defaults" do
      %Board{} = board = Board.new()

      assert board.name == "Default"
      assert board.simulation_id == "Default Simulation ID"
      assert %Workflow{} = board.workflow
      assert board.workers == %{}
      assert is_binary(board.id)
      assert %Audit{} = board.audit
    end
  end

  describe "new/1" do
    test "creates board with custom name" do
      %Board{} = board = Board.new("Dev Board")

      assert board.name == "Dev Board"
      assert board.simulation_id == "Default Simulation ID"
    end
  end

  describe "new/2" do
    test "creates board with name and simulation_id" do
      %Board{} = board = Board.new("Dev Board", "sim-123")

      assert board.name == "Dev Board"
      assert board.simulation_id == "sim-123"
    end
  end

  describe "new/3" do
    test "creates board with custom workflow" do
      workflow = Workflow.new()
      %Board{} = board = Board.new("QA Board", "sim-456", workflow)

      assert board.workflow == workflow
    end
  end

  describe "new/4" do
    test "creates board with workflow and workers" do
      workflow = Workflow.new()
      worker = Worker.new("Alice")
      workers = %{worker.id => worker}

      %Board{} = board = Board.new("QA Board", "sim-456", workflow, workers)

      assert board.workers == workers
    end
  end

  describe "new/5" do
    test "creates board with custom id" do
      workflow = Workflow.new()

      %Board{} = board = Board.new("Full Board", "sim-789", workflow, %{}, "custom-id")

      assert board.id == "custom-id"
    end
  end

  describe "new/6" do
    test "creates board with all explicit params" do
      workflow = Workflow.new()
      audit = Audit.new()

      %Board{} = board = Board.new("Full Board", "sim-789", workflow, %{}, "custom-id", audit)

      assert board.id == "custom-id"
      assert board.audit == audit
    end
  end

  describe "unique ids" do
    test "generates unique UUIDs" do
      b1 = Board.new("Board1", "sim-1")
      b2 = Board.new("Board2", "sim-1")

      refute b1.id == b2.id
    end
  end
end
