defmodule KanbanVisionApi.Domain.Audit do
  @moduledoc false

  defstruct [:created, :updated]

  @type t :: %__MODULE__{
          created: DateTime.t(),
          updated: DateTime.t()
        }

  def new do
    now = DateTime.utc_now()

    %__MODULE__{
      created: now,
      updated: now
    }
  end
end
