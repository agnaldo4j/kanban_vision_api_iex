defmodule KanbanVisionApi.WebApi.Simulations.SimulationControllerTest do
  use ExUnit.Case, async: false

  import Mox
  import Plug.Test

  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.WebApi.SimulationUsecaseMock
  alias KanbanVisionApi.WebApi.Simulations.SimulationController

  setup :verify_on_exit!

  setup do
    Application.put_env(:web_api, :simulation_usecase, SimulationUsecaseMock)
    on_exit(fn -> Application.delete_env(:web_api, :simulation_usecase) end)
    sim = Simulation.new("Sprint 1", "A sprint", "org-123")
    %{sim: sim}
  end

  describe "call/2 :get_all" do
    test "returns 200 with list of simulations", %{sim: sim} do
      expect(SimulationUsecaseMock, :get_all, fn _opts ->
        {:ok, %{"org-123" => %{sim.id => sim}}}
      end)

      conn =
        :get
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> SimulationController.call(:get_all)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body) == 1
      assert hd(body)["name"] == "Sprint 1"
    end

    test "returns 200 with empty list when no simulations" do
      expect(SimulationUsecaseMock, :get_all, fn _opts ->
        {:ok, %{}}
      end)

      conn =
        :get
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> SimulationController.call(:get_all)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == []
    end
  end

  describe "call/2 :search_by_org_and_name" do
    test "returns 200 with matching simulation", %{sim: sim} do
      expect(SimulationUsecaseMock, :get_by_org_and_name, fn _query, _opts ->
        {:ok, sim}
      end)

      conn =
        :get
        |> conn("/api/v1/simulations/search?org_id=org-123&name=Sprint+1")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> SimulationController.call(:search_by_org_and_name)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Sprint 1"
    end

    test "returns 422 when org_id is missing" do
      conn =
        :get
        |> conn("/api/v1/simulations/search?name=Sprint+1")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> SimulationController.call(:search_by_org_and_name)

      assert conn.status == 422
    end

    test "returns 404 when simulation not found" do
      expect(SimulationUsecaseMock, :get_by_org_and_name, fn _query, _opts ->
        {:error, "not found"}
      end)

      conn =
        :get
        |> conn("/api/v1/simulations/search?org_id=org-123&name=Missing")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Plug.Conn.fetch_query_params()
        |> SimulationController.call(:search_by_org_and_name)

      assert conn.status == 404
    end
  end

  describe "call/2 :create" do
    test "returns 201 with created simulation", %{sim: sim} do
      expect(SimulationUsecaseMock, :add, fn _cmd, _opts ->
        {:ok, sim}
      end)

      conn =
        :post
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => "Sprint 1", "organization_id" => "org-123"})
        |> SimulationController.call(:create)

      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Sprint 1"
    end

    test "returns 422 when name is missing" do
      conn =
        :post
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"organization_id" => "org-123"})
        |> SimulationController.call(:create)

      assert conn.status == 422
    end

    test "returns 422 when organization_id is missing" do
      conn =
        :post
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => "Sprint 1"})
        |> SimulationController.call(:create)

      assert conn.status == 422
    end

    test "returns 409 when simulation already exists" do
      expect(SimulationUsecaseMock, :add, fn _cmd, _opts ->
        {:error, "already exist"}
      end)

      conn =
        :post
        |> conn("/api/v1/simulations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:body_params, %{"name" => "Sprint 1", "organization_id" => "org-123"})
        |> SimulationController.call(:create)

      assert conn.status == 409
    end
  end

  describe "call/2 :delete" do
    test "returns 200 with deleted simulation", %{sim: sim} do
      expect(SimulationUsecaseMock, :delete, fn _cmd, _opts ->
        {:ok, sim}
      end)

      conn =
        :delete
        |> conn("/api/v1/simulations/#{sim.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => sim.id})
        |> SimulationController.call(:delete)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Sprint 1"
    end

    test "returns 404 when simulation not found", %{sim: sim} do
      expect(SimulationUsecaseMock, :delete, fn _cmd, _opts ->
        {:error, "not found"}
      end)

      conn =
        :delete
        |> conn("/api/v1/simulations/#{sim.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => sim.id})
        |> SimulationController.call(:delete)

      assert conn.status == 404
    end
  end
end
