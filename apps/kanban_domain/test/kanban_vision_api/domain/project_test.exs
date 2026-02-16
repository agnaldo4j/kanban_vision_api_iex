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
  end

  describe "new/2" do
    test "creates project with custom order" do
      %Project{} = project = Project.new("Feature Y", 3)

      assert project.order == 3
      assert project.tasks == []
    end
  end

  describe "new/3" do
    test "creates project with order and tasks" do
      task = Task.new(1)
      %Project{} = project = Project.new("Feature X", 5, [task])

      assert project.order == 5
      assert project.tasks == [task]
    end
  end

  describe "new/4" do
    test "creates project with custom id" do
      task = Task.new(1)

      %Project{} = project = Project.new("Full Project", 1, [task], "custom-id")

      assert project.id == "custom-id"
    end
  end

  describe "new/5" do
    test "creates project with all explicit params" do
      task = Task.new(1)
      audit = Audit.new()

      %Project{} = project = Project.new("Full Project", 1, [task], "custom-id", audit)

      assert project.id == "custom-id"
      assert project.audit == audit
    end
  end
end
