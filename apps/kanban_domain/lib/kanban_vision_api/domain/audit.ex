defmodule KanbanVisionApi.Domain.Audit do
  @moduledoc false

  defstruct [:created, :updated]

  @type t :: %KanbanVisionApi.Domain.Audit {
               created: DateTime,
               updated: DateTime
             }

  def new do
    %KanbanVisionApi.Domain.Audit{
      created: DateTime.utc_now(),
      updated: DateTime.utc_now()
    }
  end

end
