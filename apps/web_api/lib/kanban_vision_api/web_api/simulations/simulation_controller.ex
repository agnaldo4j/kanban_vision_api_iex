defmodule KanbanVisionApi.WebApi.Simulations.SimulationController do
  @moduledoc """
  HTTP adapter: translates HTTP requests to Simulation use case calls.

  Pure adapter — no business logic. Maps HTTP → Command/Query → use case → JSON response.
  Error mapping: validation atoms normalize to `:invalid_input`, structured application
  errors map by `code`, and transport logic never parses message text.
  """

  import Plug.Conn

  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery
  alias KanbanVisionApi.WebApi.ErrorMapper
  alias KanbanVisionApi.WebApi.Simulations.SimulationSerializer

  @spec call(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def call(conn, :get_all) do
    {:ok, simulations} = sim_usecase().get_all(build_opts(conn))
    respond(conn, 200, SimulationSerializer.serialize_many(simulations))
  end

  def call(conn, :search_by_org_and_name) do
    org_id = conn.query_params["org_id"]
    name = conn.query_params["name"]

    with {:ok, query} <- GetSimulationByOrgAndNameQuery.new(org_id, name),
         {:ok, sim} <- sim_usecase().get_by_org_and_name(query, build_opts(conn)) do
      respond(conn, 200, SimulationSerializer.serialize(sim))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :create) do
    name = conn.body_params["name"]
    organization_id = conn.body_params["organization_id"]
    description = conn.body_params["description"]

    with {:ok, cmd} <- CreateSimulationCommand.new(name, organization_id, description),
         {:ok, sim} <- sim_usecase().add(cmd, build_opts(conn)) do
      respond(conn, 201, SimulationSerializer.serialize(sim))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :delete) do
    id = conn.path_params["id"]

    with {:ok, cmd} <- DeleteSimulationCommand.new(id),
         {:ok, sim} <- sim_usecase().delete(cmd, build_opts(conn)) do
      respond(conn, 200, SimulationSerializer.serialize(sim))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  defp sim_usecase do
    Application.get_env(
      :web_api,
      :simulation_usecase,
      KanbanVisionApi.WebApi.Adapters.SimulationAdapter
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
