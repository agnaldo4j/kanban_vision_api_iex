defmodule KanbanVisionApi.Usecase.Simulations.GetAllSimulations do
  @moduledoc """
  Use Case: Retrieve all simulations.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Ports.SimulationRepository
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: {:ok, map()}

  @spec execute(SimulationRepository.repository_runtime(), keyword()) :: result()
  def execute(repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving all simulations", correlation_id: correlation_id)

    simulations = repository.get_all(repository_runtime)

    Logger.debug("All simulations retrieved",
      correlation_id: correlation_id,
      count: map_size(simulations)
    )

    EventEmitter.emit(
      :simulation,
      :all_simulations_retrieved,
      %{count: map_size(simulations)},
      correlation_id
    )

    {:ok, simulations}
  end
end
