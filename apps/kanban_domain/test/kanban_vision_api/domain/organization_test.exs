defmodule KanbanVisionApi.Domain.OrganizationTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Domain.Organization

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_organization
    test "should not have any simulation", %{actor_pid: pid, domain: domain} = _context do
      template = KanbanVisionApi.Domain.Organization.new(domain.name, %{}, domain.id, domain.audit)
      assert KanbanVisionApi.Domain.Organization.get_state(pid) == template
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

    initialState = KanbanVisionApi.Domain.Organization.new(%{domain.id => domain})

    {:ok, pid} = KanbanVisionApi.Domain.Organization.start_link(initialState)
    [
      actor_pid: pid,
      domain: domain
    ]
  end

end
