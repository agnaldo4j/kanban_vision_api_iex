defmodule KanbanVisionApi.Usecase.Boards.GetAllBoards do
  @moduledoc """
  Use Case: Retrieve all boards.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: {:ok, map()}

  @spec execute(BoardRepository.repository_runtime(), keyword()) :: result()
  def execute(repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving all boards", correlation_id: correlation_id)

    boards = repository.get_all(repository_runtime)

    Logger.debug("All boards retrieved",
      correlation_id: correlation_id,
      count: map_size(boards)
    )

    EventEmitter.emit(
      :board,
      :all_boards_retrieved,
      %{count: map_size(boards)},
      correlation_id
    )

    {:ok, boards}
  end
end
