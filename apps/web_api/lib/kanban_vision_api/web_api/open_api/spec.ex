defmodule KanbanVisionApi.WebApi.OpenApi.Spec do
  @moduledoc """
  OpenAPI specification for the Kanban Vision REST API.

  Implements the OpenApiSpex.OpenApi behaviour so PutApiSpec can cache it.
  """

  @behaviour OpenApiSpex.OpenApi

  alias KanbanVisionApi.WebApi.OpenApi.Schemas.BoardSchema
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
          "BoardSummary" => BoardSchema.summary(),
          "BoardDetail" => BoardSchema.detail(),
          "Organization" => OrganizationSchema.schema(),
          "Simulation" => SimulationSchema.schema(),
          "Error" => ErrorSchema.schema()
        }
      }
    }
  end

  defp board_summary_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/BoardSummary"}
  defp board_detail_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/BoardDetail"}
  defp org_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Organization"}
  defp sim_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Simulation"}
  defp error_ref, do: %OpenApiSpex.Reference{"$ref": "#/components/schemas/Error"}

  defp org_list_schema do
    %OpenApiSpex.Schema{type: :array, items: org_ref()}
  end

  defp sim_list_schema do
    %OpenApiSpex.Schema{type: :array, items: sim_ref()}
  end

  defp board_list_schema do
    %OpenApiSpex.Schema{type: :array, items: board_summary_ref()}
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
      },
      "/api/v1/simulations/{simulation_id}/boards" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "List boards by simulation ID",
          operationId: "listBoardsBySimulationId",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :simulation_id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Boards for the simulation",
              content: json_content(board_list_schema())
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
        post: %OpenApiSpex.Operation{
          summary: "Create a board in a simulation",
          operationId: "createBoard",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :simulation_id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
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
              description: "Board created",
              content: json_content(board_summary_ref())
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
      "/api/v1/boards/{id}" => %OpenApiSpex.PathItem{
        get: %OpenApiSpex.Operation{
          summary: "Get board by ID",
          operationId: "getBoardById",
          tags: ["Boards"],
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
              description: "Board",
              content: json_content(board_detail_ref())
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
        patch: %OpenApiSpex.Operation{
          summary: "Rename a board",
          operationId: "renameBoard",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content: json_content(BoardSchema.rename_request())
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Renamed board",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
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
        },
        delete: %OpenApiSpex.Operation{
          summary: "Delete a board",
          operationId: "deleteBoard",
          tags: ["Boards"],
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
              description: "Deleted board",
              content: json_content(board_summary_ref())
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
      "/api/v1/boards/{id}/workflow/steps" => %OpenApiSpex.PathItem{
        post: %OpenApiSpex.Operation{
          summary: "Add a workflow step to a board",
          operationId: "addBoardWorkflowStep",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content: json_content(BoardSchema.add_step_request())
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Board after workflow step addition",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{
              description: "Not found",
              content: json_content(error_ref())
            },
            409 => %OpenApiSpex.Response{
              description: "Conflict",
              content: json_content(error_ref())
            },
            422 => %OpenApiSpex.Response{
              description: "Validation error",
              content: json_content(error_ref())
            }
          }
        }
      },
      "/api/v1/boards/{id}/workflow/steps/{step_id}" => %OpenApiSpex.PathItem{
        delete: %OpenApiSpex.Operation{
          summary: "Remove a workflow step from a board",
          operationId: "removeBoardWorkflowStep",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            },
            %OpenApiSpex.Parameter{
              name: :step_id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Board after workflow step removal",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{description: "Not found", content: json_content(error_ref())},
            422 => %OpenApiSpex.Response{description: "Validation error", content: json_content(error_ref())}
          }
        }
      },
      "/api/v1/boards/{id}/workflow/steps/{step_id}/order" => %OpenApiSpex.PathItem{
        patch: %OpenApiSpex.Operation{
          summary: "Reorder a workflow step in a board",
          operationId: "reorderBoardWorkflowStep",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            },
            %OpenApiSpex.Parameter{
              name: :step_id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content: json_content(BoardSchema.reorder_step_request())
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Board after workflow step reorder",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{description: "Not found", content: json_content(error_ref())},
            422 => %OpenApiSpex.Response{description: "Validation error", content: json_content(error_ref())}
          }
        }
      },
      "/api/v1/boards/{id}/workers" => %OpenApiSpex.PathItem{
        post: %OpenApiSpex.Operation{
          summary: "Allocate a worker to a board",
          operationId: "allocateBoardWorker",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          requestBody: %OpenApiSpex.RequestBody{
            required: true,
            content: json_content(BoardSchema.allocate_worker_request())
          },
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Board after worker allocation",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{description: "Not found", content: json_content(error_ref())},
            409 => %OpenApiSpex.Response{description: "Conflict", content: json_content(error_ref())},
            422 => %OpenApiSpex.Response{description: "Validation error", content: json_content(error_ref())}
          }
        }
      },
      "/api/v1/boards/{id}/workers/{worker_id}" => %OpenApiSpex.PathItem{
        delete: %OpenApiSpex.Operation{
          summary: "Remove a worker from a board",
          operationId: "removeBoardWorker",
          tags: ["Boards"],
          parameters: [
            %OpenApiSpex.Parameter{
              name: :id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            },
            %OpenApiSpex.Parameter{
              name: :worker_id,
              in: :path,
              required: true,
              schema: %OpenApiSpex.Schema{type: :string}
            }
          ],
          responses: %{
            200 => %OpenApiSpex.Response{
              description: "Board after worker removal",
              content: json_content(board_detail_ref())
            },
            404 => %OpenApiSpex.Response{description: "Not found", content: json_content(error_ref())},
            422 => %OpenApiSpex.Response{description: "Validation error", content: json_content(error_ref())}
          }
        }
      }
    }
  end
end
