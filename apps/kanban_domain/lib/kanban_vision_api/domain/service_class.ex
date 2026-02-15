defmodule KanbanVisionApi.Domain.ServiceClass do
  @moduledoc false

  defstruct [:id, :audit, :name]

  @type t :: %KanbanVisionApi.Domain.ServiceClass{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t()
        }

  def new(name, id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.ServiceClass{
      id: id,
      audit: audit,
      name: name
    }
  end
end
