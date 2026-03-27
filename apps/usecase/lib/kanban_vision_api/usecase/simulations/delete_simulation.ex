defmodule KanbanVisionApi.Usecase.Simulations.DeleteSimulation do
  @moduledoc """
  Use Case: Delete an existing simulation.

  Orchestrates the deletion of a simulation, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.RepositoryConfig
  alias KanbanVisionApi.Usecase.Simulation.DeleteSimulationCommand

  @type result :: {:ok, Simulation.t()} | {:error, String.t()}

  @spec execute(DeleteSimulationCommand.t(), term(), keyword()) :: result()
  def execute(%DeleteSimulationCommand{} = cmd, repository_runtime, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = RepositoryConfig.fetch_from_opts!(__MODULE__, opts)

    Logger.info("Deleting simulation",
      correlation_id: correlation_id,
      simulation_id: cmd.id
    )

    case repository.delete(repository_runtime, cmd.id) do
      {:ok, sim} ->
        Logger.info("Simulation deleted successfully",
          correlation_id: correlation_id,
          simulation_id: sim.id,
          simulation_name: sim.name,
          organization_id: sim.organization_id
        )

        EventEmitter.emit(
          :simulation,
          :simulation_deleted,
          %{
            simulation_id: sim.id,
            simulation_name: sim.name,
            organization_id: sim.organization_id
          },
          correlation_id
        )

        {:ok, sim}

      {:error, reason} = error ->
        Logger.error("Failed to delete simulation",
          correlation_id: correlation_id,
          simulation_id: cmd.id,
          reason: reason
        )

        error
    end
  end
end
