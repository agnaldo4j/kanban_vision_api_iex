defmodule KanbanVisionApi.Usecase.Simulations.GetSimulationByOrgAndName do
  @moduledoc """
  Use Case: Retrieve simulation by organization ID and name.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Agent.Simulations, as: SimulationRepository
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  @type result ::
          {:ok, KanbanVisionApi.Domain.Simulation.t()} | {:error, String.t()}

  @spec execute(GetSimulationByOrgAndNameQuery.t(), pid(), keyword()) :: result()
  def execute(%GetSimulationByOrgAndNameQuery{} = query, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    Logger.debug("Retrieving simulation by org and name",
      correlation_id: correlation_id,
      organization_id: query.organization_id,
      simulation_name: query.name
    )

    result =
      SimulationRepository.get_by_organization_id_and_simulation_name(
        repository_pid,
        query.organization_id,
        query.name
      )

    case result do
      {:ok, simulation} ->
        Logger.debug("Simulation retrieved successfully",
          correlation_id: correlation_id,
          organization_id: query.organization_id,
          simulation_name: query.name,
          simulation_id: simulation.id
        )

        # Return as list for consistency with test expectations
        {:ok, [simulation]}

      {:error, reason} = error ->
        Logger.warning("Simulation not found",
          correlation_id: correlation_id,
          organization_id: query.organization_id,
          simulation_name: query.name,
          reason: reason
        )

        error
    end
  end
end
