defmodule KanbanVisionApi.Usecase.SimulationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Usecase.Simulation
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  describe "When start with empty state" do
    setup [:start_usecase]

    test "should return empty map", %{pid: pid} do
      assert Simulation.get_all(pid) == {:ok, %{}}
    end

    test "should add a new simulation via command", %{pid: pid} do
      org = KanbanVisionApi.Domain.Organization.new("TestOrg")

      {:ok, cmd} = CreateSimulationCommand.new("TestSim", org.id, "Description")

      assert {:ok, sim} = Simulation.add(pid, cmd)
      assert sim.name == "TestSim"
      assert sim.organization_id == org.id
    end

    test "should find simulation by org and name via query", %{pid: pid} do
      org = KanbanVisionApi.Domain.Organization.new("TestOrg")

      {:ok, cmd} = CreateSimulationCommand.new("TestSim", org.id, "Description")
      {:ok, sim} = Simulation.add(pid, cmd)

      {:ok, query} = GetSimulationByOrgAndNameQuery.new(org.id, "TestSim")
      # The result is a list, not a single simulation
      assert {:ok, [^sim]} = Simulation.get_by_org_and_name(pid, query)
    end

    test "should return error for non-existent simulation", %{pid: pid} do
      {:ok, query} = GetSimulationByOrgAndNameQuery.new("invalid", "Invalid")
      assert {:error, _} = Simulation.get_by_org_and_name(pid, query)
    end

    test "should reject invalid command", %{pid: pid} do
      assert {:error, :invalid_name} = CreateSimulationCommand.new("", "org-id")

      assert {:error, :invalid_organization_id} =
               CreateSimulationCommand.new("TestSim", "")
    end
  end

  defp start_usecase(_context) do
    {:ok, pid} = Simulation.start_link()
    [pid: pid]
  end
end
