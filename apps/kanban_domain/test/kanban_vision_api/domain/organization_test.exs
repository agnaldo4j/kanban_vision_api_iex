defmodule KanbanVisionApi.Domain.OrganizationTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Domain.Organization

  describe "When start a organization with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_organization
    test "should not have any simulation", %{actor_pid: pid, domain: domain} = _context do
      template = KanbanVisionApi.Domain.Organization.new(domain.name, %{}, domain.id, domain.audit)
      assert KanbanVisionApi.Domain.Organization.get_state(pid) == template
    end

    @tag :domain_organization
    test "should be able to add new simulation", %{actor_pid: pid, domain: domain} = _context do
      simulation = KanbanVisionApi.Domain.Simulation.new("ExampleSim")
      assert KanbanVisionApi.Domain.Organization.add_simulation(pid, simulation) == :ok
      assert KanbanVisionApi.Domain.Organization.get_state(pid).simulations == %{simulation.id => simulation}
    end

    @tag :domain_organization
    test "try to find a simulation by name", %{actor_pid: pid, domain: domain} = _context do
      simulation = KanbanVisionApi.Domain.Simulation.new("ExampleSim")
      assert KanbanVisionApi.Domain.Organization.add_simulation(pid, simulation) == :ok
      assert KanbanVisionApi.Domain.Organization.get_state(pid).simulations == %{simulation.id => simulation}
      assert KanbanVisionApi.Domain.Organization.get_simulation_by_name(pid, simulation.name) == {:ok, [simulation]}
    end

    @tag :domain_organization
    test "try to add the same simulation twice", %{actor_pid: pid, domain: domain} = _context do
      simulation = KanbanVisionApi.Domain.Simulation.new("ExampleSim")
      assert KanbanVisionApi.Domain.Organization.add_simulation(pid, simulation) == :ok
      assert KanbanVisionApi.Domain.Organization.add_simulation(pid, simulation) == :ok
      assert KanbanVisionApi.Domain.Organization.get_state(pid).simulations == %{simulation.id => simulation}
      assert KanbanVisionApi.Domain.Organization.get_simulation_by_name(pid, simulation.name) == {:ok, [simulation]}
    end
  end

  defp prepare_empty_context(_context) do
    domain = KanbanVisionApi.Domain.Organization.new("Teste")
    {:ok, pid} = KanbanVisionApi.Domain.Organization.start_link(domain)
    [
      actor_pid: pid,
      domain: domain
    ]
  end

  defp prepare_context_with_default_organization(_context) do
    domain = KanbanVisionApi.Domain.Organization.new("ExampleOrg")

    {:ok, pid} = KanbanVisionApi.Domain.Organization.start_link(domain)
    [
      actor_pid: pid,
      domain: domain
    ]
  end
end