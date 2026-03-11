defmodule KanbanVisionApi.WebApi.OpenApi.Spec do
  @moduledoc """
  OpenAPI specification for the Kanban Vision REST API.

  Implements the OpenApiSpex.OpenApi behaviour so PutApiSpec can cache it.
  """

  @behaviour OpenApiSpex.OpenApi

  alias KanbanVisionApi.WebApi.OpenApi.Schemas.ErrorSchema
  alias KanbanVisionApi.WebApi.OpenApi.Schemas.OrganizationSchema
  alias KanbanVisionApi.WebApi.OpenApi.Schemas.SimulationSchema

  @impl OpenApiSpex.OpenApi
  def spec do
    %OpenApiSpex.OpenApi{
      openapi: "3.0.0",
      info: %OpenApiSpex.Info{
        title: "Kanban Vision API",
        version: "1.0.0",
        description: "REST API for the Kanban Vision simulation platform"
      },
      servers: [
        %OpenApiSpex.Server{url: "http://localhost:4000", description: "Local development"}
      ],
      paths: paths(),
      components: %OpenApiSpex.Components{
        schemas: %{
          "Organization" => OrganizationSchema.schema(),
          "Simulation" => SimulationSchema.schema(),
          "Error" => ErrorSchema.schema()
        }
      }
    }
  end

  defp org_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Organization"}
  defp sim_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Simulation"}
  defp error_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Error"}

  defp org_list_schema do
    %OpenApiSpex.Schema{type: :array, items: org_ref()}
  end

  defp sim_list_schema do
    %OpenApiSpex.Schema{type: :array, items: sim_ref()}
  end

  defp json_content(schema) do
    %{"application/json" => %OpenApiSpex.MediaType{schema: schema}}
  end

  defp paths do
    %{
      "/api/v1/organizations" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "List all organizations",
          operationId: "listOrganizations",
          tags: ["Organizations"],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "List of organizations",
              content: json_content(org_list_schema())
            }
          }
        },
        post: %OpenApiSpex.Operation{
          summary: "Create an organization",
          operationId: "createOrganization",
          tags: ["Organizations"],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content:
              json_content(%OpenApiSpex.Schema{
                type: :object,
                properties: %{name: %OpenApiSpex.Schema{type: :string}},
                required: [:name]
              })
          },
          responses: %{
            201 => %OpenApiSpex.Response{
              description: "Organization created",
              content: json_content(org_ref())
            },
            409 => %OpenApiSpex.Response{
              description: "Already exists",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/organizations/search" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "Search organizations by name",
          operationId: "searchOrganizationsByName",
          tags: ["Organizations"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :name,
              in: :query,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Matching organizations",
              content: json_content(org_list_schema())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/organizations/{id}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "Get organization by ID",
          operationId: "getOrganizationById",
          tags: ["Organizations"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Organization",
              content: json_content(org_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        },
        delete: %OpenApiSpex.Operation{
          summary: "Delete an organization",
          operationId: "deleteOrganization",
          tags: ["Organizations"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Deleted organization",
              content: json_content(org_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/simulations" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "List all simulations",
          operationId: "listSimulations",
          tags: ["Simulations"],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "List of simulations",
              content: json_content(sim_list_schema())
            }
          }
        },
        post: %OpenApiSpex.Operation{
          summary: "Create a simulation",
          operationId: "createSimulation",
          tags: ["Simulations"],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content:
              json_content(%OpenApiSpex.Schema{
                type: :object,
                properties: %{
                  name: %OpenApiSpex.Schema{type: :string},
                  organization_id: %OpenApiSpex.Schema{type: :string},
                  description: %OpenApiSpex.Schema{type: :string}
                },
                required: [:name, :organization_id]
              })
          },
          responses: %{
            201 => %OpenApiSpex.Response{
              description: "Simulation created",
              content: json_content(sim_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Organization not found",
              content: json_content(error_ref())
            },
            409 => %OpenApiSpex.Response{
              description: "Already exists",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/simulations/search" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "Search simulation by organization and name",
          operationId: "searchSimulationByOrgAndName",
          tags: ["Simulations"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :org_id,
              in: :query,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            },
            %OpenApiSpex.Parameter{
              name: :name,
              in: :query,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Simulation",
              content: json_content(sim_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/simulations/{id}" => %OpenApiSpex.PathItem{
        delete: %OpenApiSpex.Operation{
          summary: "Delete a simulation",
          operationId: "deleteSimulation",
          tags: ["Simulations"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Deleted simulation",
              content: json_content(sim_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      }
    }
  end
end
