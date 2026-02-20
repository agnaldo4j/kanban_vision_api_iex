# Dia 2 — Módulo 2: Princípios SOLID em Elixir

> SOLID não é um conjunto de regras rígidas — é um guia para tornar código
> **tolerante a mudanças** e **fácil de entender**. Vamos ver cada princípio
> com exemplos reais do projeto.

---

## S — Single Responsibility Principle (SRP) (8 min)

> *"Uma classe deve ter apenas uma razão para mudar."*
> — Robert C. Martin

Em Elixir: **um módulo, uma responsabilidade**.

### Violação — múltiplas responsabilidades no mesmo módulo

```elixir
# RUIM — OrganizationService faz tudo
defmodule OrganizationService do
  def create(name, tribes) do
    # Validação
    if String.length(name) == 0, do: raise "nome inválido"

    # Criação da entidade
    org = %Organization{id: UUID.uuid4(), name: name, tribes: tribes}

    # Persistência
    Agent.update(:organizations, fn state -> Map.put(state, org.id, org) end)

    # Log
    IO.puts("Organização #{name} criada")

    # Notificação
    send_email("admin@company.com", "Nova org criada: #{name}")

    {:ok, org}
  end
end
# Razões para mudar: validação, criação, persistência, log, notificação (5 razões!)
```

### Solução — cada módulo tem uma responsabilidade

```elixir
# BOM — cada módulo tem UMA responsabilidade

# 1. Entidade — representa o conceito de domínio
# apps/kanban_domain/lib/kanban_vision_api/domain/organization.ex
defmodule KanbanVisionApi.Domain.Organization do
  defstruct [:id, :audit, :name, :tribes]

  def new(name, tribes \\ []) do
    %__MODULE__{id: UUID.uuid4(), audit: Audit.new(), name: name, tribes: tribes}
  end
  # Razão para mudar: mudança no conceito de Organization (apenas 1)
end

# 2. Use Case — orquestra o fluxo de negócio
# apps/usecase/lib/kanban_vision_api/usecase/organizations/create_organization.ex
defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    organization = Organization.new(cmd.name, cmd.tribes)
    repository.add(repository_pid, organization)
    # Razão para mudar: mudança no fluxo de criação (apenas 1)
  end
end

# 3. Repositório — cuida da persistência
# apps/persistence/lib/kanban_vision_api/agent/organizations.ex
defmodule KanbanVisionApi.Agent.Organizations do
  def add(pid, %Organization{} = org) do
    Agent.get_and_update(pid, fn state -> ... end)
    # Razão para mudar: mudança na estratégia de persistência (apenas 1)
  end
end

# 4. EventEmitter — cuida de telemetria
# apps/usecase/lib/kanban_vision_api/usecase/event_emitter.ex
defmodule KanbanVisionApi.Usecase.EventEmitter do
  def emit(context, event_type, metadata, correlation_id) do
    :telemetry.execute([:kanban_vision_api, context, event_type], ...)
    # Razão para mudar: mudança na estratégia de telemetria (apenas 1)
  end
end
```

### Teste que confirma SRP

Cada módulo pode ser testado **isoladamente**, sem precisar dos outros:

```elixir
# Testando a entidade isolada — sem persistência, sem log
test "cria organization com defaults" do
  org = Organization.new("Acme")
  assert org.name == "Acme"
  assert org.tribes == []
  assert is_binary(org.id)
end

# Testando o use case isolado — com repositório mock
test "cria organization via use case" do
  {:ok, cmd} = CreateOrganizationCommand.new("Acme")
  {:ok, pid} = MockRepository.start_link()

  {:ok, org} = CreateOrganization.execute(cmd, pid, repository: MockRepository)
  assert org.name == "Acme"
end
```

---

## O — Open/Closed Principle (OCP) (7 min)

> *"Software deve ser aberto para extensão, mas fechado para modificação."*

Em Elixir: **adicione novos comportamentos implementando interfaces (behaviours), não modificando código existente**.

### O sistema de repositórios é aberto para extensão

```elixir
# INTERFACE definida uma vez — nunca muda
# apps/kanban_domain/lib/kanban_vision_api/domain/ports/organization_repository.ex
defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @callback get_all(pid()) :: map()
  @callback get_by_id(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback add(pid(), Organization.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback delete(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
end
```

```elixir
# EXTENSÃO 1 — Agent (in-memory, atual)
defmodule KanbanVisionApi.Agent.Organizations do
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  @impl true
  def add(pid, org) do
    Agent.get_and_update(pid, fn state -> ... end)
  end
end

# EXTENSÃO 2 — PostgreSQL (futura, sem modificar código existente)
defmodule KanbanVisionApi.Postgres.Organizations do
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  @impl true
  def add(pid, org) do
    Repo.insert!(org)
  end
end

# EXTENSÃO 3 — Redis (futura, sem modificar código existente)
defmodule KanbanVisionApi.Redis.Organizations do
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  @impl true
  def add(pid, org) do
    Redix.command(pid, ["SET", org.id, Jason.encode!(org)])
  end
end
```

**Resultado:** O Use Case `CreateOrganization` **nunca é modificado** ao trocar a implementação de persistência. Apenas uma nova implementação do behaviour é criada.

### Extensão de Use Cases — sem modificar os existentes

```elixir
# Use Cases existentes — nunca modificados
# organizations/create_organization.ex
# organizations/delete_organization.ex
# organizations/get_all_organizations.ex

# Novo Use Case — apenas adicionado
# organizations/transfer_organization.ex
defmodule KanbanVisionApi.Usecase.Organizations.TransferOrganization do
  def execute(%TransferOrganizationCommand{} = cmd, pid, opts \\ []) do
    # nova funcionalidade sem tocar nos outros use cases
  end
end
```

---

## L — Liskov Substitution Principle (LSP) (7 min)

> *"Objetos de uma subclasse devem ser substituíveis por objetos da superclasse sem alterar o comportamento correto do programa."*

Em Elixir: **qualquer implementação de um behaviour deve ser substituível por qualquer outra**.

### O contrato define o comportamento esperado

```elixir
# CONTRATO — o que se espera de qualquer repositório
defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @callback add(pid(), Organization.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  #                                          ↑ contrato de retorno
  # Qualquer implementação DEVE retornar {:ok, org} ou {:error, string}
end
```

### Implementação correta — respeita o contrato

```elixir
# Agent — respeita o contrato (sempre {:ok} ou {:error, string})
@impl true
def add(pid, %Organization{} = org) do
  Agent.get_and_update(pid, fn state ->
    case internal_get_by_name(state.organizations, org.name) do
      {:error, _} ->
        new_orgs = Map.put(state.organizations, org.id, org)
        {{:ok, org}, %{state | organizations: new_orgs}}        # ✓ {:ok, org}

      {:ok, _} ->
        {{:error, "Organization with name: #{org.name} already exist"}, state}  # ✓ {:error, string}
    end
  end)
end
```

### Contract tests — garantindo LSP

O projeto usa **testes de contrato** para verificar que todas as implementações respeitam o behaviour:

```elixir
# apps/persistence/test/kanban_vision_api/agent/organization_repository_contract_test.exs
# Este teste roda para TODAS as implementações do OrganizationRepository

defmodule KanbanVisionApi.OrganizationRepositoryContractTest do
  use ExUnit.Case

  # Define quais implementações serão testadas
  @implementations [
    KanbanVisionApi.Agent.Organizations
    # KanbanVisionApi.Postgres.Organizations  ← quando implementar
    # KanbanVisionApi.Redis.Organizations     ← quando implementar
  ]

  for impl <- @implementations do
    @impl impl

    describe "#{@impl} deve respeitar o contrato OrganizationRepository" do
      setup do
        {:ok, pid} = @impl.start_link()
        {:ok, pid: pid}
      end

      test "add/2 retorna {:ok, org} ao adicionar nova organização", %{pid: pid} do
        org = Organization.new("Acme")
        assert {:ok, ^org} = @impl.add(pid, org)
      end

      test "add/2 retorna {:error, string} ao adicionar org duplicada", %{pid: pid} do
        org = Organization.new("Acme")
        @impl.add(pid, org)
        assert {:error, reason} = @impl.add(pid, org)
        assert is_binary(reason)   # sempre string, não atom nem mapa
      end
    end
  end
end
```

---

## I — Interface Segregation Principle (ISP) (6 min)

> *"Clientes não devem ser forçados a depender de interfaces que não usam."*

Em Elixir: **behaviours focados, não genéricos demais**.

### Violação — behaviour monolítico

```elixir
# RUIM — um único behaviour que mistura responsabilidades
defmodule KanbanVisionApi.Domain.Ports.MegaRepository do
  # Organizações
  @callback get_organization(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback add_organization(pid(), Organization.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback delete_organization(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}

  # Simulações
  @callback get_simulation(pid(), String.t()) :: {:ok, Simulation.t()} | {:error, String.t()}
  @callback add_simulation(pid(), Simulation.t()) :: {:ok, Simulation.t()} | {:error, String.t()}

  # Boards
  @callback get_board(pid(), String.t()) :: {:ok, Board.t()} | {:error, String.t()}
  @callback add_board(pid(), Board.t()) :: {:ok, Board.t()} | {:error, String.t()}
  # ... 20 callbacks
end

# Quem implementa esse behaviour DEVE implementar todos os 20 callbacks
# mesmo que só precise de 3
```

### Solução — behaviours focados (como o projeto faz)

```elixir
# BOM — três behaviours separados e focados

# PORT 1 — apenas organizações
defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @callback get_all(pid()) :: map()
  @callback get_by_id(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback get_by_name(pid(), String.t()) :: {:ok, [Organization.t()]} | {:error, String.t()}
  @callback add(pid(), Organization.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback delete(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
end

# PORT 2 — apenas simulações
defmodule KanbanVisionApi.Domain.Ports.SimulationRepository do
  @callback get_all(pid()) :: map()
  @callback add(pid(), Simulation.t()) :: {:ok, Simulation.t()} | {:error, String.t()}
  @callback delete(pid(), String.t()) :: {:ok, Simulation.t()} | {:error, String.t()}
  @callback get_by_organization_id_and_simulation_name(pid(), String.t(), String.t()) ::
              {:ok, Simulation.t()} | {:error, String.t()}
end

# PORT 3 — apenas boards
defmodule KanbanVisionApi.Domain.Ports.BoardRepository do
  @callback get_all(pid()) :: map()
  @callback get_by_id(pid(), String.t()) :: {:ok, Board.t()} | {:error, String.t()}
  @callback add(pid(), Board.t()) :: {:ok, Board.t()} | {:error, String.t()}
  @callback delete(pid(), String.t()) :: {:ok, Board.t()} | {:error, String.t()}
  @callback get_all_by_simulation_id(pid(), String.t()) :: {:ok, [Board.t()]} | {:error, String.t()}
end
```

**Resultado:** Cada Adapter implementa apenas o behaviour que precisa. Um adapter de Organization não precisa saber nada sobre Boards.

---

## D — Dependency Inversion Principle (DIP) (7 min)

> *"Módulos de alto nível não devem depender de módulos de baixo nível. Ambos devem depender de abstrações."*
> *"Abstrações não devem depender de detalhes. Detalhes devem depender de abstrações."*

Em Elixir: **o domínio e os use cases dependem de behaviours (interfaces), não de implementações concretas**.

### Mapa de dependências do projeto

```
                  ┌──────────────────────────┐
                  │      kanban_domain       │
                  │  (alto nível — domínio)  │
                  │                          │
                  │  define: Organization    │
                  │  define: PORT behaviours │
                  └────────────┬─────────────┘
                               │ depende de (abstração)
                               ▼
                  ┌──────────────────────────┐
                  │         usecase          │
                  │  (alto nível — negócio)  │
                  │                          │
                  │  usa: PORT (behaviour)   │
                  │  NÃO conhece: Agents     │
                  └────────────┬─────────────┘
                               │ injeção em runtime
                               ▼
                  ┌──────────────────────────┐
                  │       persistence        │
                  │  (baixo nível — detalhe) │
                  │                          │
                  │  implementa: PORT        │
                  │  usa: Agent (concreto)   │
                  └──────────────────────────┘
```

### Inversão de dependência via injeção

```elixir
# Use Case — alto nível, depende apenas da abstração
defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @default_repository KanbanVisionApi.Agent.Organizations

  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    # Recebe o repositório como parâmetro — não instancia diretamente
    repository = Keyword.get(opts, :repository, @default_repository)
    #             ↑ injeção de dependência via opts

    organization = Organization.new(cmd.name, cmd.tribes)
    repository.add(repository_pid, organization)
    #          ↑ chama via interface (behaviour), não implementação
  end
end
```

```elixir
# O GenServer injeta o repositório ao inicializar
defmodule KanbanVisionApi.Usecase.Organization do
  use GenServer

  @default_repository KanbanVisionApi.Agent.Organizations

  @impl true
  def init(opts) do
    # Repositório configurável — injeção via opts
    repository = Keyword.get(opts, :repository, @default_repository)
    {:ok, agent_pid} = repository.start_link()
    {:ok, %{repository_pid: agent_pid, repository: repository}}
  end
end

# Produção — usa Agent
{:ok, pid} = Organization.start_link()

# Testes — injeta mock
{:ok, pid} = Organization.start_link(repository: MockOrganizationRepository)
```

### Diagrama de dependências (setas = "depende de")

```
persistence ──────────────────────────────►  kanban_domain (PORT)
                                                    ↑
usecase ────────────────────────────────────────────┘
           (depende do PORT, não da implementação)
```

```
# Mix.exs confirma a direção das dependências:

# persistence/mix.exs
deps: [{:kanban_domain, in_umbrella: true}]

# usecase/mix.exs
deps: [{:kanban_domain, in_umbrella: true},
       {:persistence, in_umbrella: true}]

# kanban_domain/mix.exs
deps: []  # zero dependências — núcleo puro
```

---

## SOLID — Verificação Rápida (5 min)

| Princípio | Pergunta | No projeto |
|-----------|----------|------------|
| **S** — SRP | Cada módulo tem uma razão para mudar? | `CreateOrganization` só muda se o fluxo de criar org muda |
| **O** — OCP | Posso estender sem modificar? | Novo adapter de persistência sem tocar nos Use Cases |
| **L** — LSP | Posso trocar implementações? | `Agent.Organizations` ↔ `Postgres.Organizations` |
| **I** — ISP | Behaviours são focados? | 3 behaviours separados: Org, Simulation, Board |
| **D** — DIP | Alto nível depende de abstrações? | Use Cases dependem de PORT behaviours |

### Red flags — SOLID sendo violado

```elixir
# SRP violado — módulo faz muitas coisas
defmodule OrganizationManager do  # "Manager" é sinal de alerta
  def create, do: ...
  def validate, do: ...
  def persist, do: ...
  def notify, do: ...
  def report, do: ...
end

# OCP violado — precisa modificar para adicionar
def add(pid, org, storage_type) do
  case storage_type do  # if/case por tipo de implementação = violação
    :agent    -> Agent.update(...)
    :postgres -> Repo.insert(...)
    :redis    -> Redix.command(...)
  end
end

# DIP violado — alto nível depende de detalhe
defmodule CreateOrganization do
  def execute(cmd) do
    # Instancia diretamente — não pode ser trocado!
    org = Organization.new(cmd.name)
    KanbanVisionApi.Agent.Organizations.add(org)  # acoplamento direto
  end
end
```

---

## Resumo do Módulo 3

```
S — Uma razão para mudar      → Use Cases separados por operação
O — Aberto para extensão      → Behaviours como contratos extensíveis
L — Substituível              → Contract tests garantem LSP
I — Interfaces focadas        → 3 behaviours ao invés de 1 mega-behaviour
D — Depender de abstrações    → Use Cases recebem repositório por injeção
```

> **Próximo módulo:** Use Cases — o coração da arquitetura hexagonal: como isolar o que o sistema faz de qualquer detalhe técnico.
