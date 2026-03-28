defmodule KanbanVisionApi.Agent.OrganizationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Organizations

  alias KanbanVisionApi.Agent.Organizations
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.ApplicationError

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_organizations
    test "should not have any organization",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations
         } = _context do
      template = %{}
      assert Organizations.get_all(repository_runtime) == template
    end

    @tag :domain_organizations
    test "should be able to add new organization",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations
         } = _context do
      domain = Organization.new("ExampleOrg")
      assert Organizations.add(repository_runtime, domain) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should be able to delete an existent organization",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations
         } = _context do
      domain = Organization.new("ExampleOrg")
      assert Organizations.add(repository_runtime, domain) == {:ok, domain}
      assert Organizations.delete(repository_runtime, domain.id) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should not be able to delete a non-existent organization",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations
         } = _context do
      assert Organizations.delete(repository_runtime, :nada) ==
               ApplicationError.not_found(
                 "Organization with id: nada not found",
                 %{entity: :organization, id: :nada}
               )
    end
  end

  describe "When start the system with one organization at the state" do
    setup [:prepare_context_with_default_organization]

    @tag :domain_organizations
    test "should has one organization",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: my_domain
         } = _context do
      template = %{my_domain.id => my_domain}

      assert Organizations.get_all(repository_runtime) == template
    end

    @tag :domain_organizations
    test "should be possible to find the organization by the id",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: domain
         } = _context do
      assert Organizations.get_by_id(repository_runtime, domain.id) == {:ok, domain}
    end

    @tag :domain_organizations
    test "should be possible to find the organization by the name",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: domain
         } = _context do
      assert Organizations.get_by_name(repository_runtime, domain.name) == {:ok, [domain]}
    end

    @tag :domain_organizations
    test "should not be possible to find the organization by the wrong id",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: _domain
         } = _context do
      assert Organizations.get_by_id(repository_runtime, :nada) ==
               ApplicationError.not_found(
                 "Organization with id: nada not found",
                 %{entity: :organization, id: :nada}
               )
    end

    @tag :domain_organizations
    test "should no be possible to find the organization by the wrong name",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: _domain
         } = _context do
      assert Organizations.get_by_name(repository_runtime, "Invalid Name") ==
               ApplicationError.not_found(
                 "Organization with name: Invalid Name not found",
                 %{entity: :organization, field: :name, name: "Invalid Name"}
               )
    end

    @tag :domain_organizations
    test "should no be possible to add one organization with the name already exist",
         %{
           repository_runtime: repository_runtime,
           organizations: _organizations,
           domain: domain
         } = _context do
      assert Organizations.add(repository_runtime, domain) ==
               ApplicationError.conflict(
                 "Organization with name: ExampleOrg already exist",
                 %{entity: :organization, field: :name, name: "ExampleOrg"}
               )
    end
  end

  defp prepare_empty_context(_context) do
    organizations_domain = Organizations.new()
    {:ok, repository_pid} = Organizations.start_link(organizations_domain)
    repository_runtime = Organizations.runtime(repository_pid)

    [
      repository_runtime: repository_runtime,
      organizations: organizations_domain
    ]
  end

  defp prepare_context_with_default_organization(_context) do
    organization_domain = Organization.new("ExampleOrg")

    initial_state =
      Organizations.new(%{organization_domain.id => organization_domain})

    {:ok, repository_pid} = Organizations.start_link(initial_state)
    repository_runtime = Organizations.runtime(repository_pid)

    [
      repository_runtime: repository_runtime,
      organizations: initial_state,
      domain: organization_domain
    ]
  end
end
