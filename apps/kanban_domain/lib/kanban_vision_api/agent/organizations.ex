defmodule KanbanVisionApi.Agent.Organizations do
  @moduledoc false

  use Agent

  defstruct [:id, :organizations]

  @type t :: %KanbanVisionApi.Agent.Organizations {
               id: String.t,
               organizations: Map.t
             }

  def new(organizations \\ %{}, id \\ UUID.uuid4()) do
    %KanbanVisionApi.Agent.Organizations{
      id: id,
      organizations: organizations
    }
  end

  # Client

  @spec start_link(KanbanVisionApi.Agent.Organizations.t) :: Agent.on_start()
  def start_link(default \\ KanbanVisionApi.Agent.Organizations.new) do
    Agent.start_link(fn -> default end, name: String.to_atom(default.id))
  end

  def get_all(id) do
    Agent.get(id, fn state -> state end)
  end

  def get_by_id(pid, domain_id) do
    Agent.get(pid, fn state ->
      case Map.get(state.organizations, domain_id) do
        nil -> {:error, "Organization with id: #{domain_id} not found"}
        domain -> {:ok, domain}
      end
    end)
  end

  def get_by_name(pid, domain_name) do
    Agent.get(pid, fn state ->
      internal_get_by_name(state.organizations, domain_name)
    end)
  end

  def add(pid, new_organization = %KanbanVisionApi.Domain.Organization{}) do
    Agent.update(pid, fn state ->
      case internal_get_by_name(state.organizations, new_organization.name) do
        {:error, _} ->
          put_in(
            state.organizations,
            Map.put(state.organizations, new_organization.id, new_organization)
          )
        {:ok, _} ->
          state
      end
    end)
  end

  def delete(pid, domain_id) do
    result = get_by_id(pid, domain_id)

    Agent.update(pid, fn state ->
      case result do
        {:error, _} -> state
        {:ok, domain} -> put_in(state.organizations, Map.delete(state.organizations, domain.id))
      end
    end)

    result
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
