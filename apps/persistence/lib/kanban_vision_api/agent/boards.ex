defmodule KanbanVisionApi.Agent.Boards do
  @moduledoc false

  use Agent

  @behaviour KanbanVisionApi.Domain.Ports.BoardRepository

  defstruct [:id, :boards]

  @type t :: %__MODULE__{
          id: String.t(),
          boards: map()
        }

  def new(boards \\ %{}, id \\ UUID.uuid4()) do
    %__MODULE__{
      id: id,
      boards: boards
    }
  end

  # Client

  @spec start_link(t()) :: Agent.on_start()
  def start_link(default \\ __MODULE__.new()) do
    Agent.start_link(fn -> default end)
  end

  def add(pid, %KanbanVisionApi.Domain.Board{} = new_board) do
    Agent.get_and_update(pid, fn state ->
      case get_by_board(state.boards, new_board) do
        {:error, _} ->
          new_state =
            put_in(
              state.boards,
              Map.put(state.boards, new_board.id, new_board)
            )

          {{:ok, new_board}, new_state}

        {:ok, _} ->
          {{:error,
            """
            Board with name: #{new_board.name}
            from simulation_id: #{new_board.simulation_id} already exist
            """}, state}
      end
    end)
  end

  def get_all(pid) do
    Agent.get(pid, fn state -> state.boards end)
  end

  def get_all_by_simulation_id(pid, simulation_id) do
    Agent.get(pid, fn state ->
      get_by_simulation_id(state.boards, simulation_id)
    end)
  end

  defp get_by_simulation_id(boards, simulation_id) do
    Map.values(boards)
    |> Enum.filter(fn board -> board.simulation_id == simulation_id end)
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
      {:ok, filtered_boards} ->
        boards_by_name = Enum.filter(filtered_boards, fn board -> board.name == name end)

        case boards_by_name do
          [] -> {:error, "Boards by name: #{name} and simulation_id: #{simulation_id} not found"}
          _ -> {:ok, boards_by_name}
        end

      _ ->
        result
    end
  end
end
