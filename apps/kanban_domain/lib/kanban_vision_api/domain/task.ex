defmodule KanbanVisionApi.Domain.Task do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.ServiceClass

  defstruct [:id, :audit, :order, :service_class]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          order: non_neg_integer(),
          service_class: ServiceClass.t()
        }

  def new(
        order,
        service_class \\ %ServiceClass{},
        id \\ UUID.uuid4(),
        audit \\ Audit.new()
      ) do
    %__MODULE__{
      id: id,
      audit: audit,
      order: order,
      service_class: service_class
    }
  end
end
