defmodule KanbanVisionApi.WebApi.Simulations.SimulationController do
  @moduledoc """
  HTTP adapter: translates HTTP requests to Simulation use case calls.

  Pure adapter — no business logic. Maps HTTP → Command/Query → use case → JSON response.
  Error mapping: :invalid_* → 422, "not found" → 404, "already exist" → 409, other → 500.
  """

  import Plug.Conn

  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand
  alias KanbanVisionApi.Usecase.Simulation.GetSimulationByOrgAndNameQuery
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
    {status, message} = map_error(reason)
    respond(conn, status, %{error: message})
  end

  defp map_error(:invalid_name), do: {422, "Invalid name"}
  defp map_error(:invalid_id), do: {422, "Invalid ID"}
  defp map_error(:invalid_organization_id), do: {422, "Invalid organization ID"}

  defp map_error(reason) when is_binary(reason) do
    cond do
      String.contains?(reason, "not found") -> {404, reason}
      String.contains?(reason, "already exist") -> {409, reason}
      true -> {500, reason}
    end
  end

  defp map_error(_), do: {500, "Internal server error"}
end
