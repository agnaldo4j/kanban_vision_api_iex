defmodule KanbanVisionApi.Agent.SimulationsTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Agent.Simulations

  describe "When start the system with empty state" do
    setup [:prepare_empty_context]

    @tag :domain_smulations
    test "should not have any simulation for any organization", %{
           actor_pid: pid,
           simulations: simulations
         } = _context do

      template = %KanbanVisionApi.Agent.Simulations{
        id: simulations.id,
        simulations_by_organization: %{}
      }

      assert KanbanVisionApi.Agent.Simulations.get_all(pid) == template
    end
  end

  defp prepare_empty_context(_context) do
    simulations_domain = KanbanVisionApi.Agent.Simulations.new()
    {:ok, pid} = KanbanVisionApi.Agent.Simulations.start_link(simulations_domain)
    [
      actor_pid: pid,
      simulations: simulations_domain
    ]
  end
end
