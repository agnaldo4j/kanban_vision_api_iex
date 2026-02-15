defmodule KanbanVisionApi.Usecase.Simulations.GetSimulationByOrgAndName do
  @moduledoc """
  Use Case: Retrieve simulation by organization ID and name.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery

  @default_repository KanbanVisionApi.Agent.Simulations

  @type result ::
          {:ok, KanbanVisionApi.Domain.Simulation.t()} | {:error, String.t()}

  @spec execute(GetSimulationByOrgAndNameQuery.t(), pid(), keyword()) :: result()
  def execute(%GetSimulationByOrgAndNameQuery{} = query, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.debug("Retrieving simulation by org and name",
      correlation_id: correlation_id,
      organization_id: query.organization_id,
      simulation_name: query.name
    )

    result =
      repository.get_by_organization_id_and_simulation_name(
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

        {:ok, simulation}

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
