defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @moduledoc """
  Port defining the contract for organization persistence.
  """

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.RepositoryRuntime

  @type repository_runtime :: RepositoryRuntime.t()

  @callback get_all(runtime :: repository_runtime()) :: map()
  @callback get_by_id(runtime :: repository_runtime(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
  @callback get_by_name(runtime :: repository_runtime(), name :: String.t()) ::
              {:ok, [Organization.t()]} | {:error, String.t()}
  @callback add(runtime :: repository_runtime(), organization :: Organization.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
  @callback delete(runtime :: repository_runtime(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
end
