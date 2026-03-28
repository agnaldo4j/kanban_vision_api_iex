defmodule KanbanVisionApi.Usecase.Boards.CreateBoard do
  @moduledoc """
  Use Case: Create a new board.

  Orchestrates board creation, logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.BoardRepository
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Board.t())

  @spec execute(CreateBoardCommand.t(), BoardRepository.repository_runtime(), keyword()) ::
          result()
  def execute(%CreateBoardCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Creating board",
      correlation_id: correlation_id,
      board_name: cmd.name,
      simulation_id: cmd.simulation_id
    )

    board = Board.new(cmd.name, cmd.simulation_id)

    case repository.add(repository_runtime, board) do
      {:ok, created_board} ->
        Logger.info("Board created successfully",
          correlation_id: correlation_id,
          board_id: created_board.id,
          board_name: created_board.name,
          simulation_id: created_board.simulation_id
        )

        EventEmitter.emit(
          :board,
          :board_created,
          %{
            board_id: created_board.id,
            board_name: created_board.name,
            simulation_id: created_board.simulation_id
          },
          correlation_id
        )

        {:ok, created_board}

      {:error, reason} = error ->
        metadata =
          [
            correlation_id: correlation_id,
            board_name: cmd.name,
            simulation_id: cmd.simulation_id
          ] ++ ErrorMetadata.from_reason(reason)

        Logger.error("Failed to create board", metadata)

        error
    end
  end
end
