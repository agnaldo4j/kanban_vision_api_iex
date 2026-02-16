defmodule KanbanVisionApi.Domain.TaskTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.ServiceClass
  alias KanbanVisionApi.Domain.Task

  describe "new/1" do
    test "creates task with order and default service class" do
      %Task{} = task = Task.new(1)

      assert task.order == 1
      assert %ServiceClass{} = task.service_class
      assert is_binary(task.id)
      assert %Audit{} = task.audit
    end
  end

  describe "new/2" do
    test "creates task with explicit service class" do
      service_class = ServiceClass.new("Expedite")
      %Task{} = task = Task.new(2, service_class)

      assert task.order == 2
      assert task.service_class == service_class
    end
  end
end
