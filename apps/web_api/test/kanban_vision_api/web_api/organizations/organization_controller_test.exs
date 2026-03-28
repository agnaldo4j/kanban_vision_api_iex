defmodule KanbanVisionApi.WebApi.Organizations.OrganizationControllerTest do
  use ExUnit.Case, async: false

  import Mox
  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.Domain.Organization
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.WebApi.Organizations.OrganizationController
  alias KanbanVisionApi.WebApi.OrganizationUsecaseMock

  setup :verify_on_exit!

  setup do
    Application.put_env(:web_api, :organization_usecase, OrganizationUsecaseMock)
    on_exit(fn -> Application.delete_env(:web_api, :organization_usecase) end)
    org = Organization.new("Acme Corp")
    %{org: org}
  end

  describe "call/2 :get_all" do
    test "returns 200 with list of organizations", %{org: org} do
      expect(OrganizationUsecaseMock, :get_all, fn _opts ->
        {:ok, %{org.id => org}}
      end)

      conn =
        :get
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> OrganizationController.call(:get_all)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body) == 1
      assert hd(body)["name"] == "Acme Corp"
    end

    test "returns 200 with empty list when no organizations" do
      expect(OrganizationUsecaseMock, :get_all, fn _opts ->
        {:ok, %{}}
      end)

      conn =
        :get
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> OrganizationController.call(:get_all)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == []
    end
  end

  describe "call/2 :search_by_name" do
    test "returns 200 with matching organizations", %{org: org} do
      expect(OrganizationUsecaseMock, :get_by_name, fn _query, _opts ->
        {:ok, [org]}
      end)

      conn =
        :get
        |> conn("/api/v1/organizations/search?name=Acme")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> OrganizationController.call(:search_by_name)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body) == 1
    end

    test "returns 422 when name is missing" do
      conn =
        :get
        |> conn("/api/v1/organizations/search")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> OrganizationController.call(:search_by_name)

      assert conn.status == 422
    end

    test "returns 404 when no organizations found" do
      expect(OrganizationUsecaseMock, :get_by_name, fn _query, _opts ->
        ApplicationError.not_found("Organization with name: Unknown not found", %{})
      end)

      conn =
        :get
        |> conn("/api/v1/organizations/search?name=Unknown")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> OrganizationController.call(:search_by_name)

      assert conn.status == 404
    end
  end

  describe "call/2 :get_by_id" do
    test "returns 200 with organization", %{org: org} do
      expect(OrganizationUsecaseMock, :get_by_id, fn _query, _opts ->
        {:ok, org}
      end)

      conn =
        :get
        |> conn("/api/v1/organizations/#{org.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => org.id})
        |> OrganizationController.call(:get_by_id)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Acme Corp"
    end

    test "returns 404 when organization not found", %{org: org} do
      expect(OrganizationUsecaseMock, :get_by_id, fn _query, _opts ->
        ApplicationError.not_found("Organization with id: #{org.id} not found", %{})
      end)

      conn =
        :get
        |> conn("/api/v1/organizations/#{org.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => org.id})
        |> OrganizationController.call(:get_by_id)

      assert conn.status == 404
    end

    test "returns 422 when id is invalid" do
      conn =
        :get
        |> conn("/api/v1/organizations/  ")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => ""})
        |> OrganizationController.call(:get_by_id)

      assert conn.status == 422
    end
  end

  describe "call/2 :create" do
    test "returns 201 with created organization", %{org: org} do
      expect(OrganizationUsecaseMock, :add, fn _cmd, _opts ->
        {:ok, org}
      end)

      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{name: "Acme Corp"}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => "Acme Corp"})
        |> OrganizationController.call(:create)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Acme Corp"
    end

    test "returns 422 when name is missing" do
      conn =
        :post
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{})
        |> OrganizationController.call(:create)

      assert conn.status == 422
    end

    test "returns 409 when organization already exists", %{org: org} do
      expect(OrganizationUsecaseMock, :add, fn _cmd, _opts ->
        ApplicationError.conflict("Organization with name: #{org.name} already exist", %{})
      end)

      conn =
        :post
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => org.name})
        |> OrganizationController.call(:create)

      assert conn.status == 409
    end
  end

  describe "call/2 :delete" do
    test "returns 200 with deleted organization", %{org: org} do
      expect(OrganizationUsecaseMock, :delete, fn _cmd, _opts ->
        {:ok, org}
      end)

      conn =
        :delete
        |> conn("/api/v1/organizations/#{org.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => org.id})
        |> OrganizationController.call(:delete)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Acme Corp"
    end

    test "returns 404 when organization not found", %{org: org} do
      expect(OrganizationUsecaseMock, :delete, fn _cmd, _opts ->
        ApplicationError.not_found("Organization with id: #{org.id} not found", %{})
      end)

      conn =
        :delete
        |> conn("/api/v1/organizations/#{org.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => org.id})
        |> OrganizationController.call(:delete)

      assert conn.status == 404
    end
  end

  describe "error mapping" do
    test "returns 422 for :invalid_tribes" do
      conn =
        :post
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => "Acme", "tribes" => "not-a-list"})
        |> OrganizationController.call(:create)

      assert conn.status == 422
    end

    test "returns 500 for a generic binary server error" do
      expect(OrganizationUsecaseMock, :delete, fn _cmd, _opts ->
        ApplicationError.internal_error("unexpected server failure", %{})
      end)

      conn =
        :delete
        |> conn("/api/v1/organizations/some-id")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => "some-id"})
        |> OrganizationController.call(:delete)

      assert conn.status == 500
      assert Jason.decode!(conn.resp_body)["error"] == "unexpected server failure"
    end

    test "returns 500 for an unknown error type" do
      expect(OrganizationUsecaseMock, :delete, fn _cmd, _opts ->
        {:error, :unexpected_error}
      end)

      conn =
        :delete
        |> conn("/api/v1/organizations/some-id")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => "some-id"})
        |> OrganizationController.call(:delete)

      assert conn.status == 500
    end
  end
end
