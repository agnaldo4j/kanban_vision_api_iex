defmodule KanbanVisionApi.Domain.Organizations do
  @moduledoc false

  use Agent

  defstruct [:id, :organizations]

  @type t :: %KanbanVisionApi.Domain.Organizations {
               id: String.t,
               organizations: Map.t
             }

  def new(organizations \\ %{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Domain.Organizations{
      id: id,
      organizations: organizations
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Domain.Organizations.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Domain.Organizations.new) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_all(id) do
    Agent.get(id, fn state -> state end)
  end

  def get_by_id(pid, domain_id) do
    Agent.get(pid, fn state ->
      result = case Map.get(state.organizations, domain_id) do
        nil -> {:error, "Organization with id: #{domain_id} not found"}
        domain -> {:ok, domain}
      end
      result
    end)
  end

  def get_by_name(pid, domain_name) do
    Agent.get(pid, fn state ->
      result = internal_get_by_name(state.organizations, domain_name)
      result
    end)
  end

  def add(pid, new_organization = %KanbanVisionApi.Domain.Organization{}) do
    Agent.update(pid, fn state ->
      case internal_get_by_name(state.organizations, new_organization.name) do
        {:error, _} ->
          new_state = put_in(state.organizations, Map.put(state.organizations, new_organization.id, new_organization))
        {:ok, _} ->
          state
      end
    end)
  end

  defp internal_get_by_name(state, domain_name) do
    Map.values(state)
    |> Enum.filter(fn domain -> domain.name == domain_name end)
    |> prepare_by_name_result(domain_name)
  end

  defp prepare_by_name_result(result_list, domain_name) do
    case result_list do
      values when values == [] -> {:error, "Organization with name: #{domain_name} not found"}
      values -> {:ok, values}
    end
  end

end
