defmodule KanbanVisionApi.Agent.OrganizationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Organizations

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_organizations
    test "should not have any organization",
         %{
           actor_pid: pid,
           organizations: _organizations
         } = _context do
      template = %{}
      assert KanbanVisionApi.Agent.Organizations.get_all(pid) == template
    end

    @tag :domain_organizations
    test "should be able to add new organization",
         %{
           actor_pid: pid,
           organizations: _organizations
         } = _context do
      domain = KanbanVisionApi.Domain.Organization.new("ExampleOrg")
      assert KanbanVisionApi.Agent.Organizations.add(pid, domain) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should be able to delete an existent organization",
         %{
           actor_pid: pid,
           organizations: _organizations
         } = _context do
      domain = KanbanVisionApi.Domain.Organization.new("ExampleOrg")
      assert KanbanVisionApi.Agent.Organizations.add(pid, domain) == {:ok, domain}
      assert KanbanVisionApi.Agent.Organizations.delete(pid, domain.id) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should not be able to delete a non-existent organization",
         %{
           actor_pid: pid,
           organizations: _organizations
         } = _context do
      template = {:error, "Organization with id: nada not found"}
      assert KanbanVisionApi.Agent.Organizations.delete(pid, :nada) == template
    end
  end

  describe "When start the system with one organization at the state" do
    setup [:prepare_context_with_default_organization]

    @tag :domain_organizations
    test "should has one organization",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: my_domain
         } = _context do
      template = %{my_domain.id => my_domain}

      assert KanbanVisionApi.Agent.Organizations.get_all(pid) == template
    end

    @tag :domain_organizations
    test "should be possible to find the organization by the id",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: domain
         } = _context do
      assert KanbanVisionApi.Agent.Organizations.get_by_id(pid, domain.id) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should be possible to find the organization by the name",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: domain
         } = _context do
      assert KanbanVisionApi.Agent.Organizations.get_by_name(pid, domain.name) == {:ok, [domain]}
    end

    @tag :domain_organizations
    test "should not be possible to find the organization by the wrong id",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: _domain
         } = _context do
      template = {:error, "Organization with id: nada not found"}
      assert KanbanVisionApi.Agent.Organizations.get_by_id(pid, :nada) == template
    end

    @tag :domain_organizations
    test "should no be possible to find the organization by the wrong name",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: _domain
         } = _context do
      template = {:error, "Organization with name: Invalid Name not found"}
      assert KanbanVisionApi.Agent.Organizations.get_by_name(pid, "Invalid Name") == template
    end

    @tag :domain_organizations
    test "should no be possible to add one organization with the name already exist",
         %{
           actor_pid: pid,
           organizations: _organizations,
           domain: domain
         } = _context do
      template = {:error, "Organization with name: ExampleOrg already exist"}
      assert KanbanVisionApi.Agent.Organizations.add(pid, domain) == template
    end
  end

  defp prepare_empty_context(_context) do
    organizations_domain = KanbanVisionApi.Agent.Organizations.new()
    {:ok, pid} = KanbanVisionApi.Agent.Organizations.start_link(organizations_domain)

    [
      actor_pid: pid,
      organizations: organizations_domain
    ]
  end

  defp prepare_context_with_default_organization(_context) do
    organization_domain = KanbanVisionApi.Domain.Organization.new("ExampleOrg")

    initial_state =
      KanbanVisionApi.Agent.Organizations.new(%{organization_domain.id => organization_domain})

    {:ok, pid} = KanbanVisionApi.Agent.Organizations.start_link(initial_state)

    [
      actor_pid: pid,
      organizations: initial_state,
      domain: organization_domain
    ]
  end
end
