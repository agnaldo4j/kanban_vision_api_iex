defmodule KanbanVisionApi.Domain.Organization do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Tribe

  defstruct [:id, :audit, :name, :tribes]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          tribes: [Tribe.t()]
        }

  def new(name, tribes \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      tribes: tribes
    }
  end
end
