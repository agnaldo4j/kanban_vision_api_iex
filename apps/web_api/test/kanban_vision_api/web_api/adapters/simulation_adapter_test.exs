defmodule KanbanVisionApi.WebApi.Adapters.SimulationAdapterTest do
  @moduledoc """
  Tests for the SimulationAdapter — delegates to the real GenServer.
  Requires the usecase application to be running (started as a dep in test env).
  """

  use ExUnit.Case, async: false

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery
  alias KanbanVisionApi.WebApi.Adapters.OrganizationAdapter
  alias KanbanVisionApi.WebApi.Adapters.SimulationAdapter

  defp unique_name, do: "AdapterSim-#{System.unique_integer([:positive])}"

  defp create_org do
    {:ok, cmd} = CreateOrganizationCommand.new("SimAdapterOrg-#{System.unique_integer([:positive])}")
    {:ok, org} = OrganizationAdapter.add(cmd, [])
    org
  end

  defp cleanup_org(org) do
    {:ok, cmd} = DeleteOrganizationCommand.new(org.id)
    OrganizationAdapter.delete(cmd, [])
  end

  describe "get_all/1" do
    test "delegates to the Simulation GenServer and returns a map" do
      assert {:ok, simulations} = SimulationAdapter.get_all([])
      assert is_map(simulations)
    end
  end

  describe "add/2" do
    test "creates a simulation via the GenServer" do
      org = create_org()
      {:ok, cmd} = CreateSimulationCommand.new(unique_name(), org.id)

      assert {:ok, sim} = SimulationAdapter.add(cmd, [])
      assert sim.organization_id == org.id

      {:ok, del} = DeleteSimulationCommand.new(sim.id)
      SimulationAdapter.delete(del, [])
      cleanup_org(org)
    end
  end

  describe "get_by_org_and_name/2" do
    test "retrieves a simulation by organization and name" do
      org = create_org()
      name = unique_name()
      {:ok, cmd} = CreateSimulationCommand.new(name, org.id)
      {:ok, sim} = SimulationAdapter.add(cmd, [])

      {:ok, query} = GetSimulationByOrgAndNameQuery.new(org.id, name)
      assert {:ok, ^sim} = SimulationAdapter.get_by_org_and_name(query, [])

      {:ok, del} = DeleteSimulationCommand.new(sim.id)
      SimulationAdapter.delete(del, [])
      cleanup_org(org)
    end
  end

  describe "delete/2" do
    test "deletes a simulation via the GenServer" do
      org = create_org()
      {:ok, cmd} = CreateSimulationCommand.new(unique_name(), org.id)
      {:ok, sim} = SimulationAdapter.add(cmd, [])

      {:ok, del} = DeleteSimulationCommand.new(sim.id)
      assert {:ok, ^sim} = SimulationAdapter.delete(del, [])

      cleanup_org(org)
    end
  end
end
