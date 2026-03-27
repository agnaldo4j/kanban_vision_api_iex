defmodule KanbanVisionApi.Usecase.ErrorMetadata do
  @moduledoc false

  alias KanbanVisionApi.Domain.Ports.ApplicationError

  @spec from_reason(term()) :: keyword()
  def from_reason(%ApplicationError{} = error) do
    [
      error_code: error.code,
      error_message: error.message,
      error_details: error.details
    ]
  end

  def from_reason(reason), do: [reason: reason]
end
