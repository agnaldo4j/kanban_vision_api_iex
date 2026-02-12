defmodule KanbanVisionApi.Domain.Tribe do
  @moduledoc false

  defstruct [:id, :audit, :name, :squads]

  @type t :: %KanbanVisionApi.Domain.Tribe{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          squads: List.t()
        }

  def new(name, squads \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    initial_state = %KanbanVisionApi.Domain.Tribe{
      id: id,
      audit: audit,
      name: name,
      squads: squads
    }

    initial_state
  end
end
