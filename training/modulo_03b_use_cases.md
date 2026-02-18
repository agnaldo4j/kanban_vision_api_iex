# Módulo 3b: Use Cases — O Coração da Arquitetura Hexagonal
## Duração: 40 minutos

> Use Cases são a razão de existir de toda a arquitetura hexagonal.
> São eles que expressam **o que o sistema faz** — e garantem que esse conhecimento
> não vaze para nenhuma camada técnica.

---

## 3b.1 O que é um Use Case? (7 min)

Um Use Case representa **uma única intenção do usuário (ou sistema) que produz um resultado de negócio observável**.

> "Criar uma organização", "Deletar uma simulação", "Buscar board por ID"
> são Use Cases. "Salvar no banco", "Validar JWT" não são — são detalhes técnicos.

### O que um Use Case faz

```
Recebe um Command ou Query
         ↓
Aplica regras de negócio (sem saber de HTTP, banco, framework)
         ↓
Delega persistência via Port (interface)
         ↓
Registra observabilidade (log + evento)
         ↓
Retorna {:ok, resultado} ou {:error, reason}
```

### O que um Use Case **não** faz

```
✗ Não conhece HTTP (conn, params, headers)
✗ Não conhece Ecto (Repo, Changeset, Schema)
✗ Não conhece Phoenix, Plug, ou qualquer framework
✗ Não instancia repositórios — recebe via injeção
✗ Não orquestra múltiplos Use Cases (isso é papel do GenServer ou Saga)
✗ Não contém lógica de apresentação (serialização JSON, formatação)
```

### Por que isso importa?

```
Sem Use Cases isolados:         Com Use Cases isolados:

Controller → DB                 Controller → Use Case → Port → Adapter
    ↑                                  ↑
"Se trocar o banco,             "Trocar o banco = novo Adapter.
 tenho que alterar              O Use Case não sabe que houve troca."
 o controller também."
```

---

## 3b.2 Anatomia de um Use Case no projeto (10 min)

Todo Use Case do projeto segue a mesma estrutura. Vamos dissecar o `CreateOrganization`:

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organizations/create_organization.ex

defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  @moduledoc """
  Use Case: Create a new organization.        ← documenta a intenção de negócio

  Orchestrates the creation of an organization, ensuring business rules,
  logging, and event emission.
  """

  require Logger

  # Importa apenas domínio e interfaces — NUNCA adapters diretos
  alias KanbanVisionApi.Domain.Organization                            # (1)
  alias KanbanVisionApi.Usecase.EventEmitter                           # (2)
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand # (3)

  @default_repository KanbanVisionApi.Agent.Organizations              # (4)

  # Contrato explícito do resultado
  @type result :: {:ok, Organization.t()} | {:error, String.t()}       # (5)

  @spec execute(CreateOrganizationCommand.t(), pid(), keyword()) :: result() # (6)
  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4()) # (7)
    repository = Keyword.get(opts, :repository, @default_repository)  # (8)

    Logger.info("Creating organization",                              # (9)
      correlation_id: correlation_id,
      organization_name: cmd.name,
      tribes_count: length(cmd.tribes)
    )

    organization = Organization.new(cmd.name, cmd.tribes)             # (10)

    case repository.add(repository_pid, organization) do              # (11)
      {:ok, org} ->
        Logger.info("Organization created successfully",              # (12)
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        EventEmitter.emit(                                            # (13)
          :organization,
          :organization_created,
          %{organization_id: org.id, organization_name: org.name},
          correlation_id
        )

        {:ok, org}                                                    # (14)

      {:error, reason} = error ->
        Logger.error("Failed to create organization",                 # (15)
          correlation_id: correlation_id,
          organization_name: cmd.name,
          reason: reason
        )
        error                                                         # (16)
    end
  end
end
```

**Legenda — cada decisão de design:**

| # | Decisão | Por quê |
|---|---------|---------|
| (1) | Alias apenas de `Domain` | Use Case conhece o domínio, não adapters |
| (2) | EventEmitter centralizado | Telemetria não polui a lógica de negócio |
| (3) | Importa o Command pelo tipo | Garante que só aceita input validado |
| (4) | `@default_repository` como módulo | Permite override em testes sem mudar a lógica |
| (5) | `@type result` explícito | Documenta o contrato de retorno |
| (6) | `@spec` completo | Dialyzer verifica tipos em tempo de compilação |
| (7) | `correlation_id` via opts | Rastreabilidade sem acoplamento |
| (8) | `repository` via opts | Injeção de dependência — DIP em ação |
| (9) | Log no início | Observabilidade: "o que está sendo tentado" |
| (10) | `Organization.new(...)` | Domínio cria a entidade — lógica no lugar certo |
| (11) | `repository.add(...)` | Chama via PORT (interface), não implementação |
| (12) | Log no sucesso | Observabilidade: "o que aconteceu" |
| (13) | `EventEmitter.emit` | Telemetria: métrica de negócio |
| (14) | `{:ok, org}` | Retorno consistente com o @type result |
| (15) | Log no erro | Observabilidade: "o que falhou e por quê" |
| (16) | Repassa `error` sem transformar | Não esconde informação de quem chamou |

---

## 3b.3 Isolamento — o núcleo da questão (12 min)

### O que "isolado" significa na prática

Um Use Case é **isolado** quando você consegue:

1. Testá-lo sem banco de dados
2. Testá-lo sem HTTP server
3. Trocá-lo de contexto (HTTP → CLI → mensageria) sem reescrever
4. Trocar o adapter de persistência sem tocar nele

```
┌─────────────────────────────────────────────────────────────┐
│                    ZONA PROIBIDA                            │
│         (nunca entra num Use Case)                         │
│                                                             │
│  Plug.Conn  •  Phoenix.Controller  •  Ecto.Repo            │
│  HTTPoison  •  Jason.encode!       •  Absinthe.Schema       │
│  File.read  •  System.cmd          •  GenServer.start_link  │
└─────────────────────────────────────────────────────────────┘
         ↓ proibidos         ↓ permitidos
┌─────────────────────────────────────────────────────────────┐
│                     USE CASE                               │
│                                                             │
│  Domain structs  •  PORT behaviours  •  Logger             │
│  Commands/Queries  •  EventEmitter  •  UUID.uuid4()        │
│  Pattern matching  •  with/case  •  Enum.map/filter        │
└─────────────────────────────────────────────────────────────┘
```

### Como o GenServer mantém o isolamento

O **GenServer** funciona como portão de entrada — ele conhece os adapters, mas protege o Use Case:

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organization.ex

defmodule KanbanVisionApi.Usecase.Organization do
  use GenServer

  @default_repository KanbanVisionApi.Agent.Organizations

  # init/1 — único lugar que toca o adapter concreto
  @impl true
  def init(opts) do
    repository = Keyword.get(opts, :repository, @default_repository)
    {:ok, agent_pid} = repository.start_link()
    #                   ↑ GenServer conhece o adapter e gerencia o lifecycle
    {:ok, %{repository_pid: agent_pid, repository: repository}}
  end

  # handle_call — apenas roteia para o Use Case
  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateOrganization.execute(cmd, state.repository_pid, enrich_opts(opts, state))
    #        ↑ Use Case recebe o pid e o módulo — não sabe COMO o Agent funciona
    {:reply, result, state}
  end

  defp enrich_opts(opts, state) do
    Keyword.put_new(opts, :repository, state.repository)
    # ↑ Injeta o módulo do repositório para que o Use Case possa usá-lo
  end
end
```

```
Cliente chama:  Organization.add(pid, cmd)
                        ↓
GenServer:      handle_call({:add, cmd, opts})
                → gerencia estado e lifecycle do Agent
                → injeta repository_pid e módulo nos opts
                        ↓
Use Case:       CreateOrganization.execute(cmd, pid, opts)
                → não sabe que há um GenServer acima dele
                → não sabe que há um Agent abaixo dele
                → só sabe que repository.add/2 existe
```

### Testando o isolamento

O teste mais revelador: **Use Case sem GenServer, sem Agent real**

```elixir
# Imagine um mock de repositório para o teste unitário do Use Case

defmodule MockOrganizationRepository do
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  def start_link(initial \\ %{}), do: Agent.start_link(fn -> initial end)

  def add(pid, org) do
    Agent.get_and_update(pid, fn state ->
      if Map.has_key?(state, org.name) do
        {{:error, "já existe"}, state}
      else
        {{:ok, org}, Map.put(state, org.name, org)}
      end
    end)
  end

  def get_all(pid), do: Agent.get(pid, & &1)
  def get_by_id(_pid, _id), do: {:error, "not found"}
  def get_by_name(_pid, _name), do: {:error, "not found"}
  def delete(_pid, _id), do: {:error, "not found"}
end
```

```elixir
# Teste unitário do Use Case — zero infraestrutura real
defmodule CreateOrganizationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Usecase.Organizations.CreateOrganization
  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand

  describe "execute/3" do
    setup do
      {:ok, pid} = MockOrganizationRepository.start_link()
      {:ok, pid: pid}
    end

    test "cria organização com sucesso", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("Acme")

      # Use Case é testado com mock — sem Agent real, sem GenServer
      assert {:ok, org} = CreateOrganization.execute(
        cmd, pid,
        repository: MockOrganizationRepository
      )

      assert org.name == "Acme"
      assert is_binary(org.id)
    end

    test "rejeita nome duplicado", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("Acme")
      CreateOrganization.execute(cmd, pid, repository: MockOrganizationRepository)

      assert {:error, _} = CreateOrganization.execute(
        cmd, pid,
        repository: MockOrganizationRepository
      )
    end
  end
end
```

**Resultado:** O Use Case roda em microssegundos, sem banco, sem network, sem estado global.

---

## 3b.4 Uma operação = um Use Case (6 min)

### A regra

> Cada Use Case tem **exatamente uma função pública**: `execute/N`.

Isso não é acidente — é um compromisso com SRP (Single Responsibility Principle) em nível de módulo.

```
organizations/
├── create_organization.ex     ← CreateOrganization.execute/3
├── delete_organization.ex     ← DeleteOrganization.execute/3
├── get_organization_by_id.ex  ← GetOrganizationById.execute/3
├── get_organization_by_name.ex ← GetOrganizationByName.execute/3
└── get_all_organizations.ex   ← GetAllOrganizations.execute/2

Cada arquivo = uma operação = uma razão para mudar
```

### Por que não um módulo só com várias funções?

```elixir
# RUIM — OrganizationUseCases com tudo junto
defmodule OrganizationUseCases do
  def create(cmd, pid, opts), do: ...   # regra A
  def delete(cmd, pid, opts), do: ...   # regra B
  def get_by_id(q, pid, opts), do: ...  # regra C
  def get_by_name(q, pid, opts), do: ... # regra D
  def get_all(pid, opts), do: ...       # regra E

  # Agora tem 5 razões para mudar este módulo.
  # Qualquer mudança em qualquer operação exige recompilação de todos.
  # Testes ficam acoplados — não é possível testar create sem importar delete.
end
```

```elixir
# BOM — um módulo por operação
# Cada Use Case pode ser desenvolvido, versionado e testado de forma independente.
# Adicionar CreateOrganizationV2 não toca em DeleteOrganization.

defmodule CreateOrganization do
  def execute(%CreateOrganizationCommand{} = cmd, pid, opts), do: ...
  # Única razão para mudar: mudança na regra de criação de organização
end

defmodule DeleteOrganization do
  def execute(%DeleteOrganizationCommand{} = cmd, pid, opts), do: ...
  # Única razão para mudar: mudança na regra de exclusão de organização
end
```

### Adicionando um novo Use Case sem tocar nos existentes

```
Requisito novo: "Buscar organizações por nome de tribe"

Ação:
1. Criar get_organization_by_tribe_name.ex
2. Adicionar callback no PORT (OrganizationRepository)
3. Implementar no Adapter (Agent.Organizations)
4. Adicionar GetOrganizationByTribeNameQuery
5. Expor via GenServer (novo handle_call)

Resultado:
- CreateOrganization.ex   → NÃO TOCADO
- DeleteOrganization.ex   → NÃO TOCADO
- GetOrganizationById.ex  → NÃO TOCADO
- Todos os testes existentes → CONTINUAM PASSANDO
```

**OCP em ação**: aberto para extensão, fechado para modificação.

---

## 3b.5 Use Cases e Testabilidade (5 min)

### Os três níveis de teste para Use Cases

```
Nível 1: Teste unitário do Use Case          (rápido, mock do repositório)
Nível 2: Teste de integração via GenServer   (médio, Agent real)
Nível 3: Teste de contrato do repositório    (lento, valida o adapter)
```

#### Nível 1 — Use Case em isolamento total

```elixir
# Testa apenas a lógica do Use Case — sem GenServer, sem Agent real
test "use case cria organização com regras corretas" do
  {:ok, pid} = MockOrganizationRepository.start_link()
  {:ok, cmd} = CreateOrganizationCommand.new("Acme", [tribe1])

  {:ok, org} = CreateOrganization.execute(cmd, pid, repository: MockOrganizationRepository)

  # Verifica resultado de negócio
  assert org.name == "Acme"
  assert org.tribes == [tribe1]
  assert %Audit{} = org.audit
end
```

#### Nível 2 — Integração real via GenServer

```elixir
# apps/usecase/test/kanban_vision_api/usecase/organization_test.exs
# Testa o fluxo completo: GenServer → Use Case → Agent

describe "When start with empty state" do
  setup [:start_usecase]

  test "should add a new organization via command", %{pid: pid} do
    {:ok, cmd} = CreateOrganizationCommand.new("TestOrg")
    assert {:ok, org} = Organization.add(pid, cmd)    # GenServer.call
    assert org.name == "TestOrg"
    assert org.id != nil
  end

  defp start_usecase(_), do: [{:ok, pid} = Organization.start_link(), pid: pid]
end
```

#### Nível 3 — Contrato do repositório

```elixir
# apps/persistence/test/.../organization_repository_contract_test.exs
# Garante que o Adapter (Agent) respeita o PORT (behaviour)

test "add/2 retorna {:ok, org} ao adicionar nova organização" do
  org = Organization.new("Acme")
  assert {:ok, ^org} = Organizations.add(pid, org)
  # Se mudar o Adapter, este teste captura quebras de contrato
end
```

### Por que testes por camada?

```
Unitários (Use Case com mock):
→ Testam regras de negócio de forma isolada
→ Rápidos (< 1ms por teste)
→ Não quebram se a implementação do Agent mudar

Integração (via GenServer):
→ Testam o fluxo completo: Command → GenServer → Use Case → Agent
→ Médios (< 10ms por teste)
→ Detectam problemas de orquestração

Contrato (Adapter vs PORT):
→ Testam que o Adapter respeita o behaviour
→ Médios
→ Garantem que qualquer nova implementação é substituível (LSP)
```

---

## 3b.6 Use Cases como documentação viva (bônus — 3 min)

Uma consequência poderosa do isolamento: **a pasta `use_cases/` documenta tudo que o sistema faz**.

```
organizations/
├── create_organization.ex          → "O sistema cria organizações"
├── delete_organization.ex          → "O sistema deleta organizações"
├── get_organization_by_id.ex       → "O sistema busca org por ID"
├── get_organization_by_name.ex     → "O sistema busca org por nome"
└── get_all_organizations.ex        → "O sistema lista todas as orgs"

simulations/
├── create_simulation.ex            → "O sistema cria simulações"
├── delete_simulation.ex            → "O sistema deleta simulações"
├── get_simulation_by_org_and_name.ex → "O sistema busca simulação por org+nome"
└── get_all_simulations.ex          → "O sistema lista todas as simulações"
```

Um novo desenvolvedor lê essa estrutura e entende **o que o sistema faz** sem ler uma linha de código. Screaming Architecture + Use Cases isolados = documentação que não fica desatualizada.

---

## 3b.7 Anti-patterns — o que evitar nos Use Cases (3 min)

### 1. Use Case chamando outro Use Case diretamente

```elixir
# RUIM — acoplamento entre Use Cases
defmodule CreateSimulation do
  def execute(cmd, pid, opts) do
    # Dependência direta em outro Use Case!
    {:ok, org} = GetOrganizationById.execute(...)

    simulation = Simulation.new(cmd.name, org.id)
    repository.add(pid, simulation)
  end
end

# BOM — use o repositório para validar, ou passe os dados validados no Command
defmodule CreateSimulation do
  def execute(cmd, pid, opts) do
    # O Command já traz organization_id validado
    # A responsabilidade de garantir que a org existe
    # é do adapter/camada de entrada, não deste Use Case
    simulation = Simulation.new(cmd.name, cmd.organization_id)
    repository.add(pid, simulation)
  end
end
```

### 2. Lógica de negócio fora do Use Case

```elixir
# RUIM — lógica de negócio no GenServer (handle_call)
def handle_call({:add, cmd, opts}, _from, state) do
  # Lógica de negócio aqui viola SRP do GenServer!
  if String.length(cmd.name) < 3 do
    {:reply, {:error, :name_too_short}, state}
  else
    organization = Organization.new(cmd.name)
    result = state.repository.add(state.repository_pid, organization)
    {:reply, result, state}
  end
end

# BOM — GenServer apenas delega; regras ficam no Use Case ou no Command
def handle_call({:add, cmd, opts}, _from, state) do
  result = CreateOrganization.execute(cmd, state.repository_pid, enrich_opts(opts, state))
  {:reply, result, state}
end
```

### 3. Use Case gerenciando lifecycle de processos

```elixir
# RUIM — Use Case inicia Agent
defmodule CreateOrganization do
  def execute(cmd, opts) do
    {:ok, pid} = Organizations.start_link()  # ← vazamento de responsabilidade!
    Organizations.add(pid, Organization.new(cmd.name))
  end
end

# BOM — pid é injetado (gerenciado pelo GenServer ou pelo teste)
defmodule CreateOrganization do
  def execute(cmd, repository_pid, opts) do
    repository = Keyword.get(opts, :repository, @default_repository)
    repository.add(repository_pid, Organization.new(cmd.name))
  end
end
```

### 4. Retornar tipos inconsistentes

```elixir
# RUIM — retorna tipos diferentes dependendo do caminho
def execute(cmd, pid, opts) do
  case repository.add(pid, org) do
    {:ok, org}       -> org          # ← inconsistente! às vezes é o struct direto
    {:error, reason} -> {:error, reason}
  end
end

# BOM — sempre {:ok, _} ou {:error, _}
def execute(cmd, pid, opts) do
  case repository.add(pid, org) do
    {:ok, org} = result  -> result           # ← sempre tupla
    {:error, _} = error  -> error
  end
end
```

---

## Resumo do Módulo 3b

```
┌─────────────────────────────────────────────────────────────────┐
│                       USE CASE                                  │
│                                                                 │
│  Recebe:   Command (escrita) ou Query (leitura)                │
│  Conhece:  Domain structs + PORT behaviours + Logger           │
│  Ignora:   HTTP, Ecto, Phoenix, Agent, GenServer lifecycle     │
│  Retorna:  {:ok, resultado} | {:error, reason}  (sempre)       │
│                                                                 │
│  Responsabilidade:  UMA operação de negócio                    │
│  Testável:          Sim — com mock do repositório              │
│  Substituível:      Sim — troca adapter sem tocar no Use Case  │
│  Documentação:      A pasta é a documentação do sistema        │
└─────────────────────────────────────────────────────────────────┘

Fluxo completo (com todas as camadas):

Client
  ↓ Command/Query (validado)
GenServer           ← mantém lifecycle do Agent, roteia chamadas
  ↓ delega
Use Case            ← lógica de negócio isolada, testável, pura
  ↓ usa PORT
Adapter (Agent)     ← implementa o PORT, gerencia estado
  ↓ persiste
Domain Entity       ← struct imutável, sem infra
```

| Papel | Módulo | Responsabilidade |
|-------|--------|-----------------|
| Portão | GenServer `Organization` | Orquestra lifecycle, roteia |
| Intenção | `CreateOrganizationCommand` | Entrada validada |
| Lógica | `CreateOrganization` | Uma regra de negócio |
| Contrato | `OrganizationRepository` PORT | Interface de persistência |
| Implementação | `Agent.Organizations` | Estado em memória |
| Entidade | `Organization` | Struct imutável do domínio |

> **Próximo módulo:** Os princípios SOLID — como cada peça dessa estrutura é projetada internamente.
