defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @moduledoc """
  Port defining the contract for organization persistence.
  """

  alias KanbanVisionApi.Domain.Organization

  @callback get_all(pid :: pid()) :: map()
  @callback get_by_id(pid :: pid(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
  @callback get_by_name(pid :: pid(), name :: String.t()) ::
              {:ok, [Organization.t()]} | {:error, String.t()}
  @callback add(pid :: pid(), organization :: Organization.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
  @callback delete(pid :: pid(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
end
