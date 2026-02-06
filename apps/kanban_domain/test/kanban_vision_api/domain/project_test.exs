defmodule KanbanVisionApi.Domain.ProjectTest do
  use ExUnit.Case, async: true

  describe "new/4" do
    test "builds a project with consistent defaults" do
      project = KanbanVisionApi.Domain.Project.new("Project A")

      assert is_binary(project.id)
      assert project.name == "Project A"
      assert project.order == 0
      assert project.tasks == []
    end
  end
end
