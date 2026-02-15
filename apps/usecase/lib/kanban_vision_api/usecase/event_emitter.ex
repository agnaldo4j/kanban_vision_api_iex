defmodule KanbanVisionApi.Usecase.EventEmitter do
  @moduledoc """
  Shared telemetry event emission for use cases.

  Wraps :telemetry.execute/3 calls with a consistent event namespace
  and metadata structure across all use cases.
  """

  @spec emit(atom(), atom(), map(), String.t()) :: :ok
  def emit(context, event_type, metadata, correlation_id) do
    :telemetry.execute(
      [:kanban_vision_api, context, event_type],
      %{count: 1},
      Map.put(metadata, :correlation_id, correlation_id)
    )
  end
end
