defmodule KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand do
  @moduledoc false
  defstruct [:name, tribes: []]
end

defmodule KanbanVisionApi.Usecase.Organization.DeleteOrganizationCommand do
  @moduledoc false
  defstruct [:id]
end
