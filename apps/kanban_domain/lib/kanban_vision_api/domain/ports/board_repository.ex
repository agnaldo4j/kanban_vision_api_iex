defmodule KanbanVisionApi.Domain.Ports.BoardRepository do
  @moduledoc """
  Port defining the contract for board persistence.
  """

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.RepositoryRuntime

  @type repository_runtime :: RepositoryRuntime.t()

  @callback get_all(runtime :: repository_runtime()) :: map()
  @callback get_by_id(runtime :: repository_runtime(), id :: String.t()) ::
              {:ok, Board.t()} | {:error, String.t()}
  @callback add(runtime :: repository_runtime(), board :: Board.t()) ::
              {:ok, Board.t()} | {:error, String.t()}
  @callback delete(runtime :: repository_runtime(), id :: String.t()) ::
              {:ok, Board.t()} | {:error, String.t()}
  @callback get_all_by_simulation_id(runtime :: repository_runtime(), simulation_id :: String.t()) ::
              {:ok, [Board.t()]} | {:error, String.t()}
end
