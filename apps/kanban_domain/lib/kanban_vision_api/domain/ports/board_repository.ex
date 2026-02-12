defmodule KanbanVisionApi.Domain.Ports.BoardRepository do
  @moduledoc """
  Port defining the contract for board persistence.
  """

  @callback get_all(pid :: pid()) :: map()
  @callback add(pid :: pid(), board :: struct()) :: {:ok, struct()} | {:error, String.t()}
  @callback get_all_by_simulation_id(pid :: pid(), simulation_id :: String.t()) ::
              {:ok, list()} | {:error, String.t()}
end
