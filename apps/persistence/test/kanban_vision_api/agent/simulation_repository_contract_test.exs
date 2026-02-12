defmodule KanbanVisionApi.Agent.SimulationRepositoryContractTest do
  @moduledoc """
  Integration test verifying that Agent.Simulations correctly implements
  the SimulationRepository port contract.
  """
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Agent.Simulations
  alias KanbanVisionApi.Domain.Ports.SimulationRepository
  alias KanbanVisionApi.Domain.Simulation

  @moduletag :integration

  describe "SimulationRepository contract" do
    setup do
      {:ok, pid} = Simulations.start_link()
      [repository_pid: pid]
    end

    test "implements get_all/1 callback", %{repository_pid: pid} do
      assert function_exported?(Simulations, :get_all, 1)
      assert is_map(Simulations.get_all(pid))
    end

    test "implements add/2 callback", %{repository_pid: pid} do
      assert function_exported?(Simulations, :add, 2)

      org_id = UUID.uuid4()
      sim = Simulation.new("TestSim", "Description", org_id)
      assert {:ok, added} = Simulations.add(pid, sim)
      assert added.id == sim.id
      assert added.name == "TestSim"
    end

    test "implements get_by_organization_id_and_simulation_name/3 callback", %{
      repository_pid: pid
    } do
      assert function_exported?(Simulations, :get_by_organization_id_and_simulation_name, 3)

      org_id = UUID.uuid4()
      sim = Simulation.new("FindableSim", "Description", org_id)
      {:ok, created} = Simulations.add(pid, sim)

      assert {:ok, ^created} =
               Simulations.get_by_organization_id_and_simulation_name(pid, org_id, "FindableSim")

      assert {:error, _} =
               Simulations.get_by_organization_id_and_simulation_name(
                 pid,
                 org_id,
                 "NonExistentSim"
               )
    end

    test "satisfies @behaviour SimulationRepository" do
      behaviours = Simulations.module_info(:attributes)[:behaviour] || []
      assert SimulationRepository in behaviours
    end
  end
end
