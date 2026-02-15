defmodule KanbanVisionApi.Domain.Squad do
  @moduledoc false

  defstruct [:id, :audit, :name, :workers]

  @type t :: %KanbanVisionApi.Domain.Squad{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          workers: [KanbanVisionApi.Domain.Worker.t()]
        }

  def new(name, workers \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Squad{
      id: id,
      audit: audit,
      name: name,
      workers: workers
    }
  end
end
