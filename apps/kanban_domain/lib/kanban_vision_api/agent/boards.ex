defmodule KanbanVisionApi.Agent.Boards do
  @moduledoc false

  use Agent

  defstruct [:id, :boards]

  @type t :: %KanbanVisionApi.Agent.Boards {
               id: String.t,
               boards: Map.t
             }

  def new(boards \\ %{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Agent.Boards{
      id: id,
      boards: boards
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Agent.Boards.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Agent.Boards.new) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_all(id) do
    Agent.get(id, fn state -> state.boards end)
  end

  def get_all_by_simulation_id(pid, simulation_id) do
    Agent.get(pid, fn state ->
      internal_get_by_simulation_id(state.boards, simulation_id)
    end)
  end

  defp internal_get_by_simulation_id(boards, simulation_id) do
    Map.values(boards)
    |> Enum.filter(fn {_, board} -> board.simulation_id == simulation_id end)
    |> prepare_by_boards_result(simulation_id)
  end

  defp prepare_by_boards_result(result_list, simulation_id) do
    case result_list do
      values when values == [] -> {:error, "Boards by simulation_id: #{simulation_id} not found"}
      values -> {:ok, values}
    end
  end
end
