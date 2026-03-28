defmodule KanbanVisionApi.WebApi.Router do
  @moduledoc """
  HTTP router: wires all routes to their controller adapters.

  Plug pipeline: CorrelationId → RequestLogger → PutApiSpec → Parsers → match → dispatch.
  Route ordering: /search paths appear before /:id to avoid "search" matching as an ID.
  """

  use Plug.Router

  alias KanbanVisionApi.WebApi.Boards.BoardController
  alias KanbanVisionApi.WebApi.OpenApi.Spec
  alias KanbanVisionApi.WebApi.Organizations.OrganizationController
  alias KanbanVisionApi.WebApi.Plugs.CorrelationId
  alias KanbanVisionApi.WebApi.Plugs.RequestLogger
  alias KanbanVisionApi.WebApi.Simulations.SimulationController
  alias OpenApiSpex.Plug.PutApiSpec
  alias OpenApiSpex.Plug.RenderSpec
  alias OpenApiSpex.Plug.SwaggerUI

  plug CorrelationId
  plug RequestLogger
  plug PutApiSpec, module: Spec

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :fetch_query_params
  plug :match
  plug :dispatch

  # OpenAPI documentation routes

  get "/api/openapi" do
    opts = RenderSpec.init([])
    RenderSpec.call(conn, opts)
  end

  get "/api/swagger" do
    opts = SwaggerUI.init(path: "/api/openapi")
    SwaggerUI.call(conn, opts)
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

  # Board routes

  get "/api/v1/simulations/:simulation_id/boards" do
    BoardController.call(conn, :get_by_simulation_id)
  end

  post "/api/v1/simulations/:simulation_id/boards" do
    BoardController.call(conn, :create)
  end

  get "/api/v1/boards/:id" do
    BoardController.call(conn, :get_by_id)
  end

  patch "/api/v1/boards/:id" do
    BoardController.call(conn, :rename)
  end

  post "/api/v1/boards/:id/workflow/steps" do
    BoardController.call(conn, :add_workflow_step)
  end

  delete "/api/v1/boards/:id/workflow/steps/:step_id" do
    BoardController.call(conn, :remove_workflow_step)
  end

  patch "/api/v1/boards/:id/workflow/steps/:step_id/order" do
    BoardController.call(conn, :reorder_workflow_step)
  end

  post "/api/v1/boards/:id/workers" do
    BoardController.call(conn, :allocate_worker)
  end

  delete "/api/v1/boards/:id/workers/:worker_id" do
    BoardController.call(conn, :remove_worker)
  end

  delete "/api/v1/boards/:id" do
    BoardController.call(conn, :delete)
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end
end
