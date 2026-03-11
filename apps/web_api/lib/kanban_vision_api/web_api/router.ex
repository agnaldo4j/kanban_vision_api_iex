defmodule KanbanVisionApi.WebApi.Router do
  @moduledoc """
  HTTP router: wires all routes to their controller adapters.

  Plug pipeline: CorrelationId → RequestLogger → PutApiSpec → Parsers → match → dispatch.
  Route ordering: /search paths appear before /:id to avoid "search" matching as an ID.
  """

  use Plug.Router

  alias KanbanVisionApi.WebApi.OpenApi.Spec
  alias KanbanVisionApi.WebApi.Organizations.OrganizationController
  alias KanbanVisionApi.WebApi.Plugs.CorrelationId
  alias KanbanVisionApi.WebApi.Plugs.RequestLogger
  alias KanbanVisionApi.WebApi.Simulations.SimulationController

  plug CorrelationId
  plug RequestLogger
  plug OpenApiSpex.Plug.PutApiSpec, module: Spec

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :fetch_query_params
  plug :match
  plug :dispatch

  # OpenAPI documentation routes

  get "/api/openapi" do
    opts = OpenApiSpex.Plug.RenderSpec.init([])
    OpenApiSpex.Plug.RenderSpec.call(conn, opts)
  end

  get "/api/swagger" do
    opts = OpenApiSpex.Plug.SwaggerUI.init(path: "/api/openapi")
    OpenApiSpex.Plug.SwaggerUI.call(conn, opts)
  end

  # Organization routes — /search before /:id

  get "/api/v1/organizations/search" do
    OrganizationController.call(conn, :search_by_name)
  end

  get "/api/v1/organizations/:id" do
    OrganizationController.call(conn, :get_by_id)
  end

  get "/api/v1/organizations" do
    OrganizationController.call(conn, :get_all)
  end

  post "/api/v1/organizations" do
    OrganizationController.call(conn, :create)
  end

  delete "/api/v1/organizations/:id" do
    OrganizationController.call(conn, :delete)
  end

  # Simulation routes — /search before /:id

  get "/api/v1/simulations/search" do
    SimulationController.call(conn, :search_by_org_and_name)
  end

  get "/api/v1/simulations" do
    SimulationController.call(conn, :get_all)
  end

  post "/api/v1/simulations" do
    SimulationController.call(conn, :create)
  end

  delete "/api/v1/simulations/:id" do
    SimulationController.call(conn, :delete)
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end
end
