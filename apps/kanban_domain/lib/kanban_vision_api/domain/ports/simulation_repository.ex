defmodule KanbanVisionApi.Domain.Ports.SimulationRepository do
  @moduledoc """
  Port defining the contract for simulation persistence.
  """

  @callback get_all(pid :: pid()) :: map()
  @callback add(pid :: pid(), simulation :: struct()) :: {:ok, struct()} | {:error, String.t()}
  @callback get_by_organization_id_and_simulation_name(
              pid :: pid(),
              org_id :: String.t(),
              name :: String.t()
            ) :: {:ok, struct()} | {:error, String.t()}
end
