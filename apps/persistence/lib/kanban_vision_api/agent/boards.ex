defmodule KanbanVisionApi.Agent.Boards do
  @moduledoc false

  use Agent

  @behaviour KanbanVisionApi.Domain.Ports.BoardRepository

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError

  defmodule Runtime do
    @moduledoc false

    @enforce_keys [:pid]
    defstruct [:pid]
  end

  defstruct [:id, :boards]

  @type t :: %__MODULE__{
          id: String.t(),
          boards: map()
        }

  @opaque runtime :: %Runtime{pid: pid()}

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

  @spec runtime(pid()) :: runtime()
  def runtime(pid), do: %Runtime{pid: pid}

  def add(%Runtime{pid: pid}, %Board{} = new_board) do
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
          {conflict_by_name_and_simulation_id(new_board.name, new_board.simulation_id), state}
      end
    end)
  end

  def get_by_id(%Runtime{pid: pid}, board_id) do
    Agent.get(pid, fn state ->
      case Map.get(state.boards, board_id) do
        nil -> not_found_by_id(board_id)
        board -> {:ok, board}
      end
    end)
  end

  def get_all(%Runtime{pid: pid}) do
    Agent.get(pid, fn state -> state.boards end)
  end

  def delete(%Runtime{pid: pid}, board_id) do
    Agent.get_and_update(pid, fn state ->
      case Map.get(state.boards, board_id) do
        nil ->
          {not_found_by_id(board_id), state}

        board ->
          new_state = put_in(state.boards, Map.delete(state.boards, board_id))
          {{:ok, board}, new_state}
      end
    end)
  end

  def get_all_by_simulation_id(%Runtime{pid: pid}, simulation_id) do
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
      [] -> not_found_by_simulation_id(simulation_id)
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
          [] -> not_found_by_name_and_simulation_id(name, simulation_id)
          _ -> {:ok, boards_by_name}
        end

      _ ->
        result
    end
  end

  defp not_found_by_id(board_id) do
    ApplicationError.not_found(
      "Board with id: #{board_id} not found",
      %{entity: :board, id: board_id}
    )
  end

  defp not_found_by_simulation_id(simulation_id) do
    ApplicationError.not_found(
      "Boards by simulation_id: #{simulation_id} not found",
      %{entity: :board, field: :simulation_id, simulation_id: simulation_id}
    )
  end

  defp not_found_by_name_and_simulation_id(name, simulation_id) do
    ApplicationError.not_found(
      "Boards by name: #{name} and simulation_id: #{simulation_id} not found",
      %{entity: :board, field: :name, name: name, simulation_id: simulation_id}
    )
  end

  defp conflict_by_name_and_simulation_id(name, simulation_id) do
    ApplicationError.conflict(
      "Board with name: #{name} from simulation_id: #{simulation_id} already exist",
      %{entity: :board, field: :name, name: name, simulation_id: simulation_id}
    )
  end
end
