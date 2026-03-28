defmodule KanbanVisionApi.Usecase.Board do
  @moduledoc """
  GenServer orchestrating board use cases.

  Maintains repository state and delegates operations to specialized Use Case modules.
  """

  use GenServer

  alias KanbanVisionApi.Usecase.Board.AddBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.AllocateBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkerCommand
  alias KanbanVisionApi.Usecase.Board.RemoveBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Board.RenameBoardCommand
  alias KanbanVisionApi.Usecase.Board.ReorderBoardWorkflowStepCommand
  alias KanbanVisionApi.Usecase.Boards.AddWorkflowStep
  alias KanbanVisionApi.Usecase.Boards.AllocateWorker
  alias KanbanVisionApi.Usecase.Boards.CreateBoard
  alias KanbanVisionApi.Usecase.Boards.DeleteBoard
  alias KanbanVisionApi.Usecase.Boards.GetAllBoards
  alias KanbanVisionApi.Usecase.Boards.GetBoardById
  alias KanbanVisionApi.Usecase.Boards.GetBoardsBySimulationId
  alias KanbanVisionApi.Usecase.Boards.RemoveWorker
  alias KanbanVisionApi.Usecase.Boards.RemoveWorkflowStep
  alias KanbanVisionApi.Usecase.Boards.RenameBoard
  alias KanbanVisionApi.Usecase.Boards.ReorderWorkflowStep
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

  def rename(pid, %RenameBoardCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:rename, cmd, opts})
  end

  def add_workflow_step(pid, %AddBoardWorkflowStepCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add_workflow_step, cmd, opts})
  end

  def remove_workflow_step(pid, %RemoveBoardWorkflowStepCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:remove_workflow_step, cmd, opts})
  end

  def reorder_workflow_step(pid, %ReorderBoardWorkflowStepCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:reorder_workflow_step, cmd, opts})
  end

  def allocate_worker(pid, %AllocateBoardWorkerCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:allocate_worker, cmd, opts})
  end

  def remove_worker(pid, %RemoveBoardWorkerCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:remove_worker, cmd, opts})
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
  def handle_call({:rename, cmd, opts}, _from, state) do
    result = RenameBoard.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_workflow_step, cmd, opts}, _from, state) do
    result = AddWorkflowStep.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:remove_workflow_step, cmd, opts}, _from, state) do
    result = RemoveWorkflowStep.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:reorder_workflow_step, cmd, opts}, _from, state) do
    result = ReorderWorkflowStep.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:allocate_worker, cmd, opts}, _from, state) do
    result = AllocateWorker.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:remove_worker, cmd, opts}, _from, state) do
    result = RemoveWorker.execute(cmd, state.repository_runtime, enrich_opts(opts, state))
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
