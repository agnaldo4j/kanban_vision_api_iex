defmodule KanbanVisionApi.WebApi.Plugs.CorrelationId do
  @moduledoc """
  Plug: extracts or generates a correlation ID for request tracing.

  Reads `X-Correlation-ID` header. If absent, generates a UUID.
  Stores the ID in `conn.assigns.correlation_id` and sets Logger metadata.
  """

  import Plug.Conn

  @behaviour Plug

  @header "x-correlation-id"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    correlation_id =
      case get_req_header(conn, @header) do
        [id | _] -> id
        [] -> UUID.uuid4()
      end

    Logger.metadata(correlation_id: correlation_id)

    conn
    |> assign(:correlation_id, correlation_id)
    |> put_resp_header(@header, correlation_id)
  end
end
