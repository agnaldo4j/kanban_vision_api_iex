defmodule KanbanVisionApi.Usecase.OrganizationTest do
  use ExUnit.Case, async: true
  doctest KanbanVisionApi.Usecase.Organization

  describe "When start a new organization with empty state" do
    test "should be empty" do
      domain = KanbanVisionApi.Domain.Organization.new("Teste")
      {:ok, pid} = KanbanVisionApi.Usecase.Organization.start_link()
      assert KanbanVisionApi.Usecase.Organization.fetch(pid) == {:ok, %{}}
      assert domain.name == "Teste"
    end
  end

end
