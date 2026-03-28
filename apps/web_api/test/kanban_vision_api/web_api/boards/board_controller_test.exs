defmodule KanbanVisionApi.WebApi.Boards.BoardControllerTest do
  use ExUnit.Case, async: false

  import Mox
  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Board
  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.WebApi.Boards.BoardController
  alias KanbanVisionApi.WebApi.BoardUsecaseMock

  setup :verify_on_exit!

  setup do
    Application.put_env(:web_api, :board_usecase, BoardUsecaseMock)
    on_exit(fn -> Application.delete_env(:web_api, :board_usecase) end)
    board = Board.new("Dev Board", "sim-123")
    %{board: board}
  end

  describe "call/2 :get_by_simulation_id" do
    test "returns 200 with matching boards", %{board: board} do
      expect(BoardUsecaseMock, :get_by_simulation_id, fn _query, _opts ->
        {:ok, [board]}
      end)

      conn =
        :get
        |> conn("/api/v1/simulations/sim-123/boards")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => "sim-123"})
        |> BoardController.call(:get_by_simulation_id)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body) == 1
      assert hd(body)["name"] == "Dev Board"
    end

    test "returns 422 when simulation id is missing" do
      conn =
        :get
        |> conn("/api/v1/simulations//boards")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => ""})
        |> BoardController.call(:get_by_simulation_id)

      assert conn.status == 422
    end

    test "returns 404 when no boards are found" do
      expect(BoardUsecaseMock, :get_by_simulation_id, fn _query, _opts ->
        ApplicationError.not_found("Boards by simulation_id: sim-404 not found", %{})
      end)

      conn =
        :get
        |> conn("/api/v1/simulations/sim-404/boards")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => "sim-404"})
        |> BoardController.call(:get_by_simulation_id)

      assert conn.status == 404
    end
  end

  describe "call/2 :get_by_id" do
    test "returns 200 with board", %{board: board} do
      expect(BoardUsecaseMock, :get_by_id, fn _query, _opts -> {:ok, board} end)

      conn =
        :get
        |> conn("/api/v1/boards/#{board.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> BoardController.call(:get_by_id)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["name"] == "Dev Board"
    end

    test "returns 404 when board not found", %{board: board} do
      expect(BoardUsecaseMock, :get_by_id, fn _query, _opts ->
        ApplicationError.not_found("Board with id: #{board.id} not found", %{})
      end)

      conn =
        :get
        |> conn("/api/v1/boards/#{board.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> BoardController.call(:get_by_id)

      assert conn.status == 404
    end
  end

  describe "call/2 :create" do
    test "returns 201 with created board", %{board: board} do
      expect(BoardUsecaseMock, :add, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :post
        |> conn("/api/v1/simulations/sim-123/boards", Jason.encode!(%{name: "Dev Board"}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => "sim-123"})
        |> Map.put(:body_params, %{"name" => "Dev Board"})
        |> BoardController.call(:create)

      assert conn.status == 201
      assert Jason.decode!(conn.resp_body)["name"] == "Dev Board"
    end

    test "returns 422 when name is missing" do
      conn =
        :post
        |> conn("/api/v1/simulations/sim-123/boards")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => "sim-123"})
        |> Map.put(:body_params, %{})
        |> BoardController.call(:create)

      assert conn.status == 422
    end

    test "returns 409 when board already exists", %{board: board} do
      expect(BoardUsecaseMock, :add, fn _cmd, _opts ->
        ApplicationError.conflict(
          "Board with name: #{board.name} from simulation_id: #{board.simulation_id} already exists",
          %{}
        )
      end)

      conn =
        :post
        |> conn("/api/v1/simulations/sim-123/boards")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"simulation_id" => "sim-123"})
        |> Map.put(:body_params, %{"name" => board.name})
        |> BoardController.call(:create)

      assert conn.status == 409
    end
  end

  describe "call/2 :delete" do
    test "returns 200 with deleted board", %{board: board} do
      expect(BoardUsecaseMock, :delete, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :delete
        |> conn("/api/v1/boards/#{board.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> BoardController.call(:delete)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["name"] == "Dev Board"
    end

    test "returns 404 when board not found", %{board: board} do
      expect(BoardUsecaseMock, :delete, fn _cmd, _opts ->
        ApplicationError.not_found("Board with id: #{board.id} not found", %{})
      end)

      conn =
        :delete
        |> conn("/api/v1/boards/#{board.id}")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> BoardController.call(:delete)

      assert conn.status == 404
    end
  end

  describe "call/2 :rename" do
    test "returns 200 with renamed board", %{board: board} do
      renamed_board = %{board | name: "Renamed Board"}
      expect(BoardUsecaseMock, :rename, fn _cmd, _opts -> {:ok, renamed_board} end)

      conn =
        :patch
        |> conn("/api/v1/boards/#{board.id}", Jason.encode!(%{name: "Renamed Board"}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> Map.put(:body_params, %{"name" => "Renamed Board"})
        |> BoardController.call(:rename)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["name"] == "Renamed Board"
    end
  end

  describe "call/2 :add_workflow_step" do
    test "returns 200 with board detail after adding a step", %{board: board} do
      step = Step.new("In Progress", 0, [], Ability.new("Coding"))
      updated_board = %{board | workflow: %{board.workflow | steps: [step]}}

      expect(BoardUsecaseMock, :add_workflow_step, fn _cmd, _opts -> {:ok, updated_board} end)

      conn =
        :post
        |> conn("/api/v1/boards/#{board.id}/workflow/steps", Jason.encode!(%{name: "In Progress", order: 0, required_ability_name: "Coding"}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> Map.put(:body_params, %{"name" => "In Progress", "order" => 0, "required_ability_name" => "Coding"})
        |> BoardController.call(:add_workflow_step)

      assert conn.status == 200
      assert hd(Jason.decode!(conn.resp_body)["workflow"]["steps"])["name"] == "In Progress"
    end
  end

  describe "call/2 :remove_workflow_step" do
    test "returns 200 with board detail after removing a step", %{board: board} do
      expect(BoardUsecaseMock, :remove_workflow_step, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :delete
        |> conn("/api/v1/boards/#{board.id}/workflow/steps/step-1")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id, "step_id" => "step-1"})
        |> BoardController.call(:remove_workflow_step)

      assert conn.status == 200
    end
  end

  describe "call/2 :reorder_workflow_step" do
    test "returns 200 with board detail after reordering a step", %{board: board} do
      expect(BoardUsecaseMock, :reorder_workflow_step, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :patch
        |> conn("/api/v1/boards/#{board.id}/workflow/steps/step-1/order", Jason.encode!(%{order: 0}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id, "step_id" => "step-1"})
        |> Map.put(:body_params, %{"order" => 0})
        |> BoardController.call(:reorder_workflow_step)

      assert conn.status == 200
    end
  end

  describe "call/2 :allocate_worker" do
    test "returns 200 with board detail after allocating worker", %{board: board} do
      worker = Worker.new("Alice", [Ability.new("Coding")])
      updated_board = %{board | workers: %{worker.id => worker}}

      expect(BoardUsecaseMock, :allocate_worker, fn _cmd, _opts -> {:ok, updated_board} end)

      conn =
        :post
        |> conn("/api/v1/boards/#{board.id}/workers", Jason.encode!(%{name: "Alice", abilities: ["Coding"]}))
        |> put_req_header("content-type", "application/json")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id})
        |> Map.put(:body_params, %{"name" => "Alice", "abilities" => ["Coding"]})
        |> BoardController.call(:allocate_worker)

      assert conn.status == 200
      assert hd(Jason.decode!(conn.resp_body)["workers"])["name"] == "Alice"
    end
  end

  describe "call/2 :remove_worker" do
    test "returns 200 with board detail after removing a worker", %{board: board} do
      expect(BoardUsecaseMock, :remove_worker, fn _cmd, _opts -> {:ok, board} end)

      conn =
        :delete
        |> conn("/api/v1/boards/#{board.id}/workers/worker-1")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> Map.put(:path_params, %{"id" => board.id, "worker_id" => "worker-1"})
        |> BoardController.call(:remove_worker)

      assert conn.status == 200
    end
  end
end
