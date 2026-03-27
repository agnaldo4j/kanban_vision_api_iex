defmodule KanbanVisionApi.Domain.Ports.BoardRepository do
  @moduledoc """
  Port defining the contract for board persistence.
  """

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.RepositoryRuntime

  @type repository_runtime :: RepositoryRuntime.t()

  @callback get_all(runtime :: repository_runtime()) :: map()
  @callback get_by_id(runtime :: repository_runtime(), id :: String.t()) ::
              ApplicationError.result(Board.t())
  @callback add(runtime :: repository_runtime(), board :: Board.t()) ::
              ApplicationError.result(Board.t())
  @callback delete(runtime :: repository_runtime(), id :: String.t()) ::
              ApplicationError.result(Board.t())
  @callback get_all_by_simulation_id(runtime :: repository_runtime(), simulation_id :: String.t()) ::
              ApplicationError.result([Board.t()])
end
