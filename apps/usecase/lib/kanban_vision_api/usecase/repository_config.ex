defmodule KanbanVisionApi.Usecase.RepositoryConfig do
  @moduledoc """
  Centralizes repository adapter selection for the application layer.

  Use cases depend on repository ports and receive the concrete adapter through
  runtime composition, keeping Command/Query execution decoupled from specific
  persistence modules.
  """

  @type repository_key :: :organization | :simulation | :board

  @spec fetch!(repository_key()) :: module()
  def fetch!(key) when key in [:organization, :simulation, :board] do
    repositories =
      Application.get_env(:usecase, :repositories, [])

    Keyword.fetch!(repositories, key)
  end

  @spec fetch_from_opts!(module(), keyword()) :: module()
  def fetch_from_opts!(caller, opts) when is_list(opts) do
    case Keyword.fetch(opts, :repository) do
      {:ok, repository} ->
        repository

      :error ->
        raise ArgumentError,
              "missing required :repository option when calling " <>
                "#{inspect(caller)}. Ensure repository wiring is configured."
    end
  end
end
