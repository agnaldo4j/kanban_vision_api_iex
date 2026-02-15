defmodule KanbanVisionApi.Domain.Worker do
  @moduledoc false

  defstruct [:id, :audit, :name, :abilities]

  @type t :: %KanbanVisionApi.Domain.Worker{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          abilities: [KanbanVisionApi.Domain.Ability.t()]
        }

  def new(name, abilities \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Worker{
      id: id,
      audit: audit,
      name: name,
      abilities: abilities
    }
  end
end
