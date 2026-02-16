defmodule KanbanVisionApi.Usecase.Boards.DeleteBoard do
  @moduledoc """
  Use Case: Delete an existing board.

  Orchestrates the deletion of a board, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.EventEmitter

  @default_repository KanbanVisionApi.Agent.Boards

  @type result :: {:ok, Board.t()} | {:error, String.t()}

  @spec execute(DeleteBoardCommand.t(), pid(), keyword()) :: result()
  def execute(%DeleteBoardCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.info("Deleting board",
      correlation_id: correlation_id,
      board_id: cmd.id
    )

    case repository.delete(repository_pid, cmd.id) do
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
        Logger.error("Failed to delete board",
          correlation_id: correlation_id,
          board_id: cmd.id,
          reason: reason
        )

        error
    end
  end
end
