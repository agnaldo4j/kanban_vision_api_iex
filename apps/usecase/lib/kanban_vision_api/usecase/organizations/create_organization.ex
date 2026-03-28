defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @moduledoc """
  Use Case: Create a new organization.

  Orchestrates the creation of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Ports.OrganizationRepository
  alias KanbanVisionApi.Usecase.ErrorMetadata
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.RepositoryConfig

  @type result :: ApplicationError.result(Organization.t())

  @spec execute(
          CreateOrganizationCommand.t(),
          OrganizationRepository.repository_runtime(),
          keyword()
        ) ::
          result()
  def execute(%CreateOrganizationCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Creating organization",
      correlation_id: correlation_id,
      organization_name: cmd.name,
      tribes_count: length(cmd.tribes)
    )

    organization = Organization.new(cmd.name, cmd.tribes)

    case repository.add(repository_runtime, organization) do
      {:ok, org} ->
        Logger.info("Organization created successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        EventEmitter.emit(
          :organization,
          :organization_created,
          %{
            organization_id: org.id,
            organization_name: org.name
          },
          correlation_id
        )

        {:ok, org}

      {:error, reason} = error ->
        metadata =
          [correlation_id: correlation_id, organization_name: cmd.name] ++
            ErrorMetadata.from_reason(reason)

        Logger.error("Failed to create organization", metadata)

        error
    end
  end
end
