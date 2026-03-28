defmodule KanbanVisionApi.Domain.Board do
  @moduledoc false

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Worker
  alias KanbanVisionApi.Domain.Workflow

  defstruct [:id, :audit, :name, :simulation_id, :workflow, :workers]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          simulation_id: String.t(),
          workflow: Workflow.t(),
          workers: %{optional(String.t()) => Worker.t()}
        }

  def new(
        name \\ "Default",
        simulation_id \\ "Default Simulation ID",
        workflow \\ Workflow.new(),
        workers \\ %{},
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      simulation_id: simulation_id,
      workflow: workflow,
      workers: workers
    }
  end

  @spec rename(t(), String.t()) :: t()
  def rename(%__MODULE__{} = board, name) do
    %{board | name: name, audit: touch_audit(board.audit)}
  end

  @spec add_workflow_step(t(), Step.t()) :: {:ok, t()} | {:error, :step_name_taken}
  def add_workflow_step(%__MODULE__{} = board, %Step{} = step) do
    case Workflow.add_step(board.workflow, step) do
      {:ok, workflow} -> {:ok, %{board | workflow: workflow, audit: touch_audit(board.audit)}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec remove_workflow_step(t(), String.t()) :: {:ok, t()} | {:error, :step_not_found}
  def remove_workflow_step(%__MODULE__{} = board, step_id) do
    case Workflow.remove_step(board.workflow, step_id) do
      {:ok, workflow} -> {:ok, %{board | workflow: workflow, audit: touch_audit(board.audit)}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec reorder_workflow_step(t(), String.t(), non_neg_integer()) ::
          {:ok, t()} | {:error, :step_not_found}
  def reorder_workflow_step(%__MODULE__{} = board, step_id, order) do
    case Workflow.reorder_step(board.workflow, step_id, order) do
      {:ok, workflow} -> {:ok, %{board | workflow: workflow, audit: touch_audit(board.audit)}}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec allocate_worker(t(), Worker.t()) :: {:ok, t()} | {:error, :worker_name_taken}
  def allocate_worker(%__MODULE__{} = board, %Worker{} = worker) do
    if Enum.any?(Map.values(board.workers), &(&1.name == worker.name)) do
      {:error, :worker_name_taken}
    else
      updated_workers = Map.put(board.workers, worker.id, worker)
      {:ok, %{board | workers: updated_workers, audit: touch_audit(board.audit)}}
    end
  end

  @spec remove_worker(t(), String.t()) :: {:ok, t()} | {:error, :worker_not_found}
  def remove_worker(%__MODULE__{} = board, worker_id) do
    case Map.fetch(board.workers, worker_id) do
      {:ok, _worker} ->
        updated_workers = Map.delete(board.workers, worker_id)
        {:ok, %{board | workers: updated_workers, audit: touch_audit(board.audit)}}

      :error ->
        {:error, :worker_not_found}
    end
  end

  @spec build_step(String.t(), non_neg_integer(), String.t()) :: Step.t()
  def build_step(name, order, required_ability_name) do
    Step.new(name, order, [], Ability.new(required_ability_name))
  end

  @spec build_worker(String.t(), [String.t()]) :: Worker.t()
  def build_worker(name, ability_names) do
    abilities = Enum.map(ability_names, &Ability.new/1)
    Worker.new(name, abilities)
  end

  defp touch_audit(%Audit{} = audit), do: %{audit | updated: DateTime.utc_now()}
end
