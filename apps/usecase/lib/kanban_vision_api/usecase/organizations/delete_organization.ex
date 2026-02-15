defmodule KanbanVisionApi.Usecase.Organizations.DeleteOrganization do
  @moduledoc """
  Use Case: Delete an existing organization.

  Orchestrates the deletion of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand

  @default_repository KanbanVisionApi.Agent.Organizations

  @type result :: {:ok, Organization.t()} | {:error, String.t()}

  @spec execute(DeleteOrganizationCommand.t(), pid(), keyword()) :: result()
  def execute(%DeleteOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.info("Deleting organization",
      correlation_id: correlation_id,
      organization_id: cmd.id
    )

    case repository.delete(repository_pid, cmd.id) do
      {:ok, org} ->
        Logger.info("Organization deleted successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        EventEmitter.emit(
          :organization,
          :organization_deleted,
          %{
            organization_id: org.id,
            organization_name: org.name
          },
          correlation_id
        )

        {:ok, org}

      {:error, reason} = error ->
        Logger.error("Failed to delete organization",
          correlation_id: correlation_id,
          organization_id: cmd.id,
          reason: reason
        )

        error
    end
  end
end
