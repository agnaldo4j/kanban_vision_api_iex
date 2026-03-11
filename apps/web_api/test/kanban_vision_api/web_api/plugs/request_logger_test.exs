defmodule KanbanVisionApi.WebApi.Plugs.RequestLoggerTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias KanbanVisionApi.WebApi.Plugs.RequestLogger

  @opts RequestLogger.init([])

  describe "call/2" do
    test "passes the conn through unchanged" do
      conn =
        :get
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> RequestLogger.call(@opts)

      assert conn.request_path == "/api/v1/organizations"
      assert conn.method == "GET"
    end

    test "registers a before_send callback" do
      conn =
        :get
        |> conn("/api/v1/organizations")
        |> Plug.Conn.assign(:correlation_id, "test-id")
        |> RequestLogger.call(@opts)

      assert length(conn.private.before_send) > 0
    end
  end
end
