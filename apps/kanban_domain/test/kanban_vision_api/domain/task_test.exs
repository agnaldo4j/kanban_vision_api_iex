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
      assert is_binary(task.id)
    end
  end

  describe "new/3" do
    test "creates task with custom id" do
      service_class = ServiceClass.new("Standard")

      %Task{} = task = Task.new(3, service_class, "custom-id")

      assert task.id == "custom-id"
    end
  end

  describe "new/4" do
    test "creates task with all explicit params" do
      service_class = ServiceClass.new("Standard")
      audit = Audit.new()

      %Task{} = task = Task.new(3, service_class, "custom-id", audit)

      assert task.id == "custom-id"
      assert task.audit == audit
    end
  end
end
