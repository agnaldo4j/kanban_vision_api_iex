defmodule KanbanVisionApi.Domain.Worker do
  @moduledoc false

  alias KanbanVisionApi.Domain.Ability
  alias KanbanVisionApi.Domain.Audit

  defstruct [:id, :audit, :name, :abilities]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          abilities: [Ability.t()]
        }

  def new(name, abilities \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      abilities: abilities
    }
  end
end
