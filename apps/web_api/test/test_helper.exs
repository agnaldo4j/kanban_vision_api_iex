ExUnit.start(exclude: [:integration])

Mox.defmock(KanbanVisionApi.WebApi.OrganizationUsecaseMock,
  for: KanbanVisionApi.WebApi.Ports.OrganizationUsecase
)

Mox.defmock(KanbanVisionApi.WebApi.SimulationUsecaseMock,
  for: KanbanVisionApi.WebApi.Ports.SimulationUsecase
)
