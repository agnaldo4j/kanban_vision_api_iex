defmodule KanbanVisionApi.WebApi.Boards.BoardController do
  @moduledoc """
  HTTP adapter: translates HTTP requests to Board use case calls.
  """

  import Plug.Conn

  alias KanbanVisionApi.Usecase.Board.CreateBoardCommand
  alias KanbanVisionApi.Usecase.Board.DeleteBoardCommand
  alias KanbanVisionApi.Usecase.Board.GetBoardByIdQuery
  alias KanbanVisionApi.Usecase.Board.GetBoardsBySimulationIdQuery
  alias KanbanVisionApi.WebApi.Boards.BoardSerializer
  alias KanbanVisionApi.WebApi.ErrorMapper

  @spec call(Plug.Conn.t(), atom()) :: Plug.Conn.t()
  def call(conn, :get_by_id) do
    id = conn.path_params["id"]

    with {:ok, query} <- GetBoardByIdQuery.new(id),
         {:ok, board} <- board_usecase().get_by_id(query, build_opts(conn)) do
      respond(conn, 200, BoardSerializer.serialize(board))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :get_by_simulation_id) do
    simulation_id = conn.path_params["simulation_id"]

    with {:ok, query} <- GetBoardsBySimulationIdQuery.new(simulation_id),
         {:ok, boards} <- board_usecase().get_by_simulation_id(query, build_opts(conn)) do
      respond(conn, 200, BoardSerializer.serialize_many_list(boards))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :create) do
    name = conn.body_params["name"]
    simulation_id = conn.path_params["simulation_id"]

    with {:ok, cmd} <- CreateBoardCommand.new(name, simulation_id),
         {:ok, board} <- board_usecase().add(cmd, build_opts(conn)) do
      respond(conn, 201, BoardSerializer.serialize(board))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :delete) do
    id = conn.path_params["id"]

    with {:ok, cmd} <- DeleteBoardCommand.new(id),
         {:ok, board} <- board_usecase().delete(cmd, build_opts(conn)) do
      respond(conn, 200, BoardSerializer.serialize(board))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  defp board_usecase do
    Application.get_env(
      :web_api,
      :board_usecase,
      KanbanVisionApi.WebApi.Adapters.BoardAdapter
    )
  end

  defp build_opts(conn), do: [correlation_id: conn.assigns[:correlation_id]]

  defp respond(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp respond_error(conn, reason) do
    error = ErrorMapper.normalize(reason)
    respond(conn, ErrorMapper.http_status(error), %{error: error.message})
  end
end
