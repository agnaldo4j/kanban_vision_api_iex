defmodule KanbanVisionApi.Usecase.Boards.AllocateWorker do
  @moduledoc """
  Use Case: Allocate a worker snapshot to a board.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.AllocateBoardWorkerCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(AllocateBoardWorkerCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%AllocateBoardWorkerCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Allocating worker to board",
      correlation_id: correlation_id,
      board_id: cmd.board_id,
      worker_name: cmd.name,
      abilities_count: length(cmd.abilities)
    )

    with {:ok, board} <- repository.get_by_id(repository_runtime, cmd.board_id),
         worker <- Board.build_worker(cmd.name, cmd.abilities),
         {:ok, updated_board} <- Board.allocate_worker(board, worker),
         {:ok, persisted_board} <- repository.update(repository_runtime, updated_board) do
      Logger.info("Worker allocated successfully",
        correlation_id: correlation_id,
        board_id: persisted_board.id,
        worker_id: worker.id,
        worker_name: worker.name
      )

      EventEmitter.emit(
        :board,
        :board_worker_allocated,
        %{board_id: persisted_board.id, worker_id: worker.id, worker_name: worker.name},
        correlation_id
      )

      {:ok, persisted_board}
    else
      {:error, :worker_name_taken} ->
        error =
          ApplicationError.conflict(
            "Worker with name: #{cmd.name} already exists in board: #{cmd.board_id}",
            %{entity: :worker, field: :name, board_id: cmd.board_id, name: cmd.name}
          )

        log_error("Failed to allocate worker", cmd, correlation_id, error)
        error

      {:error, _reason} = error ->
        log_error("Failed to allocate worker", cmd, correlation_id, error)
        error
    end
  end

  defp log_error(message, cmd, correlation_id, {:error, reason}) do
    metadata =
      [
        correlation_id: correlation_id,
        board_id: cmd.board_id,
        worker_name: cmd.name,
        abilities_count: length(cmd.abilities)
      ] ++ ErrorMetadata.from_reason(reason)

    Logger.error(message, metadata)
  end
end
