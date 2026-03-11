defmodule KanbanVisionApi.WebApi.Simulations.SimulationSerializerTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.WebApi.Simulations.SimulationSerializer

  setup do
    sim = Simulation.new("Sprint 1", "A sprint simulation", "org-123")
    %{sim: sim}
  end

  describe "serialize/1" do
    test "returns a map with all expected fields", %{sim: sim} do
      result = SimulationSerializer.serialize(sim)

      assert result.id == sim.id
      assert result.name == "Sprint 1"
      assert result.description == "A sprint simulation"
      assert result.organization_id == "org-123"
      assert is_binary(result.created_at)
      assert is_binary(result.updated_at)
    end

    test "formats dates as ISO8601", %{sim: sim} do
      result = SimulationSerializer.serialize(sim)

      assert String.contains?(result.created_at, "T")
      assert String.contains?(result.updated_at, "T")
    end
  end

  describe "serialize_many/1" do
    test "flattens nested org→sim map to list", %{sim: sim} do
      sims_map = %{"org-123" => %{sim.id => sim}}
      result = SimulationSerializer.serialize_many(sims_map)

      assert length(result) == 1
      assert hd(result).name == "Sprint 1"
    end

    test "returns empty list for empty map" do
      assert SimulationSerializer.serialize_many(%{}) == []
    end
  end

  describe "serialize_many_list/1" do
    test "converts a list of simulations", %{sim: sim} do
      result = SimulationSerializer.serialize_many_list([sim])

      assert length(result) == 1
      assert hd(result).name == "Sprint 1"
    end

    test "returns empty list for empty list" do
      assert SimulationSerializer.serialize_many_list([]) == []
    end
  end
end
