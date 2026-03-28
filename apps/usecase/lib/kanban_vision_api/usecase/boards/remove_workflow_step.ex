defmodule KanbanVisionApi.Usecase.Boards.RemoveWorkflowStep do
  @moduledoc """
  Use Case: Remove a workflow step from a board.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(
          RemoveBoardWorkflowStepCommand.t(),
          BoardRepository.repository_runtime(),
          keyword()
        ) ::
          result()
  def execute(%RemoveBoardWorkflowStepCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Removing workflow step from board",
      correlation_id: correlation_id,
      board_id: cmd.board_id,
      step_id: cmd.step_id
    )

    with {:ok, board} <- repository.get_by_id(repository_runtime, cmd.board_id),
         {:ok, updated_board} <- Board.remove_workflow_step(board, cmd.step_id),
         {:ok, persisted_board} <- repository.update(repository_runtime, updated_board) do
      Logger.info("Workflow step removed successfully",
        correlation_id: correlation_id,
        board_id: persisted_board.id,
        step_id: cmd.step_id
      )

      EventEmitter.emit(
        :board,
        :board_workflow_step_removed,
        %{board_id: persisted_board.id, step_id: cmd.step_id},
        correlation_id
      )

      {:ok, persisted_board}
    else
      {:error, :step_not_found} ->
        error =
          ApplicationError.not_found(
            "Workflow step with id: #{cmd.step_id} not found in board: #{cmd.board_id}",
            %{entity: :workflow_step, id: cmd.step_id, board_id: cmd.board_id}
          )

        log_error("Failed to remove workflow step", cmd, correlation_id, error)
        error

      {:error, _reason} = error ->
        log_error("Failed to remove workflow step", cmd, correlation_id, error)
        error
    end
  end

  defp log_error(message, cmd, correlation_id, {:error, reason}) do
    metadata =
      [correlation_id: correlation_id, board_id: cmd.board_id, step_id: cmd.step_id] ++
        ErrorMetadata.from_reason(reason)

    Logger.error(message, metadata)
  end
end
