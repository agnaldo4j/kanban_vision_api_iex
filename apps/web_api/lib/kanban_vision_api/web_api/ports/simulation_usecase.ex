defmodule KanbanVisionApi.WebApi.Ports.SimulationUsecase do
  @moduledoc """
  Port: defines the Simulation use case interface for the web layer.

  Decouples HTTP adapters from the concrete application boundary,
  enabling Mox-based unit testing of controllers.
  """

  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  @callback get_all(opts :: keyword()) :: {:ok, map()}

  @callback get_by_org_and_name(GetSimulationByOrgAndNameQuery.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}

  @callback add(CreateSimulationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}

  @callback delete(DeleteSimulationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}
end
