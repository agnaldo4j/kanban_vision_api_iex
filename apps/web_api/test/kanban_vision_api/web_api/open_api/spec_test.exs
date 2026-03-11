defmodule KanbanVisionApi.WebApi.OpenApi.SpecTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.WebApi.OpenApi.Spec

  describe "spec/0" do
    test "returns a valid OpenApi struct" do
      assert %OpenApiSpex.OpenApi{} = Spec.spec()
    end

    test "has correct metadata" do
      spec = Spec.spec()

      assert spec.openapi == "3.0.0"
      assert spec.info.title == "Kanban Vision API"
      assert spec.info.version == "1.0.0"
    end

    test "includes all organization and simulation paths" do
      spec = Spec.spec()

      assert Map.has_key?(spec.paths, "/api/v1/organizations")
      assert Map.has_key?(spec.paths, "/api/v1/organizations/search")
      assert Map.has_key?(spec.paths, "/api/v1/organizations/{id}")
      assert Map.has_key?(spec.paths, "/api/v1/simulations")
      assert Map.has_key?(spec.paths, "/api/v1/simulations/search")
      assert Map.has_key?(spec.paths, "/api/v1/simulations/{id}")
    end

    test "includes Organization, Simulation and Error schemas" do
      spec = Spec.spec()

      assert Map.has_key?(spec.components.schemas, "Organization")
      assert Map.has_key?(spec.components.schemas, "Simulation")
      assert Map.has_key?(spec.components.schemas, "Error")
    end
  end
end
