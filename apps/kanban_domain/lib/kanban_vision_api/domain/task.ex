defmodule KanbanVisionApi.Domain.Task do
  @moduledoc false

  @behaviour GenServer

  defstruct [:id, :audit, :order, :service_class]

  @type t :: %KanbanVisionApi.Domain.Task {
               id: String.t,
               audit: KanbanVisionApi.Domain.Audit.t, 
               order: Integer.t,
               service_class: KanbanVisionApi.Domain.ServiceClass.t
             }

  def new(
        order,
        service_class \\ %KanbanVisionApi.Domain.ServiceClass{},
        id \\ UUID.uuid4(),
        audit \\ KanbanVisionApi.Domain.Audit.new
      ) do
    initial_state = %KanbanVisionApi.Domain.Task{
      id: id,
      audit: audit, 
      order: order,
      service_class: service_class
    }
    KanbanVisionApi.Domain.Task.start_link(initial_state)
    initial_state
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Task.t) :: GenServer.on_start()
  def start_link(default \\ %KanbanVisionApi.Domain.Task{}) do
    GenServer.start_link(__MODULE__, default, name: String.to_atom(default.id))
  end

  # Server (callbacks)

  @impl true
  def init(stack) do
    {:ok, stack}
  end

end
