defmodule KanbanVisionApi.Domain.Ports.BoardRepository do
  @moduledoc """
  Port defining the contract for board persistence.
  """

  alias KanbanVisionApi.Domain.Board

  @callback get_all(pid :: pid()) :: map()
  @callback add(pid :: pid(), board :: Board.t()) :: {:ok, Board.t()} | {:error, String.t()}
  @callback get_all_by_simulation_id(pid :: pid(), simulation_id :: String.t()) ::
              {:ok, [Board.t()]} | {:error, String.t()}
end
