defmodule KanbanVisionApi.Usecase.Boards.AddWorkflowStep do
  @moduledoc """
  Use Case: Add a workflow step to a board.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.AddBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(AddBoardWorkflowStepCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%AddBoardWorkflowStepCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Adding workflow step to board",
      correlation_id: correlation_id,
      board_id: cmd.board_id,
      step_name: cmd.name,
      step_order: cmd.order,
      required_ability_name: cmd.required_ability_name
    )

    with {:ok, board} <- repository.get_by_id(repository_runtime, cmd.board_id),
         step <- Board.build_step(cmd.name, cmd.order, cmd.required_ability_name),
         {:ok, updated_board} <- Board.add_workflow_step(board, step),
         {:ok, persisted_board} <- repository.update(repository_runtime, updated_board) do
      Logger.info("Workflow step added successfully",
        correlation_id: correlation_id,
        board_id: persisted_board.id,
        step_id: step.id,
        step_name: step.name
      )

      EventEmitter.emit(
        :board,
        :board_workflow_step_added,
        %{board_id: persisted_board.id, step_id: step.id, step_name: step.name},
        correlation_id
      )

      {:ok, persisted_board}
    else
      {:error, :step_name_taken} ->
        error =
          ApplicationError.conflict(
            "Workflow step with name: #{cmd.name} already exists in board: #{cmd.board_id}",
            %{entity: :workflow_step, field: :name, board_id: cmd.board_id, name: cmd.name}
          )

        log_error("Failed to add workflow step", cmd, correlation_id, error)
        error

      {:error, _reason} = error ->
        log_error("Failed to add workflow step", cmd, correlation_id, error)
        error
    end
  end

  defp log_error(message, cmd, correlation_id, {:error, reason}) do
    metadata =
      [
        correlation_id: correlation_id,
        board_id: cmd.board_id,
        step_name: cmd.name,
        step_order: cmd.order,
        required_ability_name: cmd.required_ability_name
      ] ++ ErrorMetadata.from_reason(reason)

    Logger.error(message, metadata)
  end
end
