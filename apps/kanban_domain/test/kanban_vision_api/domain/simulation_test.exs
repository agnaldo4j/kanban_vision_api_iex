defmodule KanbanVisionApi.Domain.SimulationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Simulation

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

    test "uses default description when only name and org_id provided" do
      %Simulation{} = sim = Simulation.new("Sim1", "Default Simulation Name", "org-123")

      assert sim.description == "Default Simulation Name"
    end

    test "generates unique UUIDs" do
      sim1 = Simulation.new("Sim1", "Desc", "org-1")
      sim2 = Simulation.new("Sim2", "Desc", "org-1")

      refute sim1.id == sim2.id
    end
  end
end
