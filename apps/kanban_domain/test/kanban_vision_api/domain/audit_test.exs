defmodule KanbanVisionApi.Domain.AuditTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Audit

  describe "new/0" do
    test "creates audit with created and updated timestamps" do
      %Audit{} = audit = Audit.new()

      assert %DateTime{} = audit.created
      assert %DateTime{} = audit.updated
    end

    test "created and updated timestamps are equal on creation" do
      %Audit{} = audit = Audit.new()

      assert audit.created == audit.updated
    end
  end
end
