defmodule KanbanVisionApi.WebApi.Ports.BoardUsecase do
  @moduledoc """
  Port: defines the Board use case interface for the web layer.
  """

  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery

  @type error_reason :: ApplicationError.t() | atom()

  @callback get_by_id(GetBoardByIdQuery.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}

  @callback get_by_simulation_id(GetBoardsBySimulationIdQuery.t(), opts :: keyword()) ::
              {:ok, list()} | {:error, error_reason()}

  @callback add(CreateBoardCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}

  @callback delete(DeleteBoardCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, error_reason()}
end
