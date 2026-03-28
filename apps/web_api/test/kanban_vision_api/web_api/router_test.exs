defmodule KanbanVisionApi.WebApi.RouterTest do
  @moduledoc """
  Unit tests for the router — verifies route dispatch using Mox stubs.
  """

  use ExUnit.Case, async: false

  import Mox
  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.WebApi.BoardUsecaseMock
  alias KanbanVisionApi.WebApi.OrganizationUsecaseMock
  alias KanbanVisionApi.WebApi.Router
  alias KanbanVisionApi.WebApi.SimulationUsecaseMock

  @opts Router.init([])

  setup :verify_on_exit!

  setup do
    Application.put_env(:web_api, :organization_usecase, OrganizationUsecaseMock)
    Application.put_env(:web_api, :simulation_usecase, SimulationUsecaseMock)
    Application.put_env(:web_api, :board_usecase, BoardUsecaseMock)

    on_exit(fn ->
      Application.delete_env(:web_api, :board_usecase)
      Application.delete_env(:web_api, :organization_usecase)
      Application.delete_env(:web_api, :simulation_usecase)
    end)

    org = Organization.new("RouterTestOrg")
    sim = Simulation.new("RouterTestSim", "desc", org.id)
    board = Board.new("RouterTestBoard", sim.id)
    %{org: org, sim: sim, board: board}
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

  describe "Board routes" do
    test "GET /api/v1/simulations/:simulation_id/boards dispatches to get_by_simulation_id", %{
      board: board
    } do
      stub(BoardUsecaseMock, :get_by_simulation_id, fn _query, _opts -> {:ok, [board]} end)

      conn = conn(:get, "/api/v1/simulations/#{board.simulation_id}/boards") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "POST /api/v1/simulations/:simulation_id/boards dispatches to create", %{board: board} do
      stub(BoardUsecaseMock, :add, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :post
        |> conn(
          "/api/v1/simulations/#{board.simulation_id}/boards",
          Jason.encode!(%{name: "RouterTestBoard"})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
    end

    test "GET /api/v1/boards/:id dispatches to get_by_id", %{board: board} do
      stub(BoardUsecaseMock, :get_by_id, fn _query, _opts -> {:ok, board} end)

      conn = conn(:get, "/api/v1/boards/#{board.id}") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "PATCH /api/v1/boards/:id dispatches to rename", %{board: board} do
      renamed_board = %{board | name: "Renamed Board"}
      stub(BoardUsecaseMock, :rename, fn _cmd, _opts -> {:ok, renamed_board} end)

      conn =
        :patch
        |> conn("/api/v1/boards/#{board.id}", Jason.encode!(%{name: "Renamed Board"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "POST /api/v1/boards/:id/workflow/steps dispatches to add_workflow_step", %{board: board} do
      stub(BoardUsecaseMock, :add_workflow_step, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :post
        |> conn(
          "/api/v1/boards/#{board.id}/workflow/steps",
          Jason.encode!(%{name: "In Progress", order: 0, required_ability_name: "Coding"})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "PATCH /api/v1/boards/:id/workflow/steps/:step_id/order dispatches to reorder_workflow_step", %{board: board} do
      stub(BoardUsecaseMock, :reorder_workflow_step, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :patch
        |> conn("/api/v1/boards/#{board.id}/workflow/steps/step-1/order", Jason.encode!(%{order: 0}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "DELETE /api/v1/boards/:id/workflow/steps/:step_id dispatches to remove_workflow_step", %{board: board} do
      stub(BoardUsecaseMock, :remove_workflow_step, fn _cmd, _opts -> {:ok, board} end)

      conn = conn(:delete, "/api/v1/boards/#{board.id}/workflow/steps/step-1") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "POST /api/v1/boards/:id/workers dispatches to allocate_worker", %{board: board} do
      stub(BoardUsecaseMock, :allocate_worker, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :post
        |> conn("/api/v1/boards/#{board.id}/workers", Jason.encode!(%{name: "Alice", abilities: ["Coding"]}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "DELETE /api/v1/boards/:id/workers/:worker_id dispatches to remove_worker", %{board: board} do
      stub(BoardUsecaseMock, :remove_worker, fn _cmd, _opts -> {:ok, board} end)

      conn = conn(:delete, "/api/v1/boards/#{board.id}/workers/worker-1") |> Router.call(@opts)

      assert conn.status == 200
    end

    test "DELETE /api/v1/boards/:id dispatches to delete", %{board: board} do
      stub(BoardUsecaseMock, :delete, fn _cmd, _opts -> {:ok, board} end)

      conn = conn(:delete, "/api/v1/boards/#{board.id}") |> Router.call(@opts)

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
