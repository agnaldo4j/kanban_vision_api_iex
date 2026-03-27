defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @moduledoc """
  Port defining the contract for organization persistence.
  """

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.RepositoryRuntime

  @type repository_runtime :: RepositoryRuntime.t()

  @callback get_all(runtime :: repository_runtime()) :: map()
  @callback get_by_id(runtime :: repository_runtime(), id :: String.t()) ::
              ApplicationError.result(Organization.t())
  @callback get_by_name(runtime :: repository_runtime(), name :: String.t()) ::
              ApplicationError.result([Organization.t()])
  @callback add(runtime :: repository_runtime(), organization :: Organization.t()) ::
              ApplicationError.result(Organization.t())
  @callback delete(runtime :: repository_runtime(), id :: String.t()) ::
              ApplicationError.result(Organization.t())
end
