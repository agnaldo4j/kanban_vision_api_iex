# Módulo 2: Screaming Architecture, Hexagonal Architecture e DDD
## Duração: 45 minutos

> Neste módulo vamos entender **por que** o projeto está organizado da forma que está,
> e **que problemas** essas arquiteturas resolvem.

---

## 2.1 O Problema: Arquitetura Técnica vs Arquitetura de Negócio (5 min)

### A armadilha clássica — organização por camada técnica

```
src/
├── controllers/
│   ├── organization_controller.ex
│   ├── simulation_controller.ex
│   └── board_controller.ex
├── services/
│   ├── organization_service.ex
│   └── simulation_service.ex
└── repositories/
    ├── organization_repo.ex
    └── simulation_repo.ex
```

**Problema:** Ao ver essa estrutura, você sabe que o sistema tem controllers, services e repositories. Mas **não sabe o que o sistema faz**. É um sistema financeiro? Logístico? Um game?

### A solução — Screaming Architecture

> *"A arquitetura deve gritar o propósito do sistema, não o framework que ele usa."*
> — Robert C. Martin (Uncle Bob)

```
apps/
├── kanban_domain/          # GRITA: domínio do Kanban
│   └── domain/
│       ├── organization.ex  # entidade de negócio
│       ├── simulation.ex    # entidade de negócio
│       ├── board.ex         # entidade de negócio
│       └── ports/           # interfaces do domínio
├── usecase/                # GRITA: casos de uso do sistema
│   └── usecase/
│       ├── organizations/
│       │   ├── create_organization.ex  # operação de negócio
│       │   └── delete_organization.ex
│       └── simulations/
│           └── create_simulation.ex
└── persistence/            # implementação técnica (detalhe)
    └── agent/
        └── organizations.ex
```

**O que você sabe ao ver essa estrutura:**
- O sistema lida com **Organizações**, **Simulações** e **Boards**
- Existem casos de uso explícitos: criar, deletar, buscar organizações
- Persistência é um detalhe de implementação — separada

---

## 2.2 Screaming Architecture em Detalhes (10 min)

### Princípio central

A estrutura de pastas e módulos deve refletir o **domínio de negócio**, não a tecnologia.

```
SEM screaming architecture:           COM screaming architecture:
"Parece um projeto Elixir/OTP"        "Parece um simulador de Kanban"
```

### Regras práticas

**1. Nomeie por comportamento de negócio, não por papel técnico**

```elixir
# RUIM — nome técnico genérico
defmodule OrganizationService do
  def create(params), do: ...
  def update(params), do: ...
  def delete(id), do: ...
  def list(), do: ...
end

# BOM — nome explícito do caso de uso
defmodule CreateOrganization do
  def execute(%CreateOrganizationCommand{} = cmd, pid, opts), do: ...
end

defmodule DeleteOrganization do
  def execute(%DeleteOrganizationCommand{} = cmd, pid, opts), do: ...
end
```

**2. A estrutura de pastas conta a história do negócio**

```
usecase/
├── organizations/          ← contexto: operações com organizações
│   ├── create_organization.ex
│   ├── delete_organization.ex
│   ├── get_organization_by_id.ex
│   ├── get_organization_by_name.ex
│   └── get_all_organizations.ex
└── simulations/            ← contexto: operações com simulações
    ├── create_simulation.ex
    ├── delete_simulation.ex
    └── get_simulation_by_org_and_name.ex
```

**3. O domínio não depende de nada externo**

```elixir
# kanban_domain/mix.exs — ZERO dependências externas
defp deps do
  [
    {:elixir_uuid, "~> 1.2.1"}  # apenas gerador de UUID
    # Sem Ecto, sem Phoenix, sem HTTP, sem banco de dados
  ]
end
```

---

## 2.3 Hexagonal Architecture (Ports & Adapters) (15 min)

Proposta por Alistair Cockburn em 2005. O objetivo: **isolar o núcleo da aplicação (domínio e casos de uso) de qualquer tecnologia externa**.

```
                    ┌─────────────────────────────────────┐
                    │           DOMÍNIO PURO              │
                    │  (sem framework, sem banco, sem HTTP)│
                    │                                     │
  Adapter HTTP  ───►│  ┌─────────────────────────────┐   │
  Adapter CLI   ───►│  │     Casos de Uso            │   │◄─── Adapter Agent
  Adapter Event ───►│  │  CreateOrganization         │   │◄─── Adapter Postgres
                    │  │  DeleteOrganization         │   │◄─── Adapter Mnesia
                    │  │  CreateSimulation           │   │
                    │  └─────────────────────────────┘   │
                    │                                     │
                    │  Entidades: Organization, Board...  │
                    └─────────────────────────────────────┘
                         ▲                         ▲
                    Portas de Entrada         Portas de Saída
                    (Driving Adapters)        (Driven Adapters)
```

### Ports — as interfaces do domínio

O domínio define **o que precisa**, não **como é implementado**:

```elixir
# apps/kanban_domain/lib/kanban_vision_api/domain/ports/organization_repository.ex
# PORT — interface definida pelo domínio

defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  alias KanbanVisionApi.Domain.Organization

  @doc "Retorna todas as organizações"
  @callback get_all(pid :: pid()) :: map()

  @doc "Busca organização por ID"
  @callback get_by_id(pid :: pid(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}

  @doc "Busca organizações por nome"
  @callback get_by_name(pid :: pid(), name :: String.t()) ::
              {:ok, [Organization.t()]} | {:error, String.t()}

  @doc "Adiciona nova organização"
  @callback add(pid :: pid(), organization :: Organization.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}

  @doc "Remove organização"
  @callback delete(pid :: pid(), id :: String.t()) ::
              {:ok, Organization.t()} | {:error, String.t()}
end
```

### Adapters — as implementações concretas

```elixir
# apps/persistence/lib/kanban_vision_api/agent/organizations.ex
# ADAPTER — implementa o PORT usando Agent (in-memory)

defmodule KanbanVisionApi.Agent.Organizations do
  use Agent

  # IMPLEMENTA o contrato do PORT
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  # @impl true garante que a função implementa um callback do @behaviour
  @impl true
  def get_all(pid) do
    Agent.get(pid, fn state -> state.organizations end)
  end

  @impl true
  def add(pid, %Organization{} = new_organization) do
    Agent.get_and_update(pid, fn state ->
      # lógica de persistência em memória...
    end)
  end
end
```

### A injeção de dependência

O Use Case recebe o repositório como parâmetro — nunca instancia diretamente:

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organizations/create_organization.ex

defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @default_repository KanbanVisionApi.Agent.Organizations  # default em produção

  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    # Usa o repositório injetado — pode ser Agent, Postgres, mock de teste...
    repository = Keyword.get(opts, :repository, @default_repository)

    organization = Organization.new(cmd.name, cmd.tribes)

    case repository.add(repository_pid, organization) do
      {:ok, org} -> {:ok, org}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

```elixir
# Em produção — usa o Agent real
CreateOrganization.execute(cmd, pid)

# Em testes — usa um mock/stub
CreateOrganization.execute(cmd, pid, repository: MockRepository)

# No futuro — troca para Postgres sem tocar no Use Case
CreateOrganization.execute(cmd, pid, repository: PostgresOrganizationRepository)
```

### Benefícios concretos

| Situação | Sem Hexagonal | Com Hexagonal |
|----------|--------------|---------------|
| Trocar banco de dados | Modificar Use Cases + Domínio | Criar novo Adapter, zero mudanças no core |
| Testar Use Case isolado | Precisa de banco real | Mock do repositório |
| Adicionar interface CLI | Refatorar controllers | Novo Adapter driving, zero mudanças no core |
| Migrar de Agent para PostgreSQL | Refatoração em cascata | Novo Adapter + troca de configuração |

---

## 2.4 Domain Driven Design (DDD) (15 min)

DDD é uma abordagem para modelar software que alinha o código com o **idioma e conceitos do negócio**.

### Linguagem Ubíqua (Ubiquitous Language)

> *O código deve falar a mesma língua que o negócio.*

```elixir
# RUIM — linguagem técnica
defmodule UserGroupManager do
  def create_group(user_id, group_data), do: ...
  def add_member(group_id, member_id), do: ...
end

# BOM — linguagem do domínio Kanban
defmodule KanbanVisionApi.Domain.Organization do
  def new(name, tribes \\ []), do: ...
  # "Organization" e "Tribe" são termos usados pelo negócio
end

defmodule CreateOrganization do
  def execute(%CreateOrganizationCommand{} = cmd, ...), do: ...
  # "CreateOrganization" é uma ação que o negócio entende
end
```

### Bounded Contexts — Contextos delimitados

Um **Bounded Context** é uma fronteira explícita dentro da qual um modelo de domínio é válido e consistente. No projeto:

```
┌─────────────────────────────────┐  ┌──────────────────────────────────┐
│   Bounded Context: Organização  │  │  Bounded Context: Simulação      │
│                                 │  │                                  │
│  Organization                   │  │  Simulation                      │
│    └── Tribe                    │  │    └── Board                     │
│          └── Squad              │  │          └── Workflow             │
│                └── Worker       │  │                └── Step          │
│                      └── Ability│  │                      └── Task   │
└─────────────────────────────────┘  └──────────────────────────────────┘
         kommunication via              communication via
         organization_id             ──► simulation_id
```

A Simulação referencia a Organização apenas pelo **ID**, não importa toda a estrutura:

```elixir
# apps/kanban_domain/lib/kanban_vision_api/domain/simulation.ex
defmodule KanbanVisionApi.Domain.Simulation do
  defstruct [:id, :audit, :name, :description, :organization_id, :board, :default_projects]

  #                                              ↑
  # Referência cruzada apenas por ID — não importa Organization diretamente
  # Cada contexto evolui de forma independente
end
```

### Entidades vs Value Objects vs Aggregates

#### Entidade — tem identidade própria (ID)

```elixir
# Organization é uma entidade — identificada pelo id
org1 = Organization.new("Acme")
org2 = Organization.new("Acme")

org1.id != org2.id   # true — são entidades DIFERENTES apesar do mesmo nome
```

#### Value Object — definido pelos seus valores, sem identidade

```elixir
# Audit é um Value Object — dois Audit iguais são intercambiáveis
# apps/kanban_domain/lib/kanban_vision_api/domain/audit.ex

defmodule KanbanVisionApi.Domain.Audit do
  defstruct [:created, :updated]
  # Não tem :id — a identidade é o próprio valor (created + updated)

  def new do
    now = DateTime.utc_now()
    %__MODULE__{created: now, updated: now}
  end
end

# ServiceClass também é um Value Object no contexto do Step
defmodule KanbanVisionApi.Domain.ServiceClass do
  defstruct [:id, :audit, :name]
  # Define a classe de serviço de uma tarefa — o valor importa, não a instância
end
```

#### Aggregate — cluster de entidades com uma raiz

```
Organization (Aggregate Root)
   ├── Tribe (entidade filha — acessada através de Organization)
   │     └── Squad (entidade filha)
   │           └── Worker (entidade filha)
   │                 └── Ability (value object ou entidade filha)
```

O **Aggregate Root** é o ponto de entrada — você não manipula Tribe diretamente, mas sempre através de Organization.

#### Factory — criação padronizada

```elixir
# Toda entidade tem uma função factory new/N que:
# 1. Gera o ID (UUID)
# 2. Define defaults
# 3. Cria o Audit com timestamps

def new(name, tribes \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
  %__MODULE__{id: id, audit: audit, name: name, tribes: tribes}
end
```

### Repositories — abstrações de persistência

No DDD, o Repository é a abstração que o domínio usa para persistir/recuperar agregados:

```elixir
# PORT no domínio (o que o domínio quer)
defmodule KanbanVisionApi.Domain.Ports.OrganizationRepository do
  @callback get_by_id(pid(), String.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  @callback add(pid(), Organization.t()) :: {:ok, Organization.t()} | {:error, String.t()}
  # ... outros callbacks
end

# ADAPTER na persistência (como é implementado)
defmodule KanbanVisionApi.Agent.Organizations do
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  @impl true
  def add(pid, %Organization{} = org) do
    Agent.get_and_update(pid, fn state ->
      # implementação específica do Agent
    end)
  end
end
```

### Domain Events — comunicação entre contextos

```elixir
# Quando uma organização é criada, emitimos um evento de domínio
# Outros contextos podem reagir sem acoplamento direto

# apps/usecase/lib/kanban_vision_api/usecase/event_emitter.ex
defmodule KanbanVisionApi.Usecase.EventEmitter do
  def emit(context, event_type, metadata, correlation_id) do
    :telemetry.execute(
      [:kanban_vision_api, context, event_type],
      %{count: 1},
      Map.put(metadata, :correlation_id, correlation_id)
    )
  end
end

# Uso em CreateOrganization
EventEmitter.emit(
  :organization,
  :organization_created,                              # evento de domínio
  %{organization_id: org.id, organization_name: org.name},
  correlation_id
)
```

---

## Resumo do Módulo 2

### As três arquiteturas trabalham juntas

```
┌──────────────────────────────────────────────────────────────┐
│                    SCREAMING ARCHITECTURE                     │
│  "A estrutura revela o propósito: simulador de Kanban"       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              HEXAGONAL ARCHITECTURE                    │  │
│  │  "O domínio no centro, adapters ao redor"             │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │                    DDD                           │  │  │
│  │  │  "Linguagem ubíqua, bounded contexts,           │  │  │
│  │  │   entidades, value objects, aggregates"         │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

| Arquitetura | Responde | No projeto |
|-------------|----------|------------|
| Screaming | O que o sistema faz? | Pastas `organizations/`, `simulations/` |
| Hexagonal | Como as partes se comunicam? | Ports em `domain/ports/`, Adapters em `agent/` |
| DDD | Como modelamos o domínio? | Entidades, Value Objects, Factories, Repositories |

> **Próximo módulo:** Os princípios SOLID — como garantir que cada peça dessa arquitetura seja bem projetada internamente.
