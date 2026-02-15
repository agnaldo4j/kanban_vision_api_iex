defmodule KanbanVisionApi.Usecase.Organizations.GetOrganizationByName do
  @moduledoc """
  Use Case: Retrieve organizations by name.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery

  @default_repository KanbanVisionApi.Agent.Organizations

  @type result :: {:ok, list()} | {:error, String.t()}

  @spec execute(GetOrganizationByNameQuery.t(), pid(), keyword()) :: result()
  def execute(%GetOrganizationByNameQuery{} = query, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.debug("Retrieving organizations by name",
      correlation_id: correlation_id,
      organization_name: query.name
    )

    result = repository.get_by_name(repository_pid, query.name)

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
