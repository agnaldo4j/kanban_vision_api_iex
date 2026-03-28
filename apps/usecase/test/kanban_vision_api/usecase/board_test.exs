defmodule KanbanVisionApi.Usecase.BoardTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ports.ApplicationError
  alias KanbanVisionApi.Usecase.Board
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery

  describe "When start with empty state" do
    setup [:start_usecase]

    test "should return empty map", %{pid: pid} do
      assert Board.get_all(pid) == {:ok, %{}}
    end

    test "should add a new board via command", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      assert {:ok, board} = Board.add(pid, cmd)
      assert board.name == "Dev Board"
      assert board.simulation_id == "sim-123"
    end

    test "should find board by id via query", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, query} = GetBoardByIdQuery.new(board.id)
      assert {:ok, ^board} = Board.get_by_id(pid, query)
    end

    test "should find boards by simulation id via query", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, query} = GetBoardsBySimulationIdQuery.new("sim-123")
      assert {:ok, [^board]} = Board.get_by_simulation_id(pid, query)
    end

    test "should delete a board via command", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, board} = Board.add(pid, cmd)

      {:ok, delete_cmd} = DeleteBoardCommand.new(board.id)
      assert {:ok, ^board} = Board.delete(pid, delete_cmd)
    end

    test "should return error for non-existent id", %{pid: pid} do
      {:ok, query} = GetBoardByIdQuery.new("invalid")

      assert Board.get_by_id(pid, query) ==
               ApplicationError.not_found(
                 "Board with id: invalid not found",
                 %{entity: :board, id: "invalid"}
               )
    end

    test "should return error for non-existent simulation id", %{pid: pid} do
      {:ok, query} = GetBoardsBySimulationIdQuery.new("sim-999")

      assert Board.get_by_simulation_id(pid, query) ==
               ApplicationError.not_found(
                 "Boards by simulation_id: sim-999 not found",
                 %{entity: :board, field: :simulation_id, simulation_id: "sim-999"}
               )
    end

    test "should not allow duplicate board names in the same simulation", %{pid: pid} do
      {:ok, cmd} = CreateBoardCommand.new("Dev Board", "sim-123")
      {:ok, _} = Board.add(pid, cmd)

      {:ok, duplicate_cmd} = CreateBoardCommand.new("Dev Board", "sim-123")

      assert Board.add(pid, duplicate_cmd) ==
               ApplicationError.conflict(
                 "Board with name: Dev Board from simulation_id: sim-123 already exist",
                 %{entity: :board, field: :name, name: "Dev Board", simulation_id: "sim-123"}
               )
    end

    test "should reject invalid command", %{pid: _pid} do
      assert {:error, :invalid_name} = CreateBoardCommand.new("", "sim-123")
      assert {:error, :invalid_simulation_id} = CreateBoardCommand.new("Dev Board", "")
      assert {:error, :invalid_id} = GetBoardByIdQuery.new("")
      assert {:error, :invalid_simulation_id} = GetBoardsBySimulationIdQuery.new("")
    end
  end

  defp start_usecase(_context) do
    {:ok, pid} = Board.start_link()
    [pid: pid]
  end
end
