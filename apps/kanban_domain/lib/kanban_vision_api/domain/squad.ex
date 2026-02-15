defmodule KanbanVisionApi.Domain.Squad do
  @moduledoc false

  alias KanbanVisionApi.Domain.Audit
  alias KanbanVisionApi.Domain.Worker

  defstruct [:id, :audit, :name, :workers]

  @type t :: %__MODULE__{
          id: String.t(),
          audit: Audit.t(),
          name: String.t(),
          workers: [Worker.t()]
        }

  def new(name, workers \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{
      id: id,
      audit: audit,
      name: name,
      workers: workers
    }
  end
end
