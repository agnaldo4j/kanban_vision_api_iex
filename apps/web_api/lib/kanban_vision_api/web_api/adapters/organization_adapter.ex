defmodule KanbanVisionApi.WebApi.Adapters.OrganizationAdapter do
  @moduledoc """
  Adapter: bridges the OrganizationUsecase port to the Organization GenServer.

  Calls the registered GenServer using the module name as the server reference.
  """

  @behaviour KanbanVisionApi.WebApi.Ports.OrganizationUsecase

  alias KanbanVisionApi.Usecase.Organization, as: OrgUsecase

  @impl true
  def get_all(opts), do: OrgUsecase.get_all(OrgUsecase, opts)

  @impl true
  def get_by_id(query, opts), do: OrgUsecase.get_by_id(OrgUsecase, query, opts)

  @impl true
  def get_by_name(query, opts), do: OrgUsecase.get_by_name(OrgUsecase, query, opts)

  @impl true
  def add(cmd, opts), do: OrgUsecase.add(OrgUsecase, cmd, opts)

  @impl true
  def delete(cmd, opts), do: OrgUsecase.delete(OrgUsecase, cmd, opts)
end
