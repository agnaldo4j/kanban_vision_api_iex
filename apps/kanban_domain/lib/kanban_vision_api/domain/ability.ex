defmodule KanbanVisionApi.Domain.Ability do
  @moduledoc false

  defstruct [:id, :audit, :name]

  @type t :: %KanbanVisionApi.Domain.Ability{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t()
        }

  def new(name, id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Ability{
      id: id,
      audit: audit,
      name: name
    }
  end
end
