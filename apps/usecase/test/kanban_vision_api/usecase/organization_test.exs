defmodule KanbanVisionApi.Usecase.OrganizationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Usecase.Organization
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery

  describe "When start with empty state" do
    setup [:start_usecase]

    test "should return empty map", %{pid: pid} do
      assert Organization.get_all(pid) == {:ok, %{}}
    end

    test "should add a new organization via command", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
      assert {:ok, org} = Organization.add(pid, cmd)
      assert org.name == "TestOrg"
      assert org.id != nil
    end

    test "should find organization by id via query", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
      {:ok, org} = Organization.add(pid, cmd)

      {:ok, query} = GetOrganizationByIdQuery.new(org.id)
      assert {:ok, ^org} = Organization.get_by_id(pid, query)
    end

    test "should find organization by name via query", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
      {:ok, org} = Organization.add(pid, cmd)

      {:ok, query} = GetOrganizationByNameQuery.new("TestOrg")
      assert {:ok, [^org]} = Organization.get_by_name(pid, query)
    end

    test "should delete an organization via command", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
      {:ok, org} = Organization.add(pid, cmd)

      {:ok, delete_cmd} = DeleteOrganizationCommand.new(org.id)
      assert {:ok, ^org} = Organization.delete(pid, delete_cmd)
      assert {:ok, %{}} = Organization.get_all(pid)
    end

    test "should return error for non-existent id", %{pid: pid} do
      {:ok, query} = GetOrganizationByIdQuery.new("invalid")
      assert {:error, _} = Organization.get_by_id(pid, query)
    end

    test "should return error for non-existent name", %{pid: pid} do
      {:ok, query} = GetOrganizationByNameQuery.new("Invalid")
      assert {:error, _} = Organization.get_by_name(pid, query)
    end

    test "should not allow duplicate organization names", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
      {:ok, _} = Organization.add(pid, cmd)

      {:ok, cmd2} = CreateOrganizationCommand.new("TestOrg")
      assert {:error, _} = Organization.add(pid, cmd2)
    end

    test "should reject invalid command", %{pid: pid} do
      assert {:error, :invalid_name} = CreateOrganizationCommand.new("")
      assert {:error, :invalid_name} = CreateOrganizationCommand.new(nil)
    end
  end

  defp start_usecase(_context) do
    {:ok, pid} = Organization.start_link()
    [pid: pid]
  end
end
