defmodule KanbanVisionApi.Domain.StepTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Step
  alias KanbanVisionApi.Domain.Task

  describe "new/3" do
    test "creates step with name, order, tasks, and default ability" do
      task = Task.new(1)
      %Step{} = step = Step.new("Analysis", 0, [task])

      assert step.name == "Analysis"
      assert step.order == 0
      assert step.tasks == [task]
      assert %Ability{} = step.required_ability
      assert is_binary(step.id)
      assert %Audit{} = step.audit
    end
  end

  describe "new/4" do
    test "creates step with explicit required_ability" do
      task = Task.new(1)
      ability = Ability.new("Coding")
      %Step{} = step = Step.new("Development", 1, [task], ability)

      assert step.required_ability == ability
      assert step.tasks == [task]
    end
  end

  describe "new/5" do
    test "creates step with custom id" do
      task = Task.new(1)
      ability = Ability.new("Testing")

      %Step{} = step = Step.new("QA", 2, [task], ability, "custom-id")

      assert step.id == "custom-id"
    end
  end

  describe "new/6" do
    test "creates step with all explicit params" do
      task = Task.new(1)
      ability = Ability.new("Testing")
      audit = Audit.new()

      %Step{} = step = Step.new("QA", 2, [task], ability, "custom-id", audit)

      assert step.id == "custom-id"
      assert step.audit == audit
    end
  end
end
