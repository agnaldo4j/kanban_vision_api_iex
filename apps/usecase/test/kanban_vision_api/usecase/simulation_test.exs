defmodule KanbanVisionApi.Usecase.SimulationTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Usecase.Simulation

  describe "When start a new simulation with empty state" do
    test "should be empty" do
      {:ok, pid} = KanbanVisionApi.Usecase.Simulation.start_link()
      assert KanbanVisionApi.Usecase.Simulation.fetch(pid) == {:ok, %{}}
    end
  end

end
