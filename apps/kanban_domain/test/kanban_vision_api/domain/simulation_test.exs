defmodule KanbanVisionApi.Domain.SimulationTest do
  use ExUnit.Case, async: true

  describe "new/7" do
    test "sets default_projects on simulation state" do
      project = KanbanVisionApi.Domain.Project.new("Project A")
      board = KanbanVisionApi.Domain.Board.new("Board A", "simulation-1")
      simulation = KanbanVisionApi.Domain.Simulation.new("Sim A", "Desc", "org-1", board, [project])

      assert simulation.default_projects == [project]
    end
  end
end
