defmodule KanbanVisionApi.WebApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {KanbanVisionApi.WebApi.Application, []}
    ]
  end

  defp deps do
    [
      {:usecase, in_umbrella: true},
      {:bandit, "~> 1.0"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:open_api_spex, "~> 3.18"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
