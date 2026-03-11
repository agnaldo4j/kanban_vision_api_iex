defmodule KanbanVisionApi.WebApi.Adapters.SimulationAdapter do
  @moduledoc """
  Adapter: bridges the SimulationUsecase port to the Simulation GenServer.

  Calls the registered GenServer using the module name as the server reference.
  """

  @behaviour KanbanVisionApi.WebApi.Ports.SimulationUsecase

  alias KanbanVisionApi.Usecase.Simulation, as: SimUsecase

  @impl true
  def get_all(opts), do: SimUsecase.get_all(SimUsecase, opts)

  @impl true
  def get_by_org_and_name(query, opts), do: SimUsecase.get_by_org_and_name(SimUsecase, query, opts)

  @impl true
  def add(cmd, opts), do: SimUsecase.add(SimUsecase, cmd, opts)

  @impl true
  def delete(cmd, opts), do: SimUsecase.delete(SimUsecase, cmd, opts)
end
