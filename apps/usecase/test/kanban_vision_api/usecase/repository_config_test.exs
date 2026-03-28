defmodule KanbanVisionApi.Usecase.RepositoryConfigTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Agent.Boards
  alias KanbanVisionApi.Agent.Organizations
  alias KanbanVisionApi.Usecase.RepositoryConfig

  describe "fetch!/1" do
    test "returns the configured repository module" do
      original = Application.get_env(:usecase, :repositories)

      Application.put_env(:usecase, :repositories, organization: Organizations)

      on_exit(fn ->
        if original do
          Application.put_env(:usecase, :repositories, original)
        else
          Application.delete_env(:usecase, :repositories)
        end
      end)

      assert RepositoryConfig.fetch!(:organization) == Organizations
    end

    test "returns the configured board repository module" do
      original = Application.get_env(:usecase, :repositories)

      Application.put_env(:usecase, :repositories, board: Boards)

      on_exit(fn ->
        if original do
          Application.put_env(:usecase, :repositories, original)
        else
          Application.delete_env(:usecase, :repositories)
        end
      end)

      assert RepositoryConfig.fetch!(:board) == Boards
    end
  end

  describe "fetch_from_opts!/2" do
    test "returns repository from opts when present" do
      assert RepositoryConfig.fetch_from_opts!(__MODULE__, repository: Organizations) ==
               Organizations
    end

    test "raises a descriptive error when repository is missing" do
      assert_raise ArgumentError,
                   "missing required :repository option when calling #{inspect(__MODULE__)}. Ensure repository wiring is configured.",
                   fn ->
                     RepositoryConfig.fetch_from_opts!(__MODULE__, [])
                   end
    end
  end
end
