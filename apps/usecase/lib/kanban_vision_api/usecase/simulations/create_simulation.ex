defmodule KanbanVisionApi.Usecase.Simulations.CreateSimulation do
  @moduledoc """
  Use Case: Create a new simulation.

  Orchestrates the creation of a simulation, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.Usecase.EventEmitter
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand

  @default_repository KanbanVisionApi.Agent.Simulations

  @type result :: {:ok, Simulation.t()} | {:error, String.t()}

  @spec execute(CreateSimulationCommand.t(), pid(), keyword()) :: result()
  def execute(%CreateSimulationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    Logger.info("Creating simulation",
      correlation_id: correlation_id,
      simulation_name: cmd.name,
      organization_id: cmd.organization_id
    )

    simulation = Simulation.new(cmd.name, cmd.description, cmd.organization_id)

    case repository.add(repository_pid, simulation) do
      {:ok, sim} ->
        Logger.info("Simulation created successfully",
          correlation_id: correlation_id,
          simulation_id: sim.id,
          simulation_name: sim.name,
          organization_id: sim.organization_id
        )

        EventEmitter.emit(
          :simulation,
          :simulation_created,
          %{
            simulation_id: sim.id,
            simulation_name: sim.name,
            organization_id: sim.organization_id
          },
          correlation_id
        )

        {:ok, sim}

      {:error, reason} = error ->
        Logger.error("Failed to create simulation",
          correlation_id: correlation_id,
          simulation_name: cmd.name,
          organization_id: cmd.organization_id,
          reason: reason
        )

        error
    end
  end
end
