defmodule KanbanVisionApi.Agent.Organizations do
  @moduledoc false

  use Agent

  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  defmodule Runtime do
    @moduledoc false

    @enforce_keys [:pid]
    defstruct [:pid]
  end

  defstruct [:id, :organizations]

  @type t :: %__MODULE__{
          id: String.t(),
          organizations: map()
        }

  @opaque runtime :: %Runtime{pid: pid()}

  def new(organizations \\ %{}, id \\ UUID.uuid4()) do
    %__MODULE__{
      id: id,
      organizations: organizations
    }
  end

  # Client

  @spec start_link(t()) :: {:ok, runtime()}
  def start_link(default \\ __MODULE__.new()) do
    {:ok, pid} = Agent.start_link(fn -> default end)
    {:ok, %Runtime{pid: pid}}
  end

  def get_all(%Runtime{pid: pid}) do
    Agent.get(pid, fn state -> state.organizations end)
  end

  def get_by_id(%Runtime{pid: pid}, domain_id) do
    Agent.get(pid, fn state ->
      case Map.get(state.organizations, domain_id) do
        nil -> {:error, "Organization with id: #{domain_id} not found"}
        domain -> {:ok, domain}
      end
    end)
  end

  def get_by_name(%Runtime{pid: pid}, domain_name) do
    Agent.get(pid, fn state ->
      internal_get_by_name(state.organizations, domain_name)
    end)
  end

  def add(%Runtime{pid: pid}, %KanbanVisionApi.Domain.Organization{} = new_organization) do
    Agent.get_and_update(pid, fn state ->
      case internal_get_by_name(state.organizations, new_organization.name) do
        {:error, _} ->
          new_orgs = Map.put(state.organizations, new_organization.id, new_organization)
          new_state = put_in(state.organizations, new_orgs)
          {{:ok, new_organization}, new_state}

        {:ok, _} ->
          {{:error, "Organization with name: #{new_organization.name} already exist"}, state}
      end
    end)
  end

  def delete(%Runtime{pid: pid}, domain_id) do
    Agent.get_and_update(pid, fn state ->
      case Map.get(state.organizations, domain_id) do
        nil ->
          {{:error, "Organization with id: #{domain_id} not found"}, state}

        domain ->
          new_orgs = Map.delete(state.organizations, domain.id)
          new_state = put_in(state.organizations, new_orgs)
          {{:ok, domain}, new_state}
      end
    end)
  end

  defp internal_get_by_name(organizations, domain_name) do
    Map.values(organizations)
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
