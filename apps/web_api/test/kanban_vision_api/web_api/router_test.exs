defmodule KanbanVisionApi.WebApi.RouterTest do
  @moduledoc """
  Unit tests for the router — verifies route dispatch using Mox stubs.
  """

  use ExUnit.Case, async: false

  import Mox
  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.WebApi.OrganizationUsecaseMock
  alias KanbanVisionApi.WebApi.Router
  alias KanbanVisionApi.WebApi.SimulationUsecaseMock

  @opts Router.init([])

  setup :verify_on_exit!

  setup do
    Application.put_env(:web_api, :organization_usecase, OrganizationUsecaseMock)
    Application.put_env(:web_api, :simulation_usecase, SimulationUsecaseMock)

    on_exit(fn ->
      Application.delete_env(:web_api, :organization_usecase)
      Application.delete_env(:web_api, :simulation_usecase)
    end)

    org = Organization.new("RouterTestOrg")
    sim = Simulation.new("RouterTestSim", "desc", org.id)
    %{org: org, sim: sim}
  end

  describe "Organization routes" do
    test "GET /api/v1/organizations dispatches to get_all", %{org: org} do
      stub(OrganizationUsecaseMock, :get_all, fn _opts -> {:ok, %{org.id => org}} end)

      conn = conn(:get, "/api/v1/organizations") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "GET /api/v1/organizations/search dispatches to search_by_name", %{org: org} do
      stub(OrganizationUsecaseMock, :get_by_name, fn _query, _opts -> {:ok, [org]} end)

      conn = conn(:get, "/api/v1/organizations/search?name=RouterTestOrg") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "GET /api/v1/organizations/:id dispatches to get_by_id", %{org: org} do
      stub(OrganizationUsecaseMock, :get_by_id, fn _query, _opts -> {:ok, org} end)

      conn = conn(:get, "/api/v1/organizations/#{org.id}") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "POST /api/v1/organizations dispatches to create", %{org: org} do
      stub(OrganizationUsecaseMock, :add, fn _cmd, _opts -> {:ok, org} end)

      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{name: "RouterTestOrg"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
    end

    test "DELETE /api/v1/organizations/:id dispatches to delete", %{org: org} do
      stub(OrganizationUsecaseMock, :delete, fn _cmd, _opts -> {:ok, org} end)

      conn = conn(:delete, "/api/v1/organizations/#{org.id}") |> Router.call(@opts)

      assert conn.status == 200
    end
  end

  describe "Simulation routes" do
    test "GET /api/v1/simulations dispatches to get_all", %{sim: sim} do
      stub(SimulationUsecaseMock, :get_all, fn _opts ->
        {:ok, %{sim.organization_id => %{sim.id => sim}}}
      end)

      conn = conn(:get, "/api/v1/simulations") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "GET /api/v1/simulations/search dispatches to search_by_org_and_name", %{sim: sim} do
      stub(SimulationUsecaseMock, :get_by_org_and_name, fn _query, _opts -> {:ok, sim} end)

      conn =
        conn(:get, "/api/v1/simulations/search?org_id=#{sim.organization_id}&name=RouterTestSim")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "POST /api/v1/simulations dispatches to create", %{sim: sim} do
      stub(SimulationUsecaseMock, :add, fn _cmd, _opts -> {:ok, sim} end)

      conn =
        :post
        |> conn(
          "/api/v1/simulations",
          Jason.encode!(%{name: "RouterTestSim", organization_id: sim.organization_id})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
    end

    test "DELETE /api/v1/simulations/:id dispatches to delete", %{sim: sim} do
      stub(SimulationUsecaseMock, :delete, fn _cmd, _opts -> {:ok, sim} end)

      conn = conn(:delete, "/api/v1/simulations/#{sim.id}") |> Router.call(@opts)

      assert conn.status == 200
    end
  end

  describe "OpenAPI routes" do
    test "GET /api/openapi returns JSON spec" do
      conn = conn(:get, "/api/openapi") |> Router.call(@opts)

      assert conn.status == 200
      [content_type | _] = get_resp_header(conn, "content-type")
      assert String.contains?(content_type, "application/json")
    end

    test "GET /api/swagger returns Swagger UI HTML" do
      conn = conn(:get, "/api/swagger") |> Router.call(@opts)

      assert conn.status == 200
    end
  end

  describe "Fallback route" do
    test "unknown path returns 404 JSON" do
      conn = conn(:get, "/unknown/route") |> Router.call(@opts)

      assert conn.status == 404
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "Not found"
    end
  end
end
