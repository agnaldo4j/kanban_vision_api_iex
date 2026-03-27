defmodule KanbanVisionApi.Usecase.Organizations.GetAllOrganizations do
  @moduledoc """
  Use Case: Retrieve all organizations.

  Query operation with logging for observability.
  """

  require Logger

  alias KanbanVisionApi.Domain.Ports.OrganizationRepository
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: {:ok, map()}

  @spec execute(OrganizationRepository.repository_runtime(), keyword()) :: result()
  def execute(repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.debug("Retrieving all organizations", correlation_id: correlation_id)

    organizations = repository.get_all(repository_runtime)

    Logger.debug("All organizations retrieved",
      correlation_id: correlation_id,
      count: map_size(organizations)
    )

    EventEmitter.emit(
      :organization,
      :all_organizations_retrieved,
      %{count: map_size(organizations)},
      correlation_id
    )

    {:ok, organizations}
  end
end
