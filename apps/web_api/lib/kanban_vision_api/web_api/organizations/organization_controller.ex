defmodule KanbanVisionApi.WebApi.Organizations.OrganizationController do
  @moduledoc """
  HTTP adapter: translates HTTP requests to Organization use case calls.

  Pure adapter — no business logic. Maps HTTP → Command/Query → use case → JSON response.
  Error mapping: validation atoms normalize to `:invalid_input`, structured application
  errors map by `code`, and transport logic never parses message text.
  """

  import Plug.Conn

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByIdQuery
  alias KanbanVisionApi.Usecase.Organization.GetOrganizationByNameQuery
  alias KanbanVisionApi.WebApi.ErrorMapper
  alias KanbanVisionApi.WebApi.Organizations.OrganizationSerializer

  @spec call(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def call(conn, :get_all) do
    {:ok, organizations} = org_usecase().get_all(build_opts(conn))
    respond(conn, 200, OrganizationSerializer.serialize_many(organizations))
  end

  def call(conn, :search_by_name) do
    name = conn.query_params["name"]

    with {:ok, query} <- GetOrganizationByNameQuery.new(name),
         {:ok, orgs} <- org_usecase().get_by_name(query, build_opts(conn)) do
      respond(conn, 200, OrganizationSerializer.serialize_many_list(orgs))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :get_by_id) do
    id = conn.path_params["id"]

    with {:ok, query} <- GetOrganizationByIdQuery.new(id),
         {:ok, org} <- org_usecase().get_by_id(query, build_opts(conn)) do
      respond(conn, 200, OrganizationSerializer.serialize(org))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :create) do
    name = conn.body_params["name"]
    tribes = conn.body_params["tribes"] || []

    with {:ok, cmd} <- CreateOrganizationCommand.new(name, tribes),
         {:ok, org} <- org_usecase().add(cmd, build_opts(conn)) do
      respond(conn, 201, OrganizationSerializer.serialize(org))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :delete) do
    id = conn.path_params["id"]

    with {:ok, cmd} <- DeleteOrganizationCommand.new(id),
         {:ok, org} <- org_usecase().delete(cmd, build_opts(conn)) do
      respond(conn, 200, OrganizationSerializer.serialize(org))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  defp org_usecase do
    Application.get_env(
      :web_api,
      :organization_usecase,
      KanbanVisionApi.WebApi.Adapters.OrganizationAdapter
    )
  end

  defp build_opts(conn) do
    [correlation_id: conn.assigns[:correlation_id]]
  end

  defp respond(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp respond_error(conn, reason) do
    error = ErrorMapper.normalize(reason)
    respond(conn, ErrorMapper.http_status(error), %{error: error.message})
  end
end
