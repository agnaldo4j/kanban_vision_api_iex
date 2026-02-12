defmodule KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery do
  @moduledoc """
  Query: Get simulation by organization ID and name.

  Validates input before query creation.
  """

  @enforce_keys [:organization_id, :name]
  defstruct [:organization_id, :name]

  @type t :: %__MODULE__{
          organization_id: String.t(),
          name: String.t()
        }

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def new(organization_id, name)
      when is_binary(organization_id) and byte_size(organization_id) > 0 and
             is_binary(name) and byte_size(name) > 0 do
    {:ok, %__MODULE__{organization_id: organization_id, name: name}}
  end

  def new(organization_id, _name)
      when not is_binary(organization_id) or byte_size(organization_id) == 0 do
    {:error, :invalid_organization_id}
  end

  def new(_organization_id, name) when not is_binary(name) or byte_size(name) == 0 do
    {:error, :invalid_name}
  end
end
