defmodule KanbanVisionApi.Agent.SimulationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Simulations

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_smulations
    test "should not have any simulation for any organization", %{
           actor_pid: pid,
           simulations: _simulations,
           organization: _organization
         } = _context do

      template = %{}

      assert KanbanVisionApi.Agent.Simulations.get_all(pid) == template
    end

    @tag :domain_smulations
    test "should be able to add a new simulation to a specific organization", %{
           actor_pid: pid,
           simulations: _simulations,
           organization: organization
         } = _context do

      simulation_domain = KanbanVisionApi.Domain.Simulation.new(
        "ExampleSimulation",
        "ExampleSimulationDescription",
        organization.id
      )

      assert KanbanVisionApi.Agent.Simulations.add(pid, simulation_domain) == {:ok, simulation_domain}
    end
  end
  
  describe "When the system is already started and already has data" do
    setup [:prepare_context_with_data]

    @tag :domain_smulations
    test "should be able to get all simulations for a specific organization", %{
           actor_pid: pid,
           simulations: _simulations,
           simulation: simulation,
           organization: organization
         } = _context do

      template = %{organization.id => %{simulation.id => simulation}}

      assert KanbanVisionApi.Agent.Simulations.get_all(pid) == template
    end

    @tag :domain_smulations
    test "should be able to add a new simulation to a specific organization", %{
           actor_pid: pid,
           simulations: _simulations,
           simulation: simulation,
           organization: organization
         } = _context do

      new_simulation = KanbanVisionApi.Domain.Simulation.new(
        "AnotherExampleOfSimulation",
        "AnotherExampleOfSimulationDescription",
        organization.id
      )

      assert KanbanVisionApi.Agent.Simulations.add(pid, new_simulation) == {:ok, new_simulation}

      template = %{organization.id => %{new_simulation.id => new_simulation, simulation.id => simulation}}

      assert KanbanVisionApi.Agent.Simulations.get_all(pid) == template
    end
  end

  defp prepare_empty_context(_context) do
    simulations_domain = KanbanVisionApi.Agent.Simulations.new()
    organization_domain = KanbanVisionApi.Agent.Organizations.new("ExampleOrg")
    {:ok, pid} = KanbanVisionApi.Agent.Simulations.start_link(simulations_domain)
    [
      actor_pid: pid,
      simulations: simulations_domain,
      organization: organization_domain
    ]
  end

  defp prepare_context_with_data(_context) do
    organization_domain = KanbanVisionApi.Agent.Organizations.new("ExampleOrg")
    simulation_domain = KanbanVisionApi.Domain.Simulation.new(
      "ExampleSimulation",
      "ExampleSimulationDescription",
      organization_domain.id
    )

    simulations_by_organization = %{
      organization_domain.id => %{simulation_domain.id => simulation_domain}
    }
    simulations_domain = KanbanVisionApi.Agent.Simulations.new(simulations_by_organization)

    {:ok, pid} = KanbanVisionApi.Agent.Simulations.start_link(simulations_domain)

    [
      actor_pid: pid,
      simulations: simulations_domain,
      simulation: simulation_domain,
      organization: organization_domain
    ]
  end
end
