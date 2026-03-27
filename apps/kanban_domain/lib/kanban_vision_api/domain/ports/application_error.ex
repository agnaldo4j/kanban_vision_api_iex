defmodule KanbanVisionApi.Domain.Ports.ApplicationError do
  @moduledoc """
  Structured error contract shared across persistence, use cases, and adapters.
  """

  @enforce_keys [:code, :message, :details]
  defstruct [:code, :message, :details]

  @type code :: :invalid_input | :not_found | :conflict | :internal_error

  @type t :: %__MODULE__{
          code: code(),
          message: String.t(),
          details: map()
        }

  @type error_result :: {:error, t()}
  @type result(value) :: {:ok, value} | error_result()

  @spec new(code(), String.t(), map()) :: t()
  def new(code, message, details \\ %{})
      when is_atom(code) and is_binary(message) and is_map(details) do
    %__MODULE__{code: code, message: message, details: details}
  end

  @spec error(code(), String.t(), map()) :: error_result()
  def error(code, message, details \\ %{}) do
    {:error, new(code, message, details)}
  end

  @spec invalid_input(String.t(), map()) :: error_result()
  def invalid_input(message, details \\ %{}), do: error(:invalid_input, message, details)

  @spec not_found(String.t(), map()) :: error_result()
  def not_found(message, details \\ %{}), do: error(:not_found, message, details)

  @spec conflict(String.t(), map()) :: error_result()
  def conflict(message, details \\ %{}), do: error(:conflict, message, details)

  @spec internal_error(String.t(), map()) :: error_result()
  def internal_error(message, details \\ %{}), do: error(:internal_error, message, details)
end
