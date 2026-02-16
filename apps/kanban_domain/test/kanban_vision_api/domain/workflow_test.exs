defmodule KanbanVisionApi.Domain.WorkflowTest do
  use ExUnit.Case, async: true

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
end
