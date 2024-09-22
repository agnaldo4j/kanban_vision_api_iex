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

  def add(pid, new_board = %KanbanVisionApi.Domain.Board{}) do
    result = Agent.get(pid, fn state -> get_by_board(state.boards, new_board) end)

    Agent.update(pid, fn state ->
      case result do
        {:error, _} -> put_in(
                         state.boards,
                         Map.put(state.boards, new_board.id, new_board)
                       )
        {:ok, _} -> state
      end
    end)

    case result do
      {:error, _} -> {:ok, new_board}
      {:ok, _} -> {
                    :error,
                    """
                    Board with name: #{new_board.name}
                    from simulation_id: #{new_board.simulation_id} already exist
                    """
                  }
    end
  end

  def get_all(id) do
    Agent.get(id, fn state -> state.boards end)
  end

  def get_all_by_simulation_id(pid, simulation_id) do
    Agent.get(pid, fn state ->
      get_by_simulation_id(state.boards, simulation_id)
    end)
  end

  defp get_by_simulation_id(boards, simulation_id) do
    Map.values(boards)
    |> Enum.filter(fn {_, board} -> board.simulation_id == simulation_id end)
    |> prepare_by_boards_result(simulation_id)
  end

  defp prepare_by_boards_result(result_list, simulation_id) do
    case result_list do
      [] -> {:error, "Boards by simulation_id: #{simulation_id} not found"}
      _ -> {:ok, result_list}
    end
  end

  defp get_by_board(boards, new_board) do
    get_by_name_and_simulation_id(boards, new_board.name, new_board.simulation_id)
  end

  defp get_by_name_and_simulation_id(boards, name, simulation_id) do
    result = get_by_simulation_id(boards, simulation_id)
    case result do
      {:ok, boards} ->
        boards_by_name = Enum.filter(boards, fn board -> board.name == name end)
        case boards_by_name do
          [] -> {:error, "Boards by name: #{name} and simulation_id: #{simulation_id} not found"}
          _ -> {:ok, boards_by_name}
        end
      _ -> result
    end
  end
end
