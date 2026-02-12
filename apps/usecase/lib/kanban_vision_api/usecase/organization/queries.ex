defmodule KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery do
  @moduledoc """
  Query: Get organization by ID.

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

defmodule KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery do
  @moduledoc """
  Query: Get organization by name.

  Validates input before query creation.
  """

  @enforce_keys [:name]
  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }

  @spec new(String.t()) :: {:ok, t()} | {:error, atom()}
  def new(name) when is_binary(name) and byte_size(name) > 0 do
    {:ok, %__MODULE__{name: name}}
  end

  def new(_name) do
    {:error, :invalid_name}
  end
end
