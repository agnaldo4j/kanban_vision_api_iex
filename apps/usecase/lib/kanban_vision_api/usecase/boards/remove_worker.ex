defmodule KanbanVisionApi.Usecase.Boards.RemoveWorker do
  @moduledoc """
  Use Case: Remove a worker from a board.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkerCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(RemoveBoardWorkerCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%RemoveBoardWorkerCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Removing worker from board",
      correlation_id: correlation_id,
      board_id: cmd.board_id,
      worker_id: cmd.worker_id
    )

    with {:ok, board} <- repository.get_by_id(repository_runtime, cmd.board_id),
         {:ok, updated_board} <- Board.remove_worker(board, cmd.worker_id),
         {:ok, persisted_board} <- repository.update(repository_runtime, updated_board) do
      Logger.info("Worker removed successfully",
        correlation_id: correlation_id,
        board_id: persisted_board.id,
        worker_id: cmd.worker_id
      )

      EventEmitter.emit(
        :board,
        :board_worker_removed,
        %{board_id: persisted_board.id, worker_id: cmd.worker_id},
        correlation_id
      )

      {:ok, persisted_board}
    else
      {:error, :worker_not_found} ->
        error =
          ApplicationError.not_found(
            "Worker with id: #{cmd.worker_id} not found in board: #{cmd.board_id}",
            %{entity: :worker, id: cmd.worker_id, board_id: cmd.board_id}
          )

        log_error("Failed to remove worker", cmd, correlation_id, error)
        error

      {:error, _reason} = error ->
        log_error("Failed to remove worker", cmd, correlation_id, error)
        error
    end
  end

  defp log_error(message, cmd, correlation_id, {:error, reason}) do
    metadata =
      [correlation_id: correlation_id, board_id: cmd.board_id, worker_id: cmd.worker_id] ++
        ErrorMetadata.from_reason(reason)

    Logger.error(message, metadata)
  end
end
