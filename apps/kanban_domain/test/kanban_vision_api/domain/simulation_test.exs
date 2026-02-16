defmodule KanbanVisionApi.Domain.SimulationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Project
  alias KanbanVisionApi.Domain.Simulation

  describe "new/2" do
    test "creates simulation with name and organization_id using default description" do
      %Simulation{} = sim = Simulation.new("Sim1", "org-123")

      assert sim.name == "Sim1"
      assert sim.description == "Default Simulation Name"
      assert sim.organization_id == "org-123"
    end
  end

  describe "new/3" do
    test "creates simulation with name, description, and organization_id" do
      %Simulation{} = sim = Simulation.new("Sim1", "A description", "org-123")

      assert sim.name == "Sim1"
      assert sim.description == "A description"
      assert sim.organization_id == "org-123"
      assert is_binary(sim.id)
      assert %Audit{} = sim.audit
      assert %Board{} = sim.board
      assert sim.default_projects == []
    end
  end

  describe "new/4" do
    test "creates simulation with custom board" do
      board = Board.new("Custom Board", "sim-1")

      %Simulation{} = sim = Simulation.new("Sim1", "Desc", "org-1", board)

      assert sim.board == board
    end
  end

  describe "new/5" do
    test "creates simulation with board and default_projects" do
      board = Board.new("Custom Board", "sim-1")
      project = Project.new("Project Alpha")

      %Simulation{} = sim = Simulation.new("Sim1", "Desc", "org-1", board, [project])

      assert sim.default_projects == [project]
    end
  end

  describe "new/6" do
    test "creates simulation with custom id" do
      board = Board.new()

      %Simulation{} = sim = Simulation.new("Sim", "Desc", "org-1", board, [], "custom-id")

      assert sim.id == "custom-id"
    end
  end

  describe "new/7" do
    test "creates simulation with all explicit params" do
      board = Board.new()
      audit = Audit.new()

      %Simulation{} = sim = Simulation.new("Sim", "Desc", "org-1", board, [], "custom-id", audit)

      assert sim.id == "custom-id"
      assert sim.audit == audit
    end
  end

  describe "unique ids" do
    test "generates unique UUIDs" do
      sim1 = Simulation.new("Sim1", "Desc", "org-1")
      sim2 = Simulation.new("Sim2", "Desc", "org-1")

      refute sim1.id == sim2.id
    end
  end
end
