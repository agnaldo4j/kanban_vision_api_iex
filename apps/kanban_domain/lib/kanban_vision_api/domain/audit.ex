defmodule KanbanVisionApi.Domain.Audit do
  @moduledoc false

  defstruct [:created, :updated]

  @type t :: %__MODULE__{
          created: DateTime.t(),
          updated: DateTime.t()
        }

  def new do
    %__MODULE__{
      created: DateTime.utc_now(),
      updated: DateTime.utc_now()
    }
  end
end
