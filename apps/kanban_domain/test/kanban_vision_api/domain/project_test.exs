defmodule KanbanVisionApi.Domain.ProjectTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Project
  alias KanbanVisionApi.Domain.Task

  describe "new/1" do
    test "creates project with name and defaults" do
      %Project{} = project = Project.new("Feature X")

      assert project.name == "Feature X"
      assert project.order == 0
      assert project.tasks == []
      assert is_binary(project.id)
      assert %Audit{} = project.audit
    end

    test "creates project with order and tasks" do
      task = Task.new(1)
      %Project{} = project = Project.new("Feature X", 5, [task])

      assert project.order == 5
      assert project.tasks == [task]
    end
  end
end
