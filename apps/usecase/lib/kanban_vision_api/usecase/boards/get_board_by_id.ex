defmodule KanbanVisionApi.Usecase.Boards.GetBoardById do
  @moduledoc """
  Use Case: Retrieve a board by its ID.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(GetBoardByIdQuery.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%GetBoardByIdQuery{} = query, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving board by ID",
      correlation_id: correlation_id,
      board_id: query.id
    )

    result = repository.get_by_id(repository_runtime, query.id)

    case result do
      {:ok, board} ->
        Logger.debug("Board retrieved successfully",
          correlation_id: correlation_id,
          board_id: board.id,
          simulation_id: board.simulation_id
        )

      {:error, reason} ->
        metadata =
          [correlation_id: correlation_id, board_id: query.id] ++
            ErrorMetadata.from_reason(reason)

        Logger.warning("Board not found", metadata)
    end

    result
  end
end
