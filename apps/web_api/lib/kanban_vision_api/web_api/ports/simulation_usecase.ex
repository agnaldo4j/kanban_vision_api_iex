defmodule KanbanVisionApi.WebApi.Ports.SimulationUsecase do
  @moduledoc """
  Port: defines the Simulation use case interface for the web layer.

  Decouples HTTP adapters from the concrete application boundary,
  enabling Mox-based unit testing of controllers.
  """

  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  @type error_reason :: ApplicationError.t() | atom()

  @callback get_all(opts :: keyword()) :: {:ok, map()}

  @callback get_by_org_and_name(GetSimulationByOrgAndNameQuery.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}

  @callback add(CreateSimulationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}

  @callback delete(DeleteSimulationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}
end
