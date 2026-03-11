defmodule KanbanVisionApi.WebApi.Integration.SimulationsIntegrationTest do
  @moduledoc """
  Integration tests for Simulation HTTP endpoints.

  Uses the real GenServer and router — no mocks.
  Run with: mix test --only integration
  """

  use ExUnit.Case, async: false

  @moduletag :integration

  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.WebApi.Router

  @opts Router.init([])

  describe "GET /api/v1/simulations" do
    test "returns 200 with JSON array" do
      conn =
        :get
        |> conn("/api/v1/simulations")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body)
    end
  end

  describe "POST /api/v1/simulations" do
    test "creates a simulation and returns 201" do
      org = create_organization("SimOrg")

      conn =
        :post
        |> conn(
          "/api/v1/simulations",
          Jason.encode!(%{name: "Sprint 1", organization_id: org["id"]})
        )
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Sprint 1"
      assert body["organization_id"] == org["id"]

      cleanup_simulation(body["id"])
      cleanup_organization(org["id"])
    end

    test "returns 422 when name is missing" do
      org = create_organization("SimOrg2")

      conn =
        :post
        |> conn("/api/v1/simulations", Jason.encode!(%{organization_id: org["id"]}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 422

      cleanup_organization(org["id"])
    end
  end

  describe "GET /api/v1/simulations/search" do
    test "returns simulation by org and name" do
      org = create_organization("SearchSimOrg")
      sim = create_simulation("MySimulation", org["id"])

      conn =
        :get
        |> conn("/api/v1/simulations/search?org_id=#{org["id"]}&name=MySimulation")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "MySimulation"

      cleanup_simulation(sim["id"])
      cleanup_organization(org["id"])
    end
  end

  describe "DELETE /api/v1/simulations/:id" do
    test "deletes a simulation and returns 200" do
      org = create_organization("DeleteSimOrg")
      sim = create_simulation("DeleteMe", org["id"])

      conn =
        :delete
        |> conn("/api/v1/simulations/#{sim["id"]}")
        |> Router.call(@opts)

      assert conn.status == 200

      cleanup_organization(org["id"])
    end

    test "returns 404 for non-existent simulation" do
      conn =
        :delete
        |> conn("/api/v1/simulations/non-existent-id")
        |> Router.call(@opts)

      assert conn.status == 404
    end
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
