defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @moduledoc """
  Use Case: Create a new organization.

  Orchestrates the creation of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Agent.Organizations, as: OrganizationRepository
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand

  @type result :: {:ok, Organization.t()} | {:error, String.t()}

  @spec execute(CreateOrganizationCommand.t(), pid(), keyword()) :: result()
  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    Logger.info("Creating organization",
      correlation_id: correlation_id,
      organization_name: cmd.name,
      tribes_count: length(cmd.tribes)
    )

    organization = Organization.new(cmd.name, cmd.tribes)

    case OrganizationRepository.add(repository_pid, organization) do
      {:ok, org} ->
        Logger.info("Organization created successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        emit_event(:organization_created, org, correlation_id)
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
