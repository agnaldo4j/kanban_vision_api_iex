defmodule KanbanVisionApi.Usecase.OrganizationTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Usecase.Organization

  @tag :usecase_organization
  describe "When start the system with empty state" do
    setup [:prepare_context]

    test "should not have any organization", %{actor_pid: pid} do
      assert KanbanVisionApi.Usecase.Organization.get_all(pid) == {:ok, %{}}
    end

    test "should be able to add organization with name ExampleOrg", %{actor_pid: pid, domain: domain} do
      assert KanbanVisionApi.Usecase.Organization.add(pid, domain) == {:ok, domain}
    end

    test "should have only one organization with name ExampleOrg inside", %{actor_pid: pid, domain: domain} do
      assert KanbanVisionApi.Usecase.Organization.get_all(pid) == {:ok, %{domain.id => domain}}
    end

    test "should be able to find an organization by id", %{actor_pid: pid, domain: domain} do
      assert KanbanVisionApi.Usecase.Organization.get_by_id(pid, domain.id) == {:ok, domain}
    end

    test "should not be able to find an organization with invalid id", %{actor_pid: pid} do
      template = {:error, "Organization with id: nada not found"}
      assert KanbanVisionApi.Usecase.Organization.get_by_id(pid, :nada) == template
    end

    test "should be able to find an organization by name", %{actor_pid: pid, domain: domain} do
      assert KanbanVisionApi.Usecase.Organization.get_by_name(pid, domain.name) == {:ok, [domain]}
    end

    test "should not be able to find an organization with a wrong name", %{actor_pid: pid} do
      template = {:error, "Organization with name: Invalid Name not found"}
      assert KanbanVisionApi.Usecase.Organization.get_by_name(pid, "Invalid Name") == template
    end

    test "should not be able to add another organization with name ExampleOrg", %{actor_pid: pid, domain: domain} do
      template = {:error, "Organization with name ExampleOrg already exists"}
      assert KanbanVisionApi.Usecase.Organization.add(pid, domain) == template
    end
  end

  defp prepare_context(_context) do
    {:ok, pid} = KanbanVisionApi.Usecase.Organization.start_link()
    [
      actor_pid: pid,
      domain: KanbanVisionApi.Domain.Organization.new("ExampleOrg")
    ]
  end

end
