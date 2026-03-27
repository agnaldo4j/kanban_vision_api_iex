defmodule KanbanVisionApi.Usecase.Organizations.GetOrganizationByName do
  @moduledoc """
  Use Case: Retrieve organizations by name.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Ports.OrganizationRepository
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: {:ok, list()} | {:error, String.t()}

  @spec execute(
          GetOrganizationByNameQuery.t(),
          OrganizationRepository.repository_runtime(),
          keyword()
        ) :: result()
  def execute(%GetOrganizationByNameQuery{} = query, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving organizations by name",
      correlation_id: correlation_id,
      organization_name: query.name
    )

    result = repository.get_by_name(repository_runtime, query.name)

    case result do
      {:ok, orgs} ->
        Logger.debug("Organizations retrieved successfully",
          correlation_id: correlation_id,
          organization_name: query.name,
          count: length(orgs)
        )

      {:error, reason} ->
        Logger.warning("Organizations not found",
          correlation_id: correlation_id,
          organization_name: query.name,
          reason: reason
        )
    end

    result
  end
end
