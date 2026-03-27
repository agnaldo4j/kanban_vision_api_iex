defmodule KanbanVisionApi.WebApi.Integration.OrganizationsIntegrationTest do
  @moduledoc """
  Integration tests for Organization HTTP endpoints.

  Uses the real GenServer and router — no mocks.
  Run with: mix test --only integration
  """

  use ExUnit.Case, async: false

  @moduletag :integration

  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.WebApi.Router

  @opts Router.init([])

  describe "GET /api/v1/organizations" do
    test "returns 200 with JSON array" do
      conn =
        :get
        |> conn("/api/v1/organizations")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body)
    end
  end

  describe "POST /api/v1/organizations" do
    test "creates an organization and returns 201" do
      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{name: "Integration Org"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Integration Org"
      assert body["id"] != nil

      cleanup_organization(body["id"])
    end

    test "returns 422 when name is missing" do
      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 422
    end

    test "returns 409 when organization already exists" do
      org = create_organization("Duplicated Integration Org")

      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{name: "Duplicated Integration Org"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 409
      assert Jason.decode!(conn.resp_body)["error"] ==
               "Organization with name: Duplicated Integration Org already exist"

      cleanup_organization(org["id"])
    end
  end

  describe "GET /api/v1/organizations/:id" do
    test "returns 200 for existing organization" do
      org = create_organization("Lookup Org")

      conn =
        :get
        |> conn("/api/v1/organizations/#{org["id"]}")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Lookup Org"

      cleanup_organization(org["id"])
    end

    test "returns 404 for non-existent organization" do
      conn =
        :get
        |> conn("/api/v1/organizations/non-existent-id")
        |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  describe "GET /api/v1/organizations/search" do
    test "returns matching organizations by name" do
      org = create_organization("SearchableOrg")

      conn =
        :get
        |> conn("/api/v1/organizations/search?name=SearchableOrg")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Enum.any?(body, fn o -> o["name"] == "SearchableOrg" end)

      cleanup_organization(org["id"])
    end
  end

  describe "DELETE /api/v1/organizations/:id" do
    test "deletes an organization and returns 200" do
      org = create_organization("DeleteMe Org")

      conn =
        :delete
        |> conn("/api/v1/organizations/#{org["id"]}")
        |> Router.call(@opts)

      assert conn.status == 200
    end

    test "returns 404 when organization not found" do
      conn =
        :delete
        |> conn("/api/v1/organizations/non-existent-id")
        |> Router.call(@opts)

      assert conn.status == 404
    end
  end

  describe "GET /api/openapi" do
    test "returns 200 with valid JSON spec" do
      conn =
        :get
        |> conn("/api/openapi")
        |> Router.call(@opts)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["openapi"] == "3.0.0"
      assert body["info"]["title"] == "Kanban Vision API"
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

  defp cleanup_organization(id) do
    :delete
    |> conn("/api/v1/organizations/#{id}")
    |> Router.call(@opts)
  end
end
