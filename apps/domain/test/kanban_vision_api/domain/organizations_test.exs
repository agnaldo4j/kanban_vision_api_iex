defmodule KanbanVisionApi.Domain.OrganizationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Domain.Organizations

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_organizations
    test "should not have any organization", %{actor_pid: pid, domain: _domain} = _context do
      template = {:ok, %KanbanVisionApi.Domain.Organizations{organizations: %{}}}
      assert KanbanVisionApi.Domain.Organizations.get_all(pid) == template
    end

    @tag :domain_organizations
    test "should be able to add new organization", %{actor_pid: pid, domain: domain} = _context do
      assert KanbanVisionApi.Domain.Organizations.add(pid, domain) == {:ok, domain}
    end
  end

  describe "When start the system with one organization at the state" do
    setup [:prepare_context_with_default_organization]

    @tag :domain_organizations
    test "should has one organization", %{actor_pid: pid, domain: domain} = _context do
      template = {:ok, %KanbanVisionApi.Domain.Organizations{organizations: %{domain.id => domain}}}
      assert KanbanVisionApi.Domain.Organizations.get_all(pid) == template

    end

    @tag :domain_organizations
    test "should be possible to find the organization by the id", %{actor_pid: pid, domain: domain} = _context do
      assert KanbanVisionApi.Domain.Organizations.get_by_id(pid, domain.id) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should not be possible to find the organization by the wrong id",
         %{actor_pid: pid, domain: _domain} = _context do
      template = {:error, "Organization with id: nada not found"}
      assert KanbanVisionApi.Domain.Organizations.get_by_id(pid, :nada) == template
    end

    @tag :domain_organizations
    test "should be possible to find the organization by the name", %{actor_pid: pid, domain: domain} = _context do
      assert KanbanVisionApi.Domain.Organizations.get_by_name(pid, domain.name) == {:ok, [domain]}
    end

    @tag :domain_organizations
    test "should no be possible to find the organization by the wrong name",
         %{actor_pid: pid, domain: _domain} = _context do
      template = {:error, "Organization with name: Invalid Name not found"}
      assert KanbanVisionApi.Domain.Organizations.get_by_name(pid, "Invalid Name") == template
    end

    @tag :domain_organizations
    test "should no be possible to add one organization with the name already exist",
         %{actor_pid: pid, domain: domain} = _context do
      template = {:error, "Organization with name ExampleOrg already exists"}
      assert KanbanVisionApi.Domain.Organizations.add(pid, domain) == template
    end
  end

  defp prepare_empty_context(_context) do
    {:ok, pid} = KanbanVisionApi.Domain.Organizations.start_link()
    [
      actor_pid: pid,
      domain: KanbanVisionApi.Domain.Organization.new("ExampleOrg")
    ]
  end

  defp prepare_context_with_default_organization(_context) do
    domain = KanbanVisionApi.Domain.Organization.new("ExampleOrg")

    initialState = KanbanVisionApi.Domain.Organizations.new(%{domain.id => domain})

    {:ok, pid} = KanbanVisionApi.Domain.Organizations.start_link(initialState)
    [
      actor_pid: pid,
      domain: domain
    ]
  end

end
