defmodule KanbanVisionApi.WebApi.Boards.BoardSerializer do
  @moduledoc """
  Serializer: converts Domain.Board structs to JSON-safe maps.
  """

  alias KanbanVisionApi.Domain.Board

  @spec serialize(Board.t()) :: map()
  def serialize(%Board{} = board) do
    %{
      id: board.id,
      name: board.name,
      simulation_id: board.simulation_id,
      created_at: DateTime.to_iso8601(board.audit.created),
      updated_at: DateTime.to_iso8601(board.audit.updated)
    }
  end

  @spec serialize_many_list(list()) :: list(map())
  def serialize_many_list(boards) when is_list(boards) do
    Enum.map(boards, &serialize/1)
  end
end
