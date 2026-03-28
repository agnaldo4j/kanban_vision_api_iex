defmodule KanbanVisionApi.Usecase.Board do
  @moduledoc """
  GenServer orchestrating board use cases.

  Maintains repository state and delegates operations to specialized Use Case modules.
  """

  use GenServer

  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.Usecase.Boards.CreateBoard
  alias KanbanVisionApi.Usecase.Boards.DeleteBoard
  alias KanbanVisionApi.Usecase.Boards.GetAllBoards
  alias KanbanVisionApi.Usecase.Boards.GetBoardById
  alias KanbanVisionApi.Usecase.Boards.GetBoardsBySimulationId
  alias KanbanVisionApi.Usecase.RepositoryConfig

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :repository, RepositoryConfig.fetch!(:board))
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
  end

  def get_all(pid, opts \\ []), do: GenServer.call(pid, {:get_all, opts})

  def get_by_id(pid, %GetBoardByIdQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_id, query, opts})
  end

  def get_by_simulation_id(pid, %GetBoardsBySimulationIdQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_simulation_id, query, opts})
  end

  def add(pid, %CreateBoardCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def delete(pid, %DeleteBoardCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:delete, cmd, opts})
  end

  @impl true
  def init(opts) do
    repository = Keyword.fetch!(opts, :repository)
    {:ok, repository_pid} = repository.start_link()
    repository_runtime = repository.runtime(repository_pid)
    {:ok, %{repository_runtime: repository_runtime, repository: repository}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    result = GetAllBoards.execute(state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_id, query, opts}, _from, state) do
    result = GetBoardById.execute(query, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_by_simulation_id, query, opts}, _from, state) do
    result =
      GetBoardsBySimulationId.execute(
        query,
        state.repository_runtime,
        enrich_opts(opts, state)
      )

    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateBoard.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:delete, cmd, opts}, _from, state) do
    result = DeleteBoard.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  defp enrich_opts(opts, state) do
    Keyword.put_new(opts, :repository, state.repository)
  end
end
