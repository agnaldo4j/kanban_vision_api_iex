# Módulo 1: Fundamentos de Elixir
## Duração: 50 minutos

> **Projeto de referência:** `kanban_vision_api_iex` — um simulador de Kanban board
> usando OTP e o padrão Object Prevalence (estado em memória via Agents).

---

## 1.1 Por que Elixir? (5 min)

Elixir roda sobre a **BEAM** (máquina virtual do Erlang), projetada para sistemas distribuídos, tolerantes a falhas e de alta concorrência. Características centrais:

- **Processos leves** — milhões de processos simultâneos no mesmo nó
- **Imutabilidade por padrão** — sem races conditions nos dados
- **Supervisão** — processos morrem e são reiniciados automaticamente
- **Pattern matching** — controle de fluxo expressivo e seguro

```
┌─────────────────────────────────────────┐
│              Elixir (sintaxe)           │
├─────────────────────────────────────────┤
│       BEAM VM (máquina virtual)         │
├─────────────────────────────────────────┤
│    Erlang OTP (bibliotecas/runtime)     │
└─────────────────────────────────────────┘
```

---

## 1.2 Tipos em Elixir (10 min)

### Tipos primitivos

```elixir
# Integer
42
1_000_000         # underscore como separador visual

# Float
3.14
1.0e10

# Boolean (são atoms!)
true
false

# Atom — identificadores imutáveis, não coletados pelo GC
:ok
:error
:not_found
nil               # também é atom

# String — binário UTF-8
"Olá, mundo!"
"Nome: #{name}"   # interpolação

# Charlists (raramente usados)
'hello'           # lista de code points
```

### Coleções

```elixir
# Lista encadeada — O(1) para prepend, O(n) para acesso
[1, 2, 3]
[head | tail] = [1, 2, 3]   # head = 1, tail = [2, 3]

# Tupla — acesso O(1), boa para retornos com status
{:ok, "resultado"}
{:error, "algo deu errado"}

# Map — chave-valor, qualquer tipo como chave
%{"nome" => "Alice", "idade" => 30}
%{nome: "Alice", idade: 30}  # chaves atom (sintaxe curta)

# Keyword list — lista de tuplas {atom, valor}
[timeout: 5000, retry: 3]
```

### Structs — o tipo mais importante no projeto

Structs são **Maps nomeados com campos fixos** e verificação em tempo de compilação.

```elixir
# Definição — do projeto real
# apps/kanban_domain/lib/kanban_vision_api/domain/organization.ex

defmodule KanbanVisionApi.Domain.Organization do
  alias KanbanVisionApi.Domain.{Audit, Tribe}

  defstruct [:id, :audit, :name, :tribes]

  @type t :: %__MODULE__{
    id:     String.t(),
    audit:  Audit.t(),
    name:   String.t(),
    tribes: [Tribe.t()]
  }
end
```

```elixir
# Uso
org = %Organization{id: "uuid", name: "Acme", tribes: [], audit: Audit.new()}

# Acesso
org.name          #=> "Acme"
org.tribes        #=> []

# Atualização — cria NOVO struct, não muta o original
org_atualizada = %{org | name: "Acme Corp"}
org.name          #=> "Acme"         # imutável!
org_atualizada.name #=> "Acme Corp"  # nova referência

# Pattern matching
%Organization{name: nome} = org
nome  #=> "Acme"

# Guard
is_struct(org, Organization)  #=> true
```

### @type — especificações de tipo

```elixir
# Do projeto real: apps/kanban_domain/lib/kanban_vision_api/domain/audit.ex
defmodule KanbanVisionApi.Domain.Audit do
  defstruct [:created, :updated]

  @type t :: %__MODULE__{
    created: DateTime.t(),
    updated: DateTime.t()
  }

  @spec new() :: t()
  def new do
    now = DateTime.utc_now()
    %__MODULE__{created: now, updated: now}
  end
end
```

`@type` e `@spec` são **documentação executável**: a ferramenta Dialyzer (análise estática) os usa para encontrar bugs antes do runtime.

```elixir
@spec new(String.t(), [Tribe.t()]) :: t()
def new(name, tribes \\ []) do
  %__MODULE__{
    id:     UUID.uuid4(),     # gera UUID aleatório
    audit:  Audit.new(),      # timestamps
    name:   name,
    tribes: tribes
  }
end
```

---

## 1.3 Pattern Matching (8 min)

Pattern matching é o mecanismo central de controle de fluxo em Elixir. O operador `=` é um **operador de correspondência**, não de atribuição.

```elixir
# Atribuição simples
x = 42

# Desestruturação de tupla
{:ok, resultado} = {:ok, "dados"}
resultado  #=> "dados"

# Falha de match
{:ok, _} = {:error, "falhou"}  # ** MatchError!

# Em funções — cláusulas
def processar({:ok, dado}),    do: "sucesso: #{dado}"
def processar({:error, motivo}), do: "erro: #{motivo}"

# case — match explícito
case buscar_organizacao(id) do
  {:ok, org}           -> mostrar(org)
  {:error, :not_found} -> {:error, "não encontrada"}
  {:error, motivo}     -> {:error, motivo}
end
```

### Pattern matching nas guards

```elixir
# Do projeto real — commands.ex
def new(name, tribes)
    when is_binary(name) and byte_size(name) > 0
    and is_list(tribes) do
  {:ok, %__MODULE__{name: name, tribes: tribes}}
end

def new(name, _tribes)
    when not is_binary(name) or byte_size(name) == 0 do
  {:error, :invalid_name}
end
```

### with — encadeamento de happy path

```elixir
# Usado nos Use Cases — fluxo de comandos
with {:ok, cmd}    <- CreateOrganizationCommand.new(name),
     {:ok, org}    <- repository.add(pid, Organization.new(cmd.name)),
     :ok           <- EventEmitter.emit(:organization_created, org) do
  {:ok, org}
else
  {:error, :invalid_name} -> {:error, "nome inválido"}
  {:error, reason}        -> {:error, reason}
end
```

---

## 1.4 Imutabilidade em Elixir (7 min)

**Toda estrutura de dados em Elixir é imutável.** Operações "modificadoras" sempre retornam uma **nova** estrutura.

```elixir
# Listas
lista = [1, 2, 3]
nova_lista = [0 | lista]     # prepend — nova lista
lista        #=> [1, 2, 3]   # original intacta
nova_lista   #=> [0, 1, 2, 3]

# Maps
mapa = %{nome: "Alice", idade: 30}
mapa_novo = %{mapa | idade: 31}
mapa.idade      #=> 30  # original
mapa_novo.idade #=> 31  # novo

# Structs — idêntico ao Map
org = Organization.new("Acme")
org_renomeada = %{org | name: "Acme Corp"}
org.name         #=> "Acme"      # original
org_renomeada.name #=> "Acme Corp" # novo
```

**Por que isso importa?**

```elixir
# Em sistemas concorrentes:
# Processo A lê org → nome = "Acme"
# Processo B muda org → novo struct "Acme Corp"
# Processo A ainda tem referência para "Acme" — sem race condition!

# Dados imutáveis são naturalmente thread-safe.
# O estado mutável fica encapsulado em Agents/GenServers.
```

### Eficiência: estrutural sharing

A BEAM não copia dados desnecessariamente. Listas e mapas compartilham estruturas:

```elixir
lista = [1, 2, 3, 4, 5]
nova  = [0 | lista]
# nova aponta para o mesmo [1,2,3,4,5] na memória — só o nó 0 é novo
```

---

## 1.5 Agents — Estado Simples (10 min)

Um **Agent** é um processo OTP que encapsula estado mutável. O acesso ao estado é feito via mensagens, garantindo serialização automática (sem locks explícitos).

```
┌─────────────────────────────────┐
│          Processo A             │
│  Agent.get(pid, fn s -> s end)  │─────────────────────┐
└─────────────────────────────────┘                     │
                                                       ▼
                                         ┌─────────────────────────┐
                                         │     Agent Process       │
                                         │   estado: %{...}        │
                                         │   mailbox: [msg1, msg2] │
                                         └─────────────────────────┘
                                                       ▲
┌─────────────────────────────────┐                   │
│          Processo B             │                   │
│  Agent.update(pid, fn s -> ...) │───────────────────┘
└─────────────────────────────────┘
```

Mensagens são processadas **uma por vez** — sem race conditions.

### Criando um Agent

```elixir
# Iniciando um agent com estado inicial
{:ok, pid} = Agent.start_link(fn -> %{} end)

# Lendo o estado
Agent.get(pid, fn state -> state end)
#=> %{}

# Atualizando o estado (retorna :ok)
Agent.update(pid, fn state -> Map.put(state, :contador, 0) end)

# Lendo após update
Agent.get(pid, fn state -> state end)
#=> %{contador: 0}

# Operação atômica: ler E atualizar em uma única mensagem
Agent.get_and_update(pid, fn state ->
  valor_atual = state.contador
  novo_estado = %{state | contador: valor_atual + 1}
  {valor_atual, novo_estado}   # retorna {resultado, novo_estado}
end)
#=> 0  (valor antes do increment)
```

### Agent no projeto real

```elixir
# apps/persistence/lib/kanban_vision_api/agent/organizations.ex
defmodule KanbanVisionApi.Agent.Organizations do
  use Agent

  # Agent implementa o PORT definido pelo domínio
  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  defstruct [:id, :organizations]

  def new(organizations \\ %{}, id \\ UUID.uuid4()) do
    %__MODULE__{id: id, organizations: organizations}
  end

  def start_link(default \\ __MODULE__.new()) do
    Agent.start_link(fn -> default end)
  end

  # READ — Agent.get/2 (não bloqueia outros leitores)
  def get_all(pid) do
    Agent.get(pid, fn state -> state.organizations end)
  end

  def get_by_id(pid, domain_id) do
    Agent.get(pid, fn state ->
      case Map.get(state.organizations, domain_id) do
        nil    -> {:error, "Organization with id: #{domain_id} not found"}
        domain -> {:ok, domain}
      end
    end)
  end

  # WRITE — Agent.get_and_update/2 (atômico!)
  def add(pid, %Organization{} = new_organization) do
    Agent.get_and_update(pid, fn state ->
      case internal_get_by_name(state.organizations, new_organization.name) do
        {:error, _} ->
          # Organização não existe — adicionar
          new_orgs = Map.put(state.organizations, new_organization.id, new_organization)
          {{:ok, new_organization}, %{state | organizations: new_orgs}}

        {:ok, _} ->
          # Já existe com esse nome — rejeitar
          {{:error, "Organization with name: #{new_organization.name} already exist"}, state}
      end
    end)
  end

  def delete(pid, domain_id) do
    Agent.get_and_update(pid, fn state ->
      case Map.get(state.organizations, domain_id) do
        nil ->
          {{:error, "Organization with id: #{domain_id} not found"}, state}

        domain ->
          new_orgs = Map.delete(state.organizations, domain.id)
          {{:ok, domain}, %{state | organizations: new_orgs}}
      end
    end)
  end
end
```

**Pontos chave:**
- `Agent.get_and_update/2` garante **atomicidade** — leitura + escrita em uma única mensagem
- O estado do agent é **sempre imutável dentro das funções** — retornamos um novo estado
- O Agent é iniciado com `start_link` → fica supervisionado (reinicia se morrer)

---

## 1.6 GenServer — Processos com Lógica (10 min)

Um **GenServer** é um processo OTP com lógica mais rica que um Agent. Enquanto Agents apenas guardam e transformam estado, GenServers podem:

- Orquestrar chamadas a outros processos
- Tratar diferentes tipos de mensagem
- Inicializar com lógica complexa
- Fazer chamadas síncronas (`call`) e assíncronas (`cast`)

```
┌──────────────────────────────────────────────────────────┐
│                     GenServer Process                    │
│                                                          │
│  init/1          → configura estado inicial             │
│  handle_call/3   → mensagem síncrona (cliente espera)   │
│  handle_cast/2   → mensagem assíncrona (fire-and-forget)│
│  handle_info/2   → mensagens não-OTP (timers, etc)      │
└──────────────────────────────────────────────────────────┘
```

### Exemplo simples: Contador

```elixir
defmodule Contador do
  use GenServer

  # ========== API Pública (Client) ==========

  def start_link(valor_inicial \\ 0) do
    GenServer.start_link(__MODULE__, valor_inicial, name: __MODULE__)
  end

  def incrementar(quantidade \\ 1) do
    GenServer.cast(__MODULE__, {:incrementar, quantidade})
  end

  def valor_atual() do
    GenServer.call(__MODULE__, :valor)
  end

  # ========== Callbacks (Server) ==========

  @impl true
  def init(valor_inicial) do
    {:ok, valor_inicial}
  end

  @impl true
  def handle_call(:valor, _from, estado) do
    {:reply, estado, estado}
    #         ↑         ↑
    #     resposta   novo estado (igual)
  end

  @impl true
  def handle_cast({:incrementar, qtd}, estado) do
    {:noreply, estado + qtd}
    #              ↑
    #          novo estado
  end
end

# Uso:
{:ok, _pid} = Contador.start_link(10)
Contador.incrementar(5)
Contador.valor_atual()   #=> 15
```

### GenServer no projeto real

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organization.ex
defmodule KanbanVisionApi.Usecase.Organization do
  use GenServer

  @default_repository KanbanVisionApi.Agent.Organizations

  # ========== API Pública ==========

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, opts)
  end

  def get_all(pid, opts \\ []) do
    GenServer.call(pid, {:get_all, opts})
  end

  def add(pid, %CreateOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def delete(pid, %DeleteOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:delete, cmd, opts})
  end

  # ========== Callbacks ==========

  @impl true
  def init(opts) do
    # Inicia o Agent de repositório e guarda o pid no estado
    repository = Keyword.get(opts, :repository, @default_repository)
    {:ok, agent_pid} = repository.start_link()
    {:ok, %{repository_pid: agent_pid, repository: repository}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    # Delega para o Use Case — GenServer apenas orquestra
    result = GetAllOrganizations.execute(state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateOrganization.execute(cmd, state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}
  end
end
```

**Observação importante:** O GenServer **não contém lógica de negócio**. Ele apenas orquestra chamadas para os Use Cases. A lógica fica nos módulos `CreateOrganization`, `GetAllOrganizations`, etc.

### Supervisor — supervisionando processos

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/application.ex
defmodule KanbanVisionApi.Usecase.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # GenServer de Organization é supervisionado
      {KanbanVisionApi.Usecase.Organization,
       name: KanbanVisionApi.Usecase.Organization},

      # GenServer de Simulation é supervisionado
      {KanbanVisionApi.Usecase.Simulation,
       name: KanbanVisionApi.Usecase.Simulation}
    ]

    # :one_for_one — se um filho morrer, só ele reinicia
    opts = [strategy: :one_for_one, name: KanbanVisionApi.Usecase.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```
Supervisor
├── Organization GenServer ──► Organizations Agent
└── Simulation GenServer  ──► Simulations Agent
```

Se o GenServer de Organization lançar uma exceção, o Supervisor o reinicia automaticamente, preservando a resiliência do sistema.

---

## 1.7 Exercício Prático (5 min)

```elixir
# No IEx — execute e observe:
iex -S mix

# 1. Criar uma Organization
alias KanbanVisionApi.Domain.Organization
org = Organization.new("Minha Empresa")
IO.inspect(org)                    # veja o struct com UUID e Audit

# 2. Tentar "mudar" o nome — observe que cria novo struct
org2 = %{org | name: "Empresa Modificada"}
org.name   # continua "Minha Empresa"
org2.name  # "Empresa Modificada"

# 3. Iniciar um Agent manualmente
alias KanbanVisionApi.Agent.Organizations
{:ok, pid} = Organizations.start_link()
Organizations.add(pid, org)
Organizations.add(pid, org2)
Organizations.get_all(pid)          # mapa com as duas orgs

# 4. Testar operação atômica
Organizations.delete(pid, org.id)
Organizations.delete(pid, "id-invalido")  # {:error, ...}
```

---

## Resumo do Módulo 1

| Conceito | Em Elixir |
|---------|-----------|
| **Tipos** | Structs com `defstruct` + `@type t()` |
| **Tipagem** | `@spec` + Dialyzer (estática) |
| **Imutabilidade** | Toda estrutura é imutável; operações retornam novas cópias |
| **Estado** | Encapsulado em Agents (simples) ou GenServers (com lógica) |
| **Concorrência** | Processos leves, mailbox, sem locks explícitos |
| **Tolerância a falhas** | Supervisor reinicia processos mortos |

> **Próximo módulo:** Como organizar esses blocos em uma arquitetura que "grita" o que o sistema faz.
