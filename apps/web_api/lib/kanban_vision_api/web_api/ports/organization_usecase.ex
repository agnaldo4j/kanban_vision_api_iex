defmodule KanbanVisionApi.WebApi.Ports.OrganizationUsecase do
  @moduledoc """
  Port: defines the Organization use case interface for the web layer.

  Decouples HTTP adapters from the concrete application boundary,
  enabling Mox-based unit testing of controllers.
  """

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery

  @callback get_all(opts :: keyword()) :: {:ok, map()}

  @callback get_by_id(GetOrganizationByIdQuery.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}

  @callback get_by_name(GetOrganizationByNameQuery.t(), opts :: keyword()) ::
              {:ok, list()} | {:error, String.t()}

  @callback add(CreateOrganizationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}

  @callback delete(DeleteOrganizationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}
end
