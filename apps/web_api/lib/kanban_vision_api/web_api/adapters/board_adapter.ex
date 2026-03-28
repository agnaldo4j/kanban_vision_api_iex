defmodule KanbanVisionApi.WebApi.Adapters.BoardAdapter do
  @moduledoc """
  Adapter: bridges the BoardUsecase port to the board application boundary.
  """

  @behaviour KanbanVisionApi.WebApi.Ports.BoardUsecase

  alias KanbanVisionApi.Usecase.Board, as: BoardUsecase

  @impl true
  def get_by_id(query, opts), do: BoardUsecase.get_by_id(BoardUsecase, query, opts)

  @impl true
  def get_by_simulation_id(query, opts),
    do: BoardUsecase.get_by_simulation_id(BoardUsecase, query, opts)

  @impl true
  def add(cmd, opts), do: BoardUsecase.add(BoardUsecase, cmd, opts)

  @impl true
  def delete(cmd, opts), do: BoardUsecase.delete(BoardUsecase, cmd, opts)
end
