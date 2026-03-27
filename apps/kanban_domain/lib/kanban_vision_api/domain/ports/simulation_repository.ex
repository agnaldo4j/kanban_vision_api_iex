defmodule KanbanVisionApi.Domain.Ports.SimulationRepository do
  @moduledoc """
  Port defining the contract for simulation persistence.
  """

  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.RepositoryRuntime
  alias KanbanVisionApi.Domain.Simulation

  @type repository_runtime :: RepositoryRuntime.t()

  @callback get_all(runtime :: repository_runtime()) :: map()
  @callback add(runtime :: repository_runtime(), simulation :: Simulation.t()) ::
              ApplicationError.result(Simulation.t())
  @callback delete(runtime :: repository_runtime(), id :: String.t()) ::
              ApplicationError.result(Simulation.t())
  @callback get_by_organization_id_and_simulation_name(
              runtime :: repository_runtime(),
              org_id :: String.t(),
              name :: String.t()
            ) :: ApplicationError.result(Simulation.t())
end
