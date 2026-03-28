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

defmodule KanbanVisionApi.Usecase.Board.RenameBoardCommand do
  @moduledoc """
  Command: Rename a board.
  """

  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(id, name)
      when is_binary(id) and byte_size(id) > 0 and is_binary(name) and byte_size(name) > 0 do
    {:ok, %__MODULE__{id: id, name: name}}
  end

  def new(id, _name) when not is_binary(id) or byte_size(id) == 0, do: {:error, :invalid_id}
  def new(_id, _name), do: {:error, :invalid_name}
end

defmodule KanbanVisionApi.Usecase.Board.AddBoardWorkflowStepCommand do
  @moduledoc """
  Command: Add a workflow step to a board.
  """

  @enforce_keys [:board_id, :name, :order, :required_ability_name]
  defstruct [:board_id, :name, :order, :required_ability_name]

  @type t :: %__MODULE__{
          board_id: String.t(),
          name: String.t(),
          order: non_neg_integer(),
          required_ability_name: String.t()
        }

  @spec new(String.t(), String.t(), integer(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(board_id, name, order, required_ability_name)
      when is_binary(board_id) and byte_size(board_id) > 0 and is_binary(name) and
             byte_size(name) > 0 and
             is_integer(order) and order >= 0 and is_binary(required_ability_name) and
             byte_size(required_ability_name) > 0 do
    {:ok,
     %__MODULE__{
       board_id: board_id,
       name: name,
       order: order,
       required_ability_name: required_ability_name
     }}
  end

  def new(board_id, _name, _order, _required_ability_name)
      when not is_binary(board_id) or byte_size(board_id) == 0,
      do: {:error, :invalid_id}

  def new(_board_id, name, _order, _required_ability_name)
      when not is_binary(name) or byte_size(name) == 0,
      do: {:error, :invalid_name}

  def new(_board_id, _name, order, _required_ability_name)
      when not is_integer(order) or order < 0,
      do: {:error, :invalid_order}

  def new(_board_id, _name, _order, _required_ability_name),
    do: {:error, :invalid_required_ability_name}
end

defmodule KanbanVisionApi.Usecase.Board.RemoveBoardWorkflowStepCommand do
  @moduledoc """
  Command: Remove a workflow step from a board.
  """

  @enforce_keys [:board_id, :step_id]
  defstruct [:board_id, :step_id]

  @type t :: %__MODULE__{
          board_id: String.t(),
          step_id: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(board_id, step_id)
      when is_binary(board_id) and byte_size(board_id) > 0 and is_binary(step_id) and
             byte_size(step_id) > 0 do
    {:ok, %__MODULE__{board_id: board_id, step_id: step_id}}
  end

  def new(board_id, _step_id) when not is_binary(board_id) or byte_size(board_id) == 0,
    do: {:error, :invalid_id}

  def new(_board_id, _step_id), do: {:error, :invalid_step_id}
end

defmodule KanbanVisionApi.Usecase.Board.ReorderBoardWorkflowStepCommand do
  @moduledoc """
  Command: Reorder a workflow step inside a board.
  """

  @enforce_keys [:board_id, :step_id, :order]
  defstruct [:board_id, :step_id, :order]

  @type t :: %__MODULE__{
          board_id: String.t(),
          step_id: String.t(),
          order: non_neg_integer()
        }

  @spec new(String.t(), String.t(), integer()) :: {:ok, t()} | {:error, atom()}
  def new(board_id, step_id, order)
      when is_binary(board_id) and byte_size(board_id) > 0 and is_binary(step_id) and
             byte_size(step_id) > 0 and
             is_integer(order) and order >= 0 do
    {:ok, %__MODULE__{board_id: board_id, step_id: step_id, order: order}}
  end

  def new(board_id, _step_id, _order)
      when not is_binary(board_id) or byte_size(board_id) == 0,
      do: {:error, :invalid_id}

  def new(_board_id, step_id, _order) when not is_binary(step_id) or byte_size(step_id) == 0,
    do: {:error, :invalid_step_id}

  def new(_board_id, _step_id, _order), do: {:error, :invalid_order}
end

defmodule KanbanVisionApi.Usecase.Board.AllocateBoardWorkerCommand do
  @moduledoc """
  Command: Allocate a worker snapshot to a board.
  """

  @enforce_keys [:board_id, :name, :abilities]
  defstruct [:board_id, :name, :abilities]

  @type t :: %__MODULE__{
          board_id: String.t(),
          name: String.t(),
          abilities: [String.t()]
        }

  @spec new(String.t(), String.t(), [String.t()]) :: {:ok, t()} | {:error, atom()}
  def new(board_id, name, abilities) do
    cond do
      not is_binary(board_id) or byte_size(board_id) == 0 ->
        {:error, :invalid_id}

      not is_binary(name) or byte_size(name) == 0 ->
        {:error, :invalid_name}

      not valid_abilities?(abilities) ->
        {:error, :invalid_abilities}

      true ->
        {:ok, %__MODULE__{board_id: board_id, name: name, abilities: abilities}}
    end
  end

  defp valid_abilities?(abilities) do
    is_list(abilities) and Enum.all?(abilities, &(is_binary(&1) and byte_size(&1) > 0))
  end
end

defmodule KanbanVisionApi.Usecase.Board.RemoveBoardWorkerCommand do
  @moduledoc """
  Command: Remove a worker from a board.
  """

  @enforce_keys [:board_id, :worker_id]
  defstruct [:board_id, :worker_id]

  @type t :: %__MODULE__{
          board_id: String.t(),
          worker_id: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(board_id, worker_id)
      when is_binary(board_id) and byte_size(board_id) > 0 and is_binary(worker_id) and
             byte_size(worker_id) > 0 do
    {:ok, %__MODULE__{board_id: board_id, worker_id: worker_id}}
  end

  def new(board_id, _worker_id) when not is_binary(board_id) or byte_size(board_id) == 0,
    do: {:error, :invalid_id}

  def new(_board_id, _worker_id), do: {:error, :invalid_worker_id}
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
