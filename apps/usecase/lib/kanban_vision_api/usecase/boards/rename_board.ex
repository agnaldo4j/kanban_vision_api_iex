defmodule KanbanVisionApi.Usecase.Boards.RenameBoard do
  @moduledoc """
  Use Case: Rename an existing board.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.RenameBoardCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(RenameBoardCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%RenameBoardCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Renaming board",
      correlation_id: correlation_id,
      board_id: cmd.id,
      board_name: cmd.name
    )

    with {:ok, board} <- repository.get_by_id(repository_runtime, cmd.id),
         renamed_board <- Board.rename(board, cmd.name),
         {:ok, updated_board} <- repository.update(repository_runtime, renamed_board) do
      Logger.info("Board renamed successfully",
        correlation_id: correlation_id,
        board_id: updated_board.id,
        board_name: updated_board.name,
        simulation_id: updated_board.simulation_id
      )

      EventEmitter.emit(
        :board,
        :board_renamed,
        %{
          board_id: updated_board.id,
          board_name: updated_board.name,
          simulation_id: updated_board.simulation_id
        },
        correlation_id
      )

      {:ok, updated_board}
    else
      {:error, reason} = error ->
        metadata =
          [correlation_id: correlation_id, board_id: cmd.id, board_name: cmd.name] ++
            ErrorMetadata.from_reason(reason)

        Logger.error("Failed to rename board", metadata)
        error
    end
  end
end
