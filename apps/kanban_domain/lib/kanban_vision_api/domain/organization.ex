defmodule KanbanVisionApi.Domain.Organization do
  @moduledoc false

  defstruct [:id, :audit, :name, :tribes]

  @type t :: %KanbanVisionApi.Domain.Organization{
          id: String.t(),
          audit: KanbanVisionApi.Domain.Audit.t(),
          name: String.t(),
          tribes: List.t()
        }

  def new(name, tribes \\ [], id \\ UUID.uuid4(), audit \\ KanbanVisionApi.Domain.Audit.new()) do
    %KanbanVisionApi.Domain.Organization{
      id: id,
      audit: audit,
      name: name,
      tribes: tribes
    }
  end
end
