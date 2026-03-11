defmodule KanbanVisionApi.WebApi.Plugs.CorrelationIdTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias KanbanVisionApi.WebApi.Plugs.CorrelationId

  @opts CorrelationId.init([])

  describe "call/2 when X-Correlation-ID header is present" do
    test "uses the provided correlation ID" do
      conn =
        :get
        |> conn("/test")
        |> put_req_header("x-correlation-id", "my-correlation-id")
        |> CorrelationId.call(@opts)

      assert conn.assigns.correlation_id == "my-correlation-id"
    end

    test "echoes the correlation ID in response header" do
      conn =
        :get
        |> conn("/test")
        |> put_req_header("x-correlation-id", "my-correlation-id")
        |> CorrelationId.call(@opts)

      assert get_resp_header(conn, "x-correlation-id") == ["my-correlation-id"]
    end
  end

  describe "call/2 when X-Correlation-ID header is absent" do
    test "generates a new UUID correlation ID" do
      conn =
        :get
        |> conn("/test")
        |> CorrelationId.call(@opts)

      assert conn.assigns.correlation_id != nil
      assert String.length(conn.assigns.correlation_id) > 0
    end

    test "sets the generated ID in the response header" do
      conn =
        :get
        |> conn("/test")
        |> CorrelationId.call(@opts)

      [resp_id] = get_resp_header(conn, "x-correlation-id")
      assert resp_id == conn.assigns.correlation_id
    end
  end
end
