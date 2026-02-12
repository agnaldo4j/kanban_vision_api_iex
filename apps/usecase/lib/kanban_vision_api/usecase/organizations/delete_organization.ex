defmodule KanbanVisionApi.Usecase.Organizations.DeleteOrganization do
  @moduledoc """
  Use Case: Delete an existing organization.

  Orchestrates the deletion of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Agent.Organizations, as: OrganizationRepository
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand

  @type result :: {:ok, Organization.t()} | {:error, String.t()}

  @spec execute(DeleteOrganizationCommand.t(), pid(), keyword()) :: result()
  def execute(%DeleteOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    Logger.info("Deleting organization",
      correlation_id: correlation_id,
      organization_id: cmd.id
    )

    case OrganizationRepository.delete(repository_pid, cmd.id) do
      {:ok, org} ->
        Logger.info("Organization deleted successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        emit_event(:organization_deleted, org, correlation_id)
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

  defp emit_event(event_type, organization, correlation_id) do
    try do
      :telemetry.execute(
        [:kanban_vision_api, :organization, event_type],
        %{count: 1},
        %{
          organization_id: organization.id,
          organization_name: organization.name,
          correlation_id: correlation_id
        }
      )
    rescue
      UndefinedFunctionError ->
        :ok
    end
  end
end
