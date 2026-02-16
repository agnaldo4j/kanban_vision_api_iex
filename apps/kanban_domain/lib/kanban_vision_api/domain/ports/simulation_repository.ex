defmodule KanbanVisionApi.Domain.Ports.SimulationRepository do
  @moduledoc """
  Port defining the contract for simulation persistence.
  """

  alias KanbanVisionApi.Domain.Simulation

  @callback get_all(pid :: pid()) :: map()
  @callback add(pid :: pid(), simulation :: Simulation.t()) ::
              {:ok, Simulation.t()} | {:error, String.t()}
  @callback delete(pid :: pid(), id :: String.t()) ::
              {:ok, Simulation.t()} | {:error, String.t()}
  @callback get_by_organization_id_and_simulation_name(
              pid :: pid(),
              org_id :: String.t(),
              name :: String.t()
            ) :: {:ok, Simulation.t()} | {:error, String.t()}
end
