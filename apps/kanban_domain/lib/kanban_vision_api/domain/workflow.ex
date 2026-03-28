defmodule KanbanVisionApi.Domain.Workflow do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Step

  defstruct [:id, :audit, :steps]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          steps: [Step.t()]
        }

  def new(steps \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      steps: steps
    }
  end

  @spec add_step(t(), Step.t()) :: {:ok, t()} | {:error, :step_name_taken}
  def add_step(%__MODULE__{} = workflow, %Step{} = step) do
    ordered_steps = Enum.sort_by(workflow.steps, & &1.order)

    if Enum.any?(ordered_steps, &(&1.name == step.name)) do
      {:error, :step_name_taken}
    else
      insert_at = min(step.order, length(ordered_steps))
      inserted_steps = List.insert_at(ordered_steps, insert_at, step)
      {:ok, update_steps(workflow, inserted_steps)}
    end
  end

  @spec remove_step(t(), String.t()) :: {:ok, t()} | {:error, :step_not_found}
  def remove_step(%__MODULE__{} = workflow, step_id) do
    ordered_steps = Enum.sort_by(workflow.steps, & &1.order)

    if Enum.any?(ordered_steps, &(&1.id == step_id)) do
      filtered_steps = Enum.reject(ordered_steps, &(&1.id == step_id))
      {:ok, update_steps(workflow, filtered_steps)}
    else
      {:error, :step_not_found}
    end
  end

  @spec reorder_step(t(), String.t(), non_neg_integer()) :: {:ok, t()} | {:error, :step_not_found}
  def reorder_step(%__MODULE__{} = workflow, step_id, new_order) do
    ordered_steps = Enum.sort_by(workflow.steps, & &1.order)

    case Enum.find(ordered_steps, &(&1.id == step_id)) do
      nil ->
        {:error, :step_not_found}

      step ->
        remaining_steps = Enum.reject(ordered_steps, &(&1.id == step_id))
        insert_at = min(new_order, length(remaining_steps))
        reordered_steps = List.insert_at(remaining_steps, insert_at, step)
        {:ok, update_steps(workflow, reordered_steps)}
    end
  end

  defp update_steps(%__MODULE__{} = workflow, steps) do
    normalized_steps =
      steps
      |> Enum.with_index()
      |> Enum.map(fn {step, index} -> %{step | order: index} end)

    %{workflow | steps: normalized_steps, audit: touch_audit(workflow.audit)}
  end

  defp touch_audit(%Audit{} = audit), do: %{audit | updated: DateTime.utc_now()}
end
