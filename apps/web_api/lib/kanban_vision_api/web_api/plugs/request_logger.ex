defmodule KanbanVisionApi.WebApi.Plugs.RequestLogger do
  @moduledoc """
  Plug: structured HTTP request logging with duration tracking.

  Logs request start immediately and response details (status, duration_ms)
  using `Plug.Conn.register_before_send/2` when the response is sent.
  """

  require Logger

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    start_time = System.monotonic_time()
    correlation_id = conn.assigns[:correlation_id]

    Logger.info("HTTP request received",
      correlation_id: correlation_id,
      method: conn.method,
      path: conn.request_path
    )

    register_before_send(conn, fn conn ->
      duration_ms =
        System.convert_time_unit(
          System.monotonic_time() - start_time,
          :native,
          :millisecond
        )

      Logger.info("HTTP response sent",
        correlation_id: correlation_id,
        method: conn.method,
        path: conn.request_path,
        status: conn.status,
        duration_ms: duration_ms
      )

      conn
    end)
  end
end
