defmodule KanbanVisionApi.Usecase.Board.GetBoardByIdQuery do
  @moduledoc """
  Query: Get board by ID.

  Validates input before query creation.
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

defmodule KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery do
  @moduledoc """
  Query: Get boards by simulation ID.

  Validates input before query creation.
  """

  @enforce_keys [:simulation_id]
  defstruct [:simulation_id]

  @type t :: %__MODULE__{
          simulation_id: String.t()
        }

  @spec new(String.t()) :: {:ok, t()} | {:error, atom()}
  def new(simulation_id) when is_binary(simulation_id) and byte_size(simulation_id) > 0 do
    {:ok, %__MODULE__{simulation_id: simulation_id}}
  end

  def new(_simulation_id) do
    {:error, :invalid_simulation_id}
  end
end
