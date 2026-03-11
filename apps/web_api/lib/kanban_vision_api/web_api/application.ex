defmodule KanbanVisionApi.WebApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:web_api, :port, 4000)
    start_server = Application.get_env(:web_api, :start_server, true)

    children =
      if start_server do
        [{Bandit, plug: KanbanVisionApi.WebApi.Router, port: port}]
      else
        []
      end

    opts = [strategy: :one_for_one, name: KanbanVisionApi.WebApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
