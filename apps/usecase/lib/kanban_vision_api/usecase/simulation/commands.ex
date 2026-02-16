defmodule KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand do
  @moduledoc """
  Command: Create a new simulation.

  Validates input before command creation.
  """

  @enforce_keys [:name, :organization_id]
  defstruct [:name, :description, :organization_id]

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          organization_id: String.t()
        }

  @spec new(String.t(), String.t(), String.t() | nil) :: {:ok, t()} | {:error, atom()}
  def new(name, organization_id, description \\ nil)

  def new(name, organization_id, description)
      when is_binary(name) and byte_size(name) > 0 and
             is_binary(organization_id) and byte_size(organization_id) > 0 do
    {:ok, %__MODULE__{name: name, description: description, organization_id: organization_id}}
  end

  def new(name, _organization_id, _description)
      when not is_binary(name) or byte_size(name) == 0 do
    {:error, :invalid_name}
  end

  def new(_name, _organization_id, _description) do
    {:error, :invalid_organization_id}
  end
end

defmodule KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand do
  @moduledoc """
  Command: Delete a simulation.

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
