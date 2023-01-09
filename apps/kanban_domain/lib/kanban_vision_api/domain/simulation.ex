defmodule KanbanVisionApi.Domain.Simulation do
  @moduledoc false

  defstruct name: "John", age: 27

  @type t :: %KanbanVisionApi.Domain.Simulation{
               name: String.t(),
               age: integer()
             }

  def new(name, age) do
    %KanbanVisionApi.Domain.Simulation{
      name: name,
      age: age
    }
  end

end
