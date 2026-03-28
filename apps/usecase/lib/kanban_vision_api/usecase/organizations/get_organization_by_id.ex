defmodule KanbanVisionApi.Usecase.Organizations.GetOrganizationById do
  @moduledoc """
  Use Case: Retrieve an organization by its ID.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.OrganizationRepository
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Organization.t())

  @spec execute(
          GetOrganizationByIdQuery.t(),
          OrganizationRepository.repository_runtime(),
          keyword()
        ) :: result()
  def execute(%GetOrganizationByIdQuery{} = query, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving organization by ID",
      correlation_id: correlation_id,
      organization_id: query.id
    )

    result = repository.get_by_id(repository_runtime, query.id)

    case result do
      {:ok, org} ->
        Logger.debug("Organization retrieved successfully",
          correlation_id: correlation_id,
          organization_id: org.id
        )

      {:error, reason} ->
        metadata =
          [correlation_id: correlation_id, organization_id: query.id] ++
            ErrorMetadata.from_reason(reason)

        Logger.warning("Organization not found", metadata)
    end

    result
  end
end
