defmodule KanbanVisionApi.Domain.Ability do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit

  defstruct [:id, :audit, :name]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t()
        }

  def new(name, id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name
    }
  end
end
