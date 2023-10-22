defmodule KanbanVisionApi.Domain.Worker do
  @moduledoc false

  defstruct [:id, :audit, :name, :abilities]

  @type t :: %KanbanVisionApi.Domain.Worker {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t,
               name: String.t,
               abilities: List.t
             }

  def new(name, abilities \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new) do
    initial_state = %KanbanVisionApi.Domain.Worker{
      id: id,
      audit: audit,
      name: name,
      abilities: abilities
    }
    KanbanVisionApi.Domain.Worker.start_link(initial_state)
    initial_state
  end
end
