defmodule KanbanVisionApi.Usecase.Board.CreateBoardCommand do
  @moduledoc """
  Command: Create a new board.

  Validates input before command creation.
  """

  @enforce_keys [:name, :simulation_id]
  defstruct [:name, :simulation_id]

  @type t :: %__MODULE__{
          name: String.t(),
          simulation_id: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(name, simulation_id)
      when is_binary(name) and byte_size(name) > 0 and
             is_binary(simulation_id) and byte_size(simulation_id) > 0 do
    {:ok, %__MODULE__{name: name, simulation_id: simulation_id}}
  end

  def new(name, _simulation_id) when not is_binary(name) or byte_size(name) == 0 do
    {:error, :invalid_name}
  end

  def new(_name, _simulation_id) do
    {:error, :invalid_simulation_id}
  end
end

defmodule KanbanVisionApi.Usecase.Board.DeleteBoardCommand do
  @moduledoc """
  Command: Delete a board.

  Validates input before command creation.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{
          id: String.t()
        }

  @spec new(String.t()) :: {:ok, t()} | {:error, atom()}
  def new(id) when is_binary(id) and byte_size(id) > 0 do
    {:ok, %__MODULE__{id: id}}
  end

  def new(_id) do
    {:error, :invalid_id}
  end
end
