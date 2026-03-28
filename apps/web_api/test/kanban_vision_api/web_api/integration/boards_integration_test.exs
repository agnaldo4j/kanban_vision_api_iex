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
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "QA Board"
      assert body["workflow"]["steps"] == []
      assert body["workers"] == []
    end
  end

  describe "board detail mutations" do
    test "renames board, manages workflow steps, and manages workers" do
      org = create_organization("BoardLifecycleOrg")
      sim = create_simulation("BoardLifecycleSim", org["id"])
      board = create_board("Lifecycle Board", sim["id"])
      register_cleanup(board_id: board["id"], simulation_id: sim["id"], organization_id: org["id"])

      renamed =
        :patch
        |> conn("/api/v1/boards/#{board["id"]}", Jason.encode!(%{name: "Renamed Board"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert renamed.status == 200
      assert Jason.decode!(renamed.resp_body)["name"] == "Renamed Board"

      add_step =
        :post
        |> conn(
          "/api/v1/boards/#{board["id"]}/workflow/steps",
          Jason.encode!(%{name: "In Progress", order: 0, required_ability_name: "Coding"})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert add_step.status == 200
      add_step_body = Jason.decode!(add_step.resp_body)
      [step] = add_step_body["workflow"]["steps"]
      assert step["name"] == "In Progress"
      assert step["order"] == 0
      assert step["required_ability"]["name"] == "Coding"

      reorder_step =
        :patch
        |> conn(
          "/api/v1/boards/#{board["id"]}/workflow/steps/#{step["id"]}/order",
          Jason.encode!(%{order: 0})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert reorder_step.status == 200

      allocate_worker =
        :post
        |> conn(
          "/api/v1/boards/#{board["id"]}/workers",
          Jason.encode!(%{name: "Alice", abilities: ["Coding", "Review"]})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert allocate_worker.status == 200
      allocate_worker_body = Jason.decode!(allocate_worker.resp_body)
      [worker] = allocate_worker_body["workers"]
      assert worker["name"] == "Alice"
      assert Enum.map(worker["abilities"], & &1["name"]) == ["Coding", "Review"]

      remove_worker =
        :delete
        |> conn("/api/v1/boards/#{board["id"]}/workers/#{worker["id"]}")
        |> Router.call(@opts)

      assert remove_worker.status == 200
      assert Jason.decode!(remove_worker.resp_body)["workers"] == []

      remove_step =
        :delete
        |> conn("/api/v1/boards/#{board["id"]}/workflow/steps/#{step["id"]}")
        |> Router.call(@opts)

      assert remove_step.status == 200
      assert Jason.decode!(remove_step.resp_body)["workflow"]["steps"] == []
    end

    test "returns 409 for duplicate board rename and duplicate worker allocation" do
      org = create_organization("BoardConflictOrg")
      sim = create_simulation("BoardConflictSim", org["id"])
      board_a = create_board("Alpha Board", sim["id"])
      board_b = create_board("Beta Board", sim["id"])

      register_cleanup(
        board_id: board_a["id"],
        simulation_id: sim["id"],
        organization_id: org["id"]
      )

      register_cleanup(board_id: board_b["id"])

      rename_conflict =
        :patch
        |> conn("/api/v1/boards/#{board_b["id"]}", Jason.encode!(%{name: "Alpha Board"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert rename_conflict.status == 409

      first_worker =
        :post
        |> conn(
          "/api/v1/boards/#{board_a["id"]}/workers",
          Jason.encode!(%{name: "Alice", abilities: ["Coding"]})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert first_worker.status == 200

      duplicate_worker =
        :post
        |> conn(
          "/api/v1/boards/#{board_a["id"]}/workers",
          Jason.encode!(%{name: "Alice", abilities: ["Review"]})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert duplicate_worker.status == 409
    end

    test "returns 404 for unknown workflow step and unknown worker removal" do
      org = create_organization("BoardNotFoundOrg")
      sim = create_simulation("BoardNotFoundSim", org["id"])
      board = create_board("Support Board", sim["id"])
      register_cleanup(board_id: board["id"], simulation_id: sim["id"], organization_id: org["id"])

      missing_step =
        :delete
        |> conn("/api/v1/boards/#{board["id"]}/workflow/steps/step-404")
        |> Router.call(@opts)

      assert missing_step.status == 404

      missing_worker =
        :delete
        |> conn("/api/v1/boards/#{board["id"]}/workers/worker-404")
        |> Router.call(@opts)

      assert missing_worker.status == 404
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
