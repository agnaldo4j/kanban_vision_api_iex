defmodule KanbanVisionApi.Domain.Tribe do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Squad

  defstruct [:id, :audit, :name, :squads]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          squads: [Squad.t()]
        }

  def new(name, squads \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      squads: squads
    }
  end
end
