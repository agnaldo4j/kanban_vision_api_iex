defmodule KanbanVisionApi.WebApi.Adapters.OrganizationAdapterTest do
  @moduledoc """
  Tests for the OrganizationAdapter — delegates to the real GenServer.
  Requires the usecase application to be running (started as a dep in test env).
  """

  use ExUnit.Case, async: false

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery
  alias KanbanVisionApi.WebApi.Adapters.OrganizationAdapter

  defp unique_name, do: "AdapterOrg-#{System.unique_integer([:positive])}"

  describe "get_all/1" do
    test "delegates to the Organization GenServer and returns a map" do
      assert {:ok, organizations} = OrganizationAdapter.get_all([])
      assert is_map(organizations)
    end
  end

  describe "add/2" do
    test "creates an organization via the GenServer" do
      {:ok, cmd} = CreateOrganizationCommand.new(unique_name())

      assert {:ok, org} = OrganizationAdapter.add(cmd, [])
      assert is_binary(org.id)

      {:ok, del} = DeleteOrganizationCommand.new(org.id)
      OrganizationAdapter.delete(del, [])
    end
  end

  describe "get_by_id/2" do
    test "retrieves an organization by ID" do
      {:ok, cmd} = CreateOrganizationCommand.new(unique_name())
      {:ok, org} = OrganizationAdapter.add(cmd, [])

      {:ok, query} = GetOrganizationByIdQuery.new(org.id)
      assert {:ok, ^org} = OrganizationAdapter.get_by_id(query, [])

      {:ok, del} = DeleteOrganizationCommand.new(org.id)
      OrganizationAdapter.delete(del, [])
    end
  end

  describe "get_by_name/2" do
    test "retrieves organizations by name" do
      name = unique_name()
      {:ok, cmd} = CreateOrganizationCommand.new(name)
      {:ok, org} = OrganizationAdapter.add(cmd, [])

      {:ok, query} = GetOrganizationByNameQuery.new(name)
      assert {:ok, [^org]} = OrganizationAdapter.get_by_name(query, [])

      {:ok, del} = DeleteOrganizationCommand.new(org.id)
      OrganizationAdapter.delete(del, [])
    end
  end

  describe "delete/2" do
    test "deletes an organization via the GenServer" do
      {:ok, cmd} = CreateOrganizationCommand.new(unique_name())
      {:ok, org} = OrganizationAdapter.add(cmd, [])

      {:ok, del} = DeleteOrganizationCommand.new(org.id)
      assert {:ok, ^org} = OrganizationAdapter.delete(del, [])
    end
  end
end
