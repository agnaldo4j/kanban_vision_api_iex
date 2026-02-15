defmodule KanbanVisionApi.Usecase.Organizations.GetAllOrganizations do
  @moduledoc """
  Use Case: Retrieve all organizations.

  Query operation with logging for observability.
  """

  require Logger

  @default_repository KanbanVisionApi.Agent.Organizations

  @type result :: {:ok, map()}

  @spec execute(pid(), keyword()) :: result()
  def execute(repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.debug("Retrieving all organizations", correlation_id: correlation_id)

    organizations = repository.get_all(repository_pid)

    Logger.debug("All organizations retrieved",
      correlation_id: correlation_id,
      count: map_size(organizations)
    )

    {:ok, organizations}
  end
end
