defmodule KanbanVisionApi.Usecase.Simulations.GetAllSimulations do
  @moduledoc """
  Use Case: Retrieve all simulations.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Agent.Simulations, as: SimulationRepository

  @type result :: {:ok, map()}

  @spec execute(pid(), keyword()) :: result()
  def execute(repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    Logger.debug("Retrieving all simulations", correlation_id: correlation_id)

    simulations = SimulationRepository.get_all(repository_pid)

    Logger.debug("All simulations retrieved",
      correlation_id: correlation_id,
      count: map_size(simulations)
    )

    {:ok, simulations}
  end
end
