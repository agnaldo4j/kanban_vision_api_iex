defmodule KanbanVisionApi.Domain.Worker do
  @moduledoc false

  use Agent

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

  # Client

  @spec start_link(KanbanVisionApi.Domain.Worker.t) :: Agent.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Worker{}) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_state(id) do
    Agent.get(id, fn state -> state end)
  end

end
