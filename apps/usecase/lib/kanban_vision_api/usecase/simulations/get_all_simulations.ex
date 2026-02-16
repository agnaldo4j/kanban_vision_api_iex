defmodule KanbanVisionApi.Usecase.Simulations.GetAllSimulations do
  @moduledoc """
  Use Case: Retrieve all simulations.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Usecase.EventEmitter

  @default_repository KanbanVisionApi.Agent.Simulations

  @type result :: {:ok, map()}

  @spec execute(pid(), keyword()) :: result()
  def execute(repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.debug("Retrieving all simulations", correlation_id: correlation_id)

    simulations = repository.get_all(repository_pid)

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
