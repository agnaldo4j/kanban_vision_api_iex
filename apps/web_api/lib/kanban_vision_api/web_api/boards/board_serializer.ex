defmodule KanbanVisionApi.WebApi.Boards.BoardSerializer do
  @moduledoc """
  Serializer: converts Domain.Board structs to JSON-safe maps.
  """

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Worker

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

  @spec serialize_detail(Board.t()) :: map()
  def serialize_detail(%Board{} = board) do
    serialize(board)
    |> Map.put(:workflow, %{steps: Enum.map(board.workflow.steps, &serialize_step/1)})
    |> Map.put(:workers, board.workers |> Map.values() |> Enum.map(&serialize_worker/1))
  end

  @spec serialize_many_list(list()) :: list(map())
  def serialize_many_list(boards) when is_list(boards) do
    Enum.map(boards, &serialize/1)
  end

  defp serialize_step(%Step{} = step) do
    %{
      id: step.id,
      name: step.name,
      order: step.order,
      required_ability: serialize_ability(step.required_ability)
    }
  end

  defp serialize_worker(%Worker{} = worker) do
    %{
      id: worker.id,
      name: worker.name,
      abilities: Enum.map(worker.abilities, &serialize_ability/1)
    }
  end

  defp serialize_ability(%Ability{} = ability) do
    %{
      id: ability.id,
      name: ability.name
    }
  end
end
