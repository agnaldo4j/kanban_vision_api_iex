defmodule KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand do
  @moduledoc """
  Command: Create a new organization.

  Validates input before command creation.
  """

  @enforce_keys [:name]
  defstruct [:name, tribes: []]

  @type t :: %__MODULE__{
          name: String.t(),
          tribes: list()
        }

  @spec new(String.t(), list()) :: {:ok, t()} | {:error, atom()}
  def new(name, tribes \\ [])

  def new(name, tribes)
      when is_binary(name) and byte_size(name) > 0 and is_list(tribes) do
    {:ok, %__MODULE__{name: name, tribes: tribes}}
  end

  def new(name, _tribes) when not is_binary(name) or byte_size(name) == 0 do
    {:error, :invalid_name}
  end

  def new(_name, _tribes) do
    {:error, :invalid_tribes}
  end
end

defmodule KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand do
  @moduledoc """
  Command: Delete an organization.

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
