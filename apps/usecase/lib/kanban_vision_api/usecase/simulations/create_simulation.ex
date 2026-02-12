defmodule KanbanVisionApi.Usecase.Simulations.CreateSimulation do
  @moduledoc """
  Use Case: Create a new simulation.

  Orchestrates the creation of a simulation, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  alias KanbanVisionApi.Agent.Simulations, as: SimulationRepository
  alias KanbanVisionApi.Domain.Simulation
  alias KanbanVisionApi.Usecase.Simulation.CreateSimulationCommand

  @type result :: {:ok, Simulation.t()} | {:error, String.t()}

  @spec execute(CreateSimulationCommand.t(), pid(), keyword()) :: result()
  def execute(%CreateSimulationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    Logger.info("Creating simulation",
      correlation_id: correlation_id,
      simulation_name: cmd.name,
      organization_id: cmd.organization_id
    )

    simulation = Simulation.new(cmd.name, cmd.description, cmd.organization_id)

    case SimulationRepository.add(repository_pid, simulation) do
      {:ok, sim} ->
        Logger.info("Simulation created successfully",
          correlation_id: correlation_id,
          simulation_id: sim.id,
          simulation_name: sim.name,
          organization_id: sim.organization_id
        )

        emit_event(:simulation_created, sim, correlation_id)
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

  defp emit_event(event_type, simulation, correlation_id) do
    try do
      :telemetry.execute(
        [:kanban_vision_api, :simulation, event_type],
        %{count: 1},
        %{
          simulation_id: simulation.id,
          simulation_name: simulation.name,
          organization_id: simulation.organization_id,
          correlation_id: correlation_id
        }
      )
    rescue
      UndefinedFunctionError ->
        :ok
    end
  end
end
