defmodule KanbanVisionApi.Domain.Squad do
  @moduledoc false

  defstruct [:id, :audit, :name, :workers]

  @type t :: %KanbanVisionApi.Domain.Squad {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t,
               workers: List.t
             }

  def new(name, workers \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new) do
    initial_state = %KanbanVisionApi.Domain.Squad{
      id: id,
      audit: audit,
      name: name,
      workers: workers
    }
    initial_state
  end
end
