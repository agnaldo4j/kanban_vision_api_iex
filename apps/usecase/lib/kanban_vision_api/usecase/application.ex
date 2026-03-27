defmodule KanbanVisionApi.Usecase.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias KanbanVisionApi.Usecase.RepositoryConfig

  @impl true
  def start(_type, _args) do
    children = [
      {KanbanVisionApi.Usecase.Organization,
       name: KanbanVisionApi.Usecase.Organization,
       repository: RepositoryConfig.fetch!(:organization)},
      {KanbanVisionApi.Usecase.Simulation,
       name: KanbanVisionApi.Usecase.Simulation, repository: RepositoryConfig.fetch!(:simulation)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KanbanVisionApi.Usecase.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
