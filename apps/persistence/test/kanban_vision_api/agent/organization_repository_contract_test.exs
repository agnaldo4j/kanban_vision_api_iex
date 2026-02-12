defmodule KanbanVisionApi.Agent.OrganizationRepositoryContractTest do
  @moduledoc """
  Integration test verifying that Agent.Organizations correctly implements
  the OrganizationRepository port contract.
  """
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Agent.Organizations
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.OrganizationRepository

  @moduletag :integration

  describe "OrganizationRepository contract" do
    setup do
      {:ok, pid} = Organizations.start_link()
      [repository_pid: pid]
    end

    test "implements get_all/1 callback", %{repository_pid: pid} do
      assert function_exported?(Organizations, :get_all, 1)
      assert is_map(Organizations.get_all(pid))
    end

    test "implements get_by_id/2 callback", %{repository_pid: pid} do
      assert function_exported?(Organizations, :get_by_id, 2)

      org = Organization.new("TestOrg")
      {:ok, created} = Organizations.add(pid, org)

      assert {:ok, ^created} = Organizations.get_by_id(pid, created.id)
      assert {:error, _} = Organizations.get_by_id(pid, "non-existent-id")
    end

    test "implements get_by_name/2 callback", %{repository_pid: pid} do
      assert function_exported?(Organizations, :get_by_name, 2)

      org = Organization.new("UniqueOrg")
      {:ok, created} = Organizations.add(pid, org)

      assert {:ok, [^created]} = Organizations.get_by_name(pid, "UniqueOrg")
      assert {:error, _} = Organizations.get_by_name(pid, "NonExistentOrg")
    end

    test "implements add/2 callback", %{repository_pid: pid} do
      assert function_exported?(Organizations, :add, 2)

      org = Organization.new("NewOrg")
      assert {:ok, added} = Organizations.add(pid, org)
      assert added.id == org.id
      assert added.name == "NewOrg"

      # Should reject duplicate names
      duplicate = Organization.new("NewOrg")
      assert {:error, _} = Organizations.add(pid, duplicate)
    end

    test "implements delete/2 callback", %{repository_pid: pid} do
      assert function_exported?(Organizations, :delete, 2)

      org = Organization.new("ToDelete")
      {:ok, created} = Organizations.add(pid, org)

      assert {:ok, deleted} = Organizations.delete(pid, created.id)
      assert deleted.id == created.id

      # Should fail on non-existent ID
      assert {:error, _} = Organizations.delete(pid, "non-existent-id")
    end

    test "satisfies @behaviour OrganizationRepository" do
      behaviours = Organizations.module_info(:attributes)[:behaviour] || []
      assert OrganizationRepository in behaviours
    end
  end
end
