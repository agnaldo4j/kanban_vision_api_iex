defmodule KanbanVisionApi.Usecase.Boards.DeleteBoard do
  @moduledoc """
  Use Case: Delete an existing board.

  Orchestrates the deletion of a board, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(DeleteBoardCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%DeleteBoardCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Deleting board",
      correlation_id: correlation_id,
      board_id: cmd.id
    )

    case repository.delete(repository_runtime, cmd.id) do
      {:ok, board} ->
        Logger.info("Board deleted successfully",
          correlation_id: correlation_id,
          board_id: board.id,
          board_name: board.name,
          simulation_id: board.simulation_id
        )

        EventEmitter.emit(
          :board,
          :board_deleted,
          %{
            board_id: board.id,
            board_name: board.name,
            simulation_id: board.simulation_id
          },
          correlation_id
        )

        {:ok, board}

      {:error, reason} = error ->
        metadata =
          [correlation_id: correlation_id, board_id: cmd.id] ++
            ErrorMetadata.from_reason(reason)

        Logger.error("Failed to delete board", metadata)

        error
    end
  end
end
