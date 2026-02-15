defmodule KanbanVisionApi.Domain.Task do
  @moduledoc false

  defstruct [:id, :audit, :order, :service_class]

  @type t :: %KanbanVisionApi.Domain.Task{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          order: non_neg_integer(),
          service_class: KanbanVisionApi.Domain.ServiceClass.t()
        }

  def new(
        order,
        service_class \\ %KanbanVisionApi.Domain.ServiceClass{},
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new()
      ) do
    %KanbanVisionApi.Domain.Task{
      id: id,
      audit: audit,
      order: order,
      service_class: service_class
    }
  end
end
