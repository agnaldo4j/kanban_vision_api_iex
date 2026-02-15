defmodule KanbanVisionApi.Domain.Tribe do
  @moduledoc false

  defstruct [:id, :audit, :name, :squads]

  @type t :: %KanbanVisionApi.Domain.Tribe{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          squads: [KanbanVisionApi.Domain.Squad.t()]
        }

  def new(name, squads \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Tribe{
      id: id,
      audit: audit,
      name: name,
      squads: squads
    }
  end
end
