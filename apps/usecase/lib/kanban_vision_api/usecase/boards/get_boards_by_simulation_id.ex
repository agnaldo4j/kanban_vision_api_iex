defmodule KanbanVisionApi.Usecase.Boards.GetBoardsBySimulationId do
  @moduledoc """
  Use Case: Retrieve boards by simulation ID.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result([Board.t()])

  @spec execute(
          GetBoardsBySimulationIdQuery.t(),
          BoardRepository.repository_runtime(),
          keyword()
        ) :: result()
  def execute(%GetBoardsBySimulationIdQuery{} = query, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving boards by simulation ID",
      correlation_id: correlation_id,
      simulation_id: query.simulation_id
    )

    result = repository.get_all_by_simulation_id(repository_runtime, query.simulation_id)

    case result do
      {:ok, boards} ->
        Logger.debug("Boards retrieved successfully",
          correlation_id: correlation_id,
          simulation_id: query.simulation_id,
          count: length(boards)
        )

        EventEmitter.emit(
          :board,
          :boards_by_simulation_retrieved,
          %{simulation_id: query.simulation_id, count: length(boards)},
          correlation_id
        )

      {:error, reason} ->
        metadata =
          [correlation_id: correlation_id, simulation_id: query.simulation_id] ++
            ErrorMetadata.from_reason(reason)

        Logger.warning("Boards not found", metadata)
    end

    result
  end
end
