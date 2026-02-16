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
    end
  end
end
