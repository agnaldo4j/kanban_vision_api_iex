defmodule KanbanVisionApi.Domain.WorkflowTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Workflow

  describe "new/0" do
    test "creates workflow with defaults" do
      %Workflow{} = workflow = Workflow.new()

      assert workflow.steps == []
      assert is_binary(workflow.id)
      assert %Audit{} = workflow.audit
    end
  end

  describe "new/1" do
    test "creates workflow with steps" do
      step = Step.new("Analysis", 0, [])
      %Workflow{} = workflow = Workflow.new([step])

      assert workflow.steps == [step]
    end
  end

  describe "add_step/2" do
    test "adds a step and normalizes ordering" do
      workflow = Workflow.new([Step.new("Backlog", 0, [])])
      step = Step.new("In Progress", 1, [], Ability.new("Coding"))

      assert {:ok, updated_workflow} = Workflow.add_step(workflow, step)
      assert Enum.map(updated_workflow.steps, & &1.name) == ["Backlog", "In Progress"]
      assert Enum.map(updated_workflow.steps, & &1.order) == [0, 1]
    end

    test "returns error when step name already exists" do
      workflow = Workflow.new([Step.new("Backlog", 0, [])])
      duplicate = Step.new("Backlog", 1, [])

      assert {:error, :step_name_taken} = Workflow.add_step(workflow, duplicate)
    end
  end

  describe "remove_step/2" do
    test "removes a step and normalizes ordering" do
      first = Step.new("Backlog", 0, [])
      second = Step.new("Done", 1, [])
      workflow = Workflow.new([first, second])

      assert {:ok, updated_workflow} = Workflow.remove_step(workflow, first.id)
      assert Enum.map(updated_workflow.steps, & &1.name) == ["Done"]
      assert Enum.map(updated_workflow.steps, & &1.order) == [0]
    end
  end

  describe "reorder_step/3" do
    test "moves a step and renormalizes ordering" do
      first = Step.new("Backlog", 0, [])
      second = Step.new("In Progress", 1, [])
      third = Step.new("Done", 2, [])
      workflow = Workflow.new([first, second, third])

      assert {:ok, updated_workflow} = Workflow.reorder_step(workflow, third.id, 0)
      assert Enum.map(updated_workflow.steps, & &1.name) == ["Done", "Backlog", "In Progress"]
      assert Enum.map(updated_workflow.steps, & &1.order) == [0, 1, 2]
    end
  end
end
