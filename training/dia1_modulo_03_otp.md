# Dia 1 — Módulo 3: OTP — Agents, GenServer e Supervisor

> OTP (Open Telecom Platform) é o conjunto de bibliotecas e padrões
> do Erlang/Elixir para construir sistemas concorrentes e tolerantes a falhas.
> Neste módulo você vai entender como o projeto usa OTP para gerenciar estado.

---

## 3.1 Processos — a unidade de concorrência da BEAM

Em Elixir, **tudo roda em processos**. Não threads do sistema operacional — processos leves da BEAM, que podem existir aos milhões.

```
┌─────────────────────────────────────────────────────┐
│                  BEAM VM                            │
│                                                     │
│  Processo 1  Processo 2  Processo 3  ... Processo N │
│  (leve ~2KB) (leve ~2KB) (leve ~2KB)                │
│                                                     │
│  Cada processo tem:                                 │
│  - Memória própria (sem compartilhamento)           │
│  - Mailbox (fila de mensagens)                      │
│  - Garbage collector próprio                        │
└─────────────────────────────────────────────────────┘
```

### Processos se comunicam por mensagens

```elixir
# Criando um processo simples
pid = spawn(fn ->
  receive do
    {:oi, nome} -> IO.puts("Olá, #{nome}!")
    :tchau      -> IO.puts("Até logo!")
  end
end)

# Enviando mensagem
send(pid, {:oi, "Alice"})   #=> imprime "Olá, Alice!"

# self() retorna o PID do processo atual
IO.inspect(self())   #=> #PID<0.123.0>
```

**Na prática, você raramente usa `spawn` + `send` diretamente.** OTP fornece abstrações de alto nível: **Agent**, **GenServer** e **Supervisor**.

---

## 3.2 Agent — estado simples

Um **Agent** é a abstração mais simples para guardar estado. Ele é um processo que:
- Mantém um valor de estado
- Responde a mensagens para ler ou atualizar esse estado
- Garante acesso serial (sem race conditions)

```
┌──────────────┐   Agent.get(pid, fn)    ┌─────────────────────────┐
│  Processo A  │ ──────────────────────► │                         │
└──────────────┘                         │     Agent Process       │
                                         │   estado: %{...}        │
┌──────────────┐   Agent.update(pid, fn) │   mailbox: [msg1, msg2] │
│  Processo B  │ ──────────────────────► │                         │
└──────────────┘                         └─────────────────────────┘
                   mensagens processadas uma por vez → sem race condition
```

### API do Agent

```elixir
# Iniciar — recebe função que retorna o estado inicial
{:ok, pid} = Agent.start_link(fn -> [] end)
{:ok, pid} = Agent.start_link(fn -> %{} end, name: :meu_agent)  # nomeado

# Ler — Agent.get/2 (não bloqueia outras leituras)
Agent.get(pid, fn estado -> estado end)
Agent.get(pid, & &1)   # shorthand equivalente

# Atualizar — retorna :ok
Agent.update(pid, fn estado -> [novo_item | estado] end)

# Ler E atualizar — ATÔMICO (uma única mensagem!)
Agent.get_and_update(pid, fn estado ->
  novo_estado = Map.put(estado, :chave, "valor")
  {estado, novo_estado}   # {valor_retornado, novo_estado}
end)

# Parar
Agent.stop(pid)
```

### Por que `get_and_update` é importante?

```elixir
# RUIM — duas operações separadas — não atômico!
valor = Agent.get(pid, & &1)           # operação 1
Agent.update(pid, fn _ -> novo end)    # operação 2
# Entre as duas operações, outro processo pode alterar o estado!

# BOM — uma única operação atômica
Agent.get_and_update(pid, fn estado ->
  # lê e decide o novo estado numa única mensagem ao Agent
  {estado, novo_estado}
end)
```

### Agent no projeto real

```elixir
# apps/persistence/lib/kanban_vision_api/agent/organizations.ex
defmodule KanbanVisionApi.Agent.Organizations do
  use Agent

  @behaviour KanbanVisionApi.Domain.Ports.OrganizationRepository

  defstruct [:id, :organizations]

  def new(organizations \\ %{}, id \\ UUID.uuid4()) do
    %__MODULE__{id: id, organizations: organizations}
  end

  def start_link(default \\ __MODULE__.new()) do
    Agent.start_link(fn -> default end)
  end

  # Leitura — apenas Agent.get
  def get_all(pid) do
    Agent.get(pid, fn state -> state.organizations end)
  end

  # Escrita atômica — Agent.get_and_update
  def add(pid, %Organization{} = new_organization) do
    Agent.get_and_update(pid, fn state ->
      case internal_get_by_name(state.organizations, new_organization.name) do
        {:error, _} ->
          new_orgs = Map.put(state.organizations, new_organization.id, new_organization)
          new_state = put_in(state.organizations, new_orgs)
          {{:ok, new_organization}, new_state}

        {:ok, _} ->
          {{:error, "Organization with name: #{new_organization.name} already exist"}, state}
      end
    end)
  end

  defp internal_get_by_name(organizations, domain_name) do
    Map.values(organizations)
    |> Enum.filter(fn domain -> domain.name == domain_name end)
    |> case do
      [] -> {:error, "Organization with name: #{domain_name} not found"}
      values -> {:ok, values}
    end
  end
end
```

---

## 3.3 GenServer — processos com lógica

**GenServer** (Generic Server) é a abstração OTP mais poderosa. Enquanto Agent apenas guarda e transforma estado, GenServer pode:

- Orquestrar chamadas a outros processos
- Ter lógica complexa de inicialização
- Responder a diferentes tipos de mensagem
- Fazer chamadas síncronas e assíncronas

```
┌────────────────────────────────────────────────────────────┐
│                   GenServer Process                        │
│                                                            │
│  init/1          ← chamado ao iniciar; retorna estado      │
│  handle_call/3   ← mensagem SÍNCRONA; cliente espera       │
│  handle_cast/2   ← mensagem ASSÍNCRONA; fire-and-forget    │
│  handle_info/2   ← outras mensagens (timers, monitores)    │
│  terminate/2     ← chamado ao encerrar (cleanup)           │
└────────────────────────────────────────────────────────────┘
```

### call vs cast

```
call (síncrono):
  Cliente envia mensagem → ESPERA resposta → recebe resposta
  Use quando: precisa do resultado antes de continuar

cast (assíncrono):
  Cliente envia mensagem → NÃO espera → continua executando
  Use quando: não precisa de resposta (fire-and-forget)
```

### Exemplo passo a passo: Contador

```elixir
defmodule Contador do
  use GenServer

  # ========== API Pública (interface para o caller) ==========

  def start_link(inicial \\ 0) do
    # Inicia o processo GenServer; __MODULE__ = Contador
    GenServer.start_link(__MODULE__, inicial, name: __MODULE__)
  end

  # call — síncrono, retorna o valor atual
  def valor_atual() do
    GenServer.call(__MODULE__, :valor)
  end

  # call — síncrono, retorna o valor antes do incremento
  def incrementar_e_obter(qtd \\ 1) do
    GenServer.call(__MODULE__, {:incrementar, qtd})
  end

  # cast — assíncrono, não retorna nada útil
  def incrementar(qtd \\ 1) do
    GenServer.cast(__MODULE__, {:incrementar, qtd})
  end

  # ========== Callbacks (implementação do servidor) ==========

  @impl true
  def init(inicial) do
    # Retorna {:ok, estado_inicial}
    {:ok, inicial}
  end

  @impl true
  def handle_call(:valor, _from, estado) do
    # {:reply, resposta, novo_estado}
    {:reply, estado, estado}   # responde com o valor, estado não muda
  end

  @impl true
  def handle_call({:incrementar, qtd}, _from, estado) do
    novo = estado + qtd
    {:reply, estado, novo}   # responde com valor ANTES, novo estado é incrementado
  end

  @impl true
  def handle_cast({:incrementar, qtd}, estado) do
    # {:noreply, novo_estado} — sem resposta
    {:noreply, estado + qtd}
  end
end

# Uso:
{:ok, _pid} = Contador.start_link(10)
Contador.incrementar(5)           # assíncrono — não espera
Contador.valor_atual()            #=> 15
Contador.incrementar_e_obter(3)   #=> 15 (valor antes do +3)
Contador.valor_atual()            #=> 18
```

### GenServer no projeto real

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organization.ex
defmodule KanbanVisionApi.Usecase.Organization do
  use GenServer

  @default_repository KanbanVisionApi.Agent.Organizations

  # API Pública — interface para o exterior
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, Keyword.take(opts, [:name]))
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

  # Callbacks — implementação do servidor

  @impl true
  def init(opts) do
    # Inicia o Agent de repositório e guarda o pid no estado do GenServer
    repository = Keyword.get(opts, :repository, @default_repository)
    {:ok, agent_pid} = repository.start_link()
    {:ok, %{repository_pid: agent_pid, repository: repository}}
  end

  @impl true
  def handle_call({:get_all, opts}, _from, state) do
    # Delega para o Use Case — GenServer apenas orquestra
    result = GetAllOrganizations.execute(state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}   # state não muda — só leitura
  end

  @impl true
  def handle_call({:add, cmd, opts}, _from, state) do
    result = CreateOrganization.execute(cmd, state.repository_pid, enrich_opts(opts, state))
    {:reply, result, state}   # state não muda — Agent mudou internamente
  end
end
```

**Observação:** O GenServer **não contém lógica de negócio**. Ele apenas recebe a mensagem, delega para o Use Case, e repassa o resultado. O estado do GenServer guarda apenas referências (o pid do Agent e o módulo do repositório).

---

## 3.4 Supervisor — tolerância a falhas

Um **Supervisor** monitora processos filhos e os reinicia quando morrem. Este é o núcleo da filosofia "let it crash" do Erlang/Elixir.

```
Supervisor
├── Organization GenServer ←──┐
└── Simulation GenServer  ←──┘
                               ↑
        Se um filho morrer, o Supervisor o reinicia
        (sem afetar os outros filhos — estratégia :one_for_one)
```

### Estratégias de reinício

```elixir
# :one_for_one  — só reinicia o filho que morreu
# :one_for_all  — reinicia TODOS se qualquer um morrer
# :rest_for_one — reinicia o que morreu + todos iniciados depois dele
```

### Supervisor no projeto real

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/application.ex
defmodule KanbanVisionApi.Usecase.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Cada tupla: {Módulo, opts_para_start_link}
      {KanbanVisionApi.Usecase.Organization,
       name: KanbanVisionApi.Usecase.Organization},

      {KanbanVisionApi.Usecase.Simulation,
       name: KanbanVisionApi.Usecase.Simulation}
    ]

    opts = [strategy: :one_for_one, name: KanbanVisionApi.Usecase.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### O ciclo de vida do sistema

```
mix run / iex -S mix
       ↓
BEAM inicia
       ↓
Application.start(:usecase, ...) é chamado
       ↓
KanbanVisionApi.Usecase.Application.start/2
       ↓
Supervisor inicia filhos:
  ├── Organization.start_link() → init/1 → Agent.start_link()
  └── Simulation.start_link()  → init/1 → Agent.start_link()
       ↓
Sistema rodando — GenServers aguardam mensagens

-- Falha --
Organization GenServer lança exceção
       ↓
Supervisor detecta morte do processo
       ↓
Supervisor reinicia Organization.start_link()
       ↓
Sistema restaurado automaticamente
```

### Por que `name:` nos GenServers?

```elixir
# Sem name — acesso por pid (você precisa guardar o pid)
{:ok, pid} = Organization.start_link()
Organization.get_all(pid)   # precisa passar o pid

# Com name — acesso pelo nome do módulo (registrado globalmente)
{:ok, _} = Organization.start_link(name: Organization)
Organization.get_all(Organization)   # pode usar o módulo como nome
# ou simplesmente deixar o GenServer usar o name internamente
```

---

## 3.5 Árvore de supervisão do projeto

```
KanbanVisionApi.Usecase.Application (OTP Application)
        |
KanbanVisionApi.Usecase.Supervisor (Supervisor, :one_for_one)
        |
        ├── KanbanVisionApi.Usecase.Organization (GenServer)
        │         |
        │   (inicia via init/1)
        │         |
        │   KanbanVisionApi.Agent.Organizations (Agent)
        │         └── estado: %Organizations{id: uuid, organizations: %{id => %Organization{}}}
        │
        └── KanbanVisionApi.Usecase.Simulation (GenServer)
                  |
            (inicia via init/1)
                  |
            KanbanVisionApi.Agent.Simulations (Agent)
                  └── estado: %Simulations{id: uuid, simulations_by_organization: %{org_id => %{sim_id => %Simulation{}}}}
```

**Nota importante:** Os Agents **não são filhos diretos do Supervisor**. Eles são iniciados dentro do `init/1` dos GenServers e dependem deles para existir. Se o GenServer morrer e for reiniciado, um novo Agent é criado do zero.

---

## Resumo do Módulo 3

| Abstração | Uso | API principal |
|-----------|-----|---------------|
| **Process** | Concorrência básica | `spawn`, `send`, `receive` |
| **Agent** | Estado simples, sem lógica | `get`, `update`, `get_and_update` |
| **GenServer** | Estado + lógica + orquestração | `call`, `cast`, `init`, `handle_call`, `handle_cast` |
| **Supervisor** | Tolerância a falhas | `start_link(children, strategy:)` |
| **Application** | Ponto de entrada OTP | `start/2` com filhos do supervisor |

```
call  → síncrono → espera resposta → {:reply, resp, estado}
cast  → assíncrono → não espera → {:noreply, estado}
init  → executado 1x ao iniciar → {:ok, estado_inicial}
```

> **Próximo módulo:** Como testar tudo isso com ExUnit — testes unitários, de integração e por tag.
