defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @moduledoc """
  Use Case: Create a new organization.

  Orchestrates the creation of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand

  @default_repository KanbanVisionApi.Agent.Organizations

  @type result :: {:ok, Organization.t()} | {:error, String.t()}

  @spec execute(CreateOrganizationCommand.t(), pid(), keyword()) :: result()
  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.info("Creating organization",
      correlation_id: correlation_id,
      organization_name: cmd.name,
      tribes_count: length(cmd.tribes)
    )

    organization = Organization.new(cmd.name, cmd.tribes)

    case repository.add(repository_pid, organization) do
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
        Logger.error("Failed to create organization",
          correlation_id: correlation_id,
          organization_name: cmd.name,
          reason: reason
        )

        error
    end
  end
end
