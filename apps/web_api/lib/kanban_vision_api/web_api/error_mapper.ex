defmodule KanbanVisionApi.WebApi.ErrorMapper do
  @moduledoc false

  alias KanbanVisionApi.Domain.Ports.ApplicationError

  @spec normalize(term()) :: ApplicationError.t()
  def normalize(%ApplicationError{} = error), do: error

  def normalize(:invalid_name),
    do: ApplicationError.new(:invalid_input, "Invalid name", %{reason: :invalid_name})

  def normalize(:invalid_id),
    do: ApplicationError.new(:invalid_input, "Invalid ID", %{reason: :invalid_id})

  def normalize(:invalid_tribes),
    do: ApplicationError.new(:invalid_input, "Invalid tribes", %{reason: :invalid_tribes})

  def normalize(:invalid_organization_id) do
    ApplicationError.new(
      :invalid_input,
      "Invalid organization ID",
      %{reason: :invalid_organization_id}
    )
  end

  def normalize(:invalid_simulation_id) do
    ApplicationError.new(
      :invalid_input,
      "Invalid simulation ID",
      %{reason: :invalid_simulation_id}
    )
  end

  def normalize(:invalid_order),
    do: ApplicationError.new(:invalid_input, "Invalid order", %{reason: :invalid_order})

  def normalize(:invalid_required_ability_name) do
    ApplicationError.new(
      :invalid_input,
      "Invalid required ability name",
      %{reason: :invalid_required_ability_name}
    )
  end

  def normalize(:invalid_abilities) do
    ApplicationError.new(
      :invalid_input,
      "Invalid abilities",
      %{reason: :invalid_abilities}
    )
  end

  def normalize(:invalid_step_id),
    do: ApplicationError.new(:invalid_input, "Invalid step ID", %{reason: :invalid_step_id})

  def normalize(:invalid_worker_id) do
    ApplicationError.new(
      :invalid_input,
      "Invalid worker ID",
      %{reason: :invalid_worker_id}
    )
  end

  def normalize(reason) when is_binary(reason) do
    ApplicationError.new(:internal_error, reason, %{legacy_reason: :binary})
  end

  def normalize(_reason) do
    ApplicationError.new(:internal_error, "Internal server error", %{})
  end

  @spec http_status(ApplicationError.t()) :: pos_integer()
  def http_status(%ApplicationError{code: :invalid_input}), do: 422
  def http_status(%ApplicationError{code: :not_found}), do: 404
  def http_status(%ApplicationError{code: :conflict}), do: 409
  def http_status(%ApplicationError{code: :internal_error}), do: 500
  def http_status(%ApplicationError{}), do: 500
end
