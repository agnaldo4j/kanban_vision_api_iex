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
  def rename(cmd, opts), do: BoardUsecase.rename(BoardUsecase, cmd, opts)

  @impl true
  def add_workflow_step(cmd, opts), do: BoardUsecase.add_workflow_step(BoardUsecase, cmd, opts)

  @impl true
  def remove_workflow_step(cmd, opts),
    do: BoardUsecase.remove_workflow_step(BoardUsecase, cmd, opts)

  @impl true
  def reorder_workflow_step(cmd, opts),
    do: BoardUsecase.reorder_workflow_step(BoardUsecase, cmd, opts)

  @impl true
  def allocate_worker(cmd, opts), do: BoardUsecase.allocate_worker(BoardUsecase, cmd, opts)

  @impl true
  def remove_worker(cmd, opts), do: BoardUsecase.remove_worker(BoardUsecase, cmd, opts)

  @impl true
  def delete(cmd, opts), do: BoardUsecase.delete(BoardUsecase, cmd, opts)
end
