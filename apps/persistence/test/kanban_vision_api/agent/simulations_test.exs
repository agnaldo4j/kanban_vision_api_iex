defmodule KanbanVisionApi.Agent.SimulationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Simulations

  alias KanbanVisionApi.Agent.Simulations
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Simulation

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_simulations
    test "should not have any simulation for any organization",
         %{
           actor_pid: pid,
           simulations: _simulations,
           organization: _organization
         } = _context do
      template = %{}

      assert Simulations.get_all(pid) == template
    end

    @tag :domain_simulations
    test "should be able to add a new simulation to a specific organization",
         %{
           actor_pid: pid,
           simulations: _simulations,
           organization: organization
         } = _context do
      simulation_domain =
        Simulation.new(
          "ExampleSimulation",
          "ExampleSimulationDescription",
          organization.id
        )

      assert Simulations.add(pid, simulation_domain) ==
               {:ok, simulation_domain}
    end
  end

  describe "When the system is already started and already has data" do
    setup [:prepare_context_with_data]

    @tag :domain_simulations
    test "should be able to get all simulations for a specific organization",
         %{
           actor_pid: pid,
           simulations: _simulations,
           simulation: simulation,
           organization: organization
         } = _context do
      template = %{organization.id => %{simulation.id => simulation}}

      assert Simulations.get_all(pid) == template
    end

    @tag :domain_simulations
    test "should be able to add a new simulation to a specific organization",
         %{
           actor_pid: pid,
           simulations: _simulations,
           simulation: simulation,
           organization: organization
         } = _context do
      new_simulation =
        Simulation.new(
          "AnotherExampleOfSimulation",
          "AnotherExampleOfSimulationDescription",
          organization.id
        )

      assert Simulations.add(pid, new_simulation) == {:ok, new_simulation}

      template = %{
        organization.id => %{new_simulation.id => new_simulation, simulation.id => simulation}
      }

      assert Simulations.get_all(pid) == template
    end

    @tag :domain_simulations
    test "Try to add a simulation that already exists",
         %{
           actor_pid: pid,
           simulations: _simulations,
           simulation: simulation,
           organization: _organization
         } = _context do
      assert Simulations.add(pid, simulation) == {
               :error,
               """
               Simulation with organization_id: #{simulation.organization_id}
               name: #{simulation.name} already exist
               """
             }
    end

    @tag :domain_simulations
    test "try to find a simulation on a non existent organization",
         %{
           actor_pid: pid,
           simulations: _simulations,
           organization: _organization
         } = _context do
      template = {:error, "Simulation with organization id: INVALID not found"}

      assert Simulations.get_by_organization_id_and_simulation_name(
               pid,
               "INVALID",
               "Simulation Name"
             ) == template
    end

    @tag :domain_simulations
    test "try to find a simulation by name that does not exist",
         %{
           actor_pid: pid,
           organization: organization
         } = _context do
      template = {:error, "Simulation with name: Missing Simulation not found"}

      assert Simulations.get_by_organization_id_and_simulation_name(
               pid,
               organization.id,
               "Missing Simulation"
             ) == template
    end

    @tag :domain_simulations
    test "should delete a simulation by its id",
         %{
           actor_pid: pid,
           simulation: simulation
         } = _context do
      assert {:ok, ^simulation} = Simulations.delete(pid, simulation.id)
      assert %{} == Simulations.get_all(pid)
    end

    @tag :domain_simulations
    test "should return error when deleting simulation with unknown id",
         %{
           actor_pid: pid
         } = _context do
      assert {:error, "Simulation with id: unknown-id not found"} =
               Simulations.delete(pid, "unknown-id")
    end

    @tag :domain_simulations
    test "should delete one simulation and keep others in same organization",
         %{
           actor_pid: pid,
           simulation: simulation,
           organization: organization
         } = _context do
      other_simulation =
        Simulation.new("OtherSim", "OtherDesc", organization.id)

      assert {:ok, ^other_simulation} = Simulations.add(pid, other_simulation)
      assert {:ok, ^simulation} = Simulations.delete(pid, simulation.id)

      remaining = Simulations.get_all(pid)
      assert map_size(remaining[organization.id]) == 1
      assert Map.has_key?(remaining[organization.id], other_simulation.id)
    end
  end

  describe "When the system has an organization with no simulations" do
    setup [:prepare_context_with_empty_org]

    @tag :domain_simulations
    test "should return error for missing simulations on existing organization",
         %{
           actor_pid: pid,
           organization: organization
         } = _context do
      template = {:error, "Simulation with organization id: #{organization.id} not found"}

      assert Simulations.get_by_organization_id_and_simulation_name(
               pid,
               organization.id,
               "Any Simulation"
             ) == template
    end
  end

  defp prepare_empty_context(_context) do
    simulations_domain = Simulations.new()
    organization_domain = Organization.new("ExampleOrg")
    {:ok, pid} = Simulations.start_link(simulations_domain)

    [
      actor_pid: pid,
      simulations: simulations_domain,
      organization: organization_domain
    ]
  end

  defp prepare_context_with_data(_context) do
    organization_domain = Organization.new("ExampleOrg")

    simulation_domain =
      Simulation.new(
        "ExampleSimulation",
        "ExampleSimulationDescription",
        organization_domain.id
      )

    simulations_by_organization = %{
      organization_domain.id => %{simulation_domain.id => simulation_domain}
    }

    simulations_domain = Simulations.new(simulations_by_organization)

    {:ok, pid} = Simulations.start_link(simulations_domain)

    [
      actor_pid: pid,
      simulations: simulations_domain,
      simulation: simulation_domain,
      organization: organization_domain
    ]
  end

  defp prepare_context_with_empty_org(_context) do
    organization_domain = Organization.new("ExampleOrg")
    simulations_domain = Simulations.new(%{organization_domain.id => %{}})
    {:ok, pid} = Simulations.start_link(simulations_domain)

    [
      actor_pid: pid,
      simulations: simulations_domain,
      organization: organization_domain
    ]
  end
end
