defmodule KanbanVisionApi.Domain.Ports.RepositoryRuntime do
  @moduledoc """
  Opaque runtime handle used by persistence adapters outside the pure domain.
  """

  @type t :: term()
end
