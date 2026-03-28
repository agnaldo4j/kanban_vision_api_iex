defmodule KanbanVisionApi.WebApi.Integration.BoardsIntegrationTest do
  @moduledoc """
  Integration tests for Board HTTP endpoints.
  """

  use ExUnit.Case, async: false

  @moduletag :integration

  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.WebApi.Router

  @opts Router.init([])

  describe "GET /api/v1/simulations/:simulation_id/boards" do
    test "returns boards for a simulation" do
      org = create_organization("BoardOrg")
      sim = create_simulation("BoardSim", org["id"])
      board = create_board("Dev Board", sim["id"])
      register_cleanup(board_id: board["id"], simulation_id: sim["id"], organization_id: org["id"])

      conn =
        :get
        |> conn("/api/v1/simulations/#{sim["id"]}/boards")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Enum.any?(body, fn item -> item["id"] == board["id"] end)
    end
  end

  describe "POST /api/v1/simulations/:simulation_id/boards" do
    test "creates a board and returns 201" do
      org = create_organization("CreateBoardOrg")
      sim = create_simulation("CreateBoardSim", org["id"])
      register_cleanup(simulation_id: sim["id"], organization_id: org["id"])

      conn =
        :post
        |> conn("/api/v1/simulations/#{sim["id"]}/boards", Jason.encode!(%{name: "Dev Board"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Dev Board"
      assert body["simulation_id"] == sim["id"]
      register_cleanup(board_id: body["id"])
    end

    test "returns 409 when board already exists" do
      org = create_organization("ConflictBoardOrg")
      sim = create_simulation("ConflictBoardSim", org["id"])
      board = create_board("Dev Board", sim["id"])
      register_cleanup(board_id: board["id"], simulation_id: sim["id"], organization_id: org["id"])

      conn =
        :post
        |> conn("/api/v1/simulations/#{sim["id"]}/boards", Jason.encode!(%{name: "Dev Board"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 409
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["error"])
      assert body["error"] != ""
    end
  end

  describe "GET /api/v1/boards/:id" do
    test "returns board by id" do
      org = create_organization("GetBoardOrg")
      sim = create_simulation("GetBoardSim", org["id"])
      board = create_board("QA Board", sim["id"])
      register_cleanup(board_id: board["id"], simulation_id: sim["id"], organization_id: org["id"])

      conn =
        :get
        |> conn("/api/v1/boards/#{board["id"]}")
        |> Router.call(@opts)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["name"] == "QA Board"
    end
  end

  describe "DELETE /api/v1/boards/:id" do
    test "deletes a board and returns 200" do
      org = create_organization("DeleteBoardOrg")
      sim = create_simulation("DeleteBoardSim", org["id"])
      board = create_board("Delete Board", sim["id"])
      register_cleanup(simulation_id: sim["id"], organization_id: org["id"])

      conn =
        :delete
        |> conn("/api/v1/boards/#{board["id"]}")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "returns 404 for non-existent board" do
      conn =
        :delete
        |> conn("/api/v1/boards/non-existent-id")
        |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  defp register_cleanup(resources) do
    on_exit(fn ->
      if board_id = resources[:board_id] do
        cleanup_board(board_id)
      end

      if simulation_id = resources[:simulation_id] do
        cleanup_simulation(simulation_id)
      end

      if organization_id = resources[:organization_id] do
        cleanup_organization(organization_id)
      end
    end)
  end

  defp create_organization(name) do
    conn =
      :post
      |> conn("/api/v1/organizations", Jason.encode!(%{name: name}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    Jason.decode!(conn.resp_body)
  end

  defp create_simulation(name, org_id) do
    conn =
      :post
      |> conn("/api/v1/simulations", Jason.encode!(%{name: name, organization_id: org_id}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    Jason.decode!(conn.resp_body)
  end

  defp create_board(name, simulation_id) do
    conn =
      :post
      |> conn("/api/v1/simulations/#{simulation_id}/boards", Jason.encode!(%{name: name}))
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    Jason.decode!(conn.resp_body)
  end

  defp cleanup_board(id) do
    :delete
    |> conn("/api/v1/boards/#{id}")
    |> Router.call(@opts)
  end

  defp cleanup_simulation(id) do
    :delete
    |> conn("/api/v1/simulations/#{id}")
    |> Router.call(@opts)
  end

  defp cleanup_organization(id) do
    :delete
    |> conn("/api/v1/organizations/#{id}")
    |> Router.call(@opts)
  end
end
