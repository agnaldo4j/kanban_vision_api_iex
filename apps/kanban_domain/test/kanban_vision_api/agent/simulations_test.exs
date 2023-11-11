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
end
