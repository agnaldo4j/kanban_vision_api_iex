defmodule KanbanVisionApi.WebApi.Ports.BoardUsecase do
  @moduledoc """
  Port: defines the Board use case interface for the web layer.
  """

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Usecase.Board.AddBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.AllocateBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.RenameBoardCommand
  alias KanbanVisionApi.Usecase.Board.ReorderBoardWorkflowStepCommand

  @type error_reason :: ApplicationError.t() | atom()

  @callback get_by_id(GetBoardByIdQuery.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback get_by_simulation_id(GetBoardsBySimulationIdQuery.t(), opts :: keyword()) ::
              {:ok, [Board.t()]} | {:error, error_reason()}

  @callback add(CreateBoardCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback rename(RenameBoardCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback add_workflow_step(AddBoardWorkflowStepCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback remove_workflow_step(RemoveBoardWorkflowStepCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback reorder_workflow_step(ReorderBoardWorkflowStepCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback allocate_worker(AllocateBoardWorkerCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback remove_worker(RemoveBoardWorkerCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}

  @callback delete(DeleteBoardCommand.t(), opts :: keyword()) ::
              {:ok, Board.t()} | {:error, error_reason()}
end
