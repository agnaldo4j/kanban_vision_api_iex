# Dia 2 — Módulo 4: Side Effects, Imutabilidade e Command/Query Separation

> Três conceitos que trabalham juntos para tornar código previsível,
> testável e fácil de raciocinar.

---

## 4.1 O que são Side Effects? (8 min)

Um **side effect** é qualquer mudança observável no mundo exterior causada pela execução de uma função:

```
Side effects incluem:
├── Escrita em banco de dados
├── Chamadas HTTP externas
├── Escrita em arquivo
├── Envio de email/SMS
├── Log em console
├── Mutação de estado global
├── Emissão de eventos/telemetria
└── Geração de números aleatórios / UUIDs
```

### Funções puras vs impuras

```elixir
# PURA — mesmo input, sempre mesmo output, sem side effects
def calcular_area(largura, altura) do
  largura * altura
end

calcular_area(3, 4)  #=> 12  (sempre, em qualquer momento)
calcular_area(3, 4)  #=> 12  (idêntico)

# IMPURA — side effect: mutação de estado externo
def criar_organizacao(nome) do
  org = Organization.new(nome)  # gera UUID aleatório — side effect!
  Agent.update(:orgs, fn s -> Map.put(s, org.id, org) end)  # side effect: estado externo
  Logger.info("Criada: #{nome}")  # side effect: I/O
  {:ok, org}
end
```

### Por que side effects são problemáticos?

```elixir
# Difícil de testar — precisa de estado real
test "criar organização" do
  # Precisa de Agent rodando, Logger configurado, etc.
  criar_organizacao("Acme")
end

# Difícil de paralelizar — side effects em estado compartilhado causam races
# Processo A e B chamam ao mesmo tempo → undefined behavior

# Difícil de entender — efeitos ocultos nas entranhas da função
```

---

## 4.2 Controle de Side Effects — Push para a Borda (12 min)

O padrão fundamental: **manter o domínio puro, confinar side effects nas bordas do sistema**.

```
┌──────────────────────────────────────────────────────────┐
│                     Borda do Sistema                     │
│  (side effects permitidos: I/O, DB, HTTP, Events, Log)   │
│                                                          │
│  Adapter HTTP ──► [BORDA]                                │
│  GenServer    ──► [BORDA]                                │
│  Use Case     ──► [BORDA] → Log + Event emission         │
│  Repository   ──► [BORDA] → Persistência                 │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │               Núcleo Puro                        │    │
│  │  (zero side effects — apenas transformações)     │    │
│  │                                                  │    │
│  │  Organization.new(name)  → struct imutável       │    │
│  │  Board.new(name, sim_id) → struct imutável       │    │
│  │  Workflow.add_step(wf, step) → novo workflow     │    │
│  └──────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### O domínio é puro

```elixir
# apps/kanban_domain/lib/kanban_vision_api/domain/organization.ex
# PURO — sem I/O, sem banco, sem log, sem eventos

defmodule KanbanVisionApi.Domain.Organization do
  defstruct [:id, :audit, :name, :tribes]

  # UUID.uuid4() é um side effect (randomness), mas é isolado na factory
  # O struct resultante é imutável e puro
  def new(name, tribes \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{id: id, audit: audit, name: name, tribes: tribes}
  end
end

# Testável sem qualquer infrastructure
test "cria organization" do
  org = Organization.new("Acme")      # sem Agent, sem DB, sem HTTP
  assert org.name == "Acme"           # rápido, determinístico, isolado
end
```

### O Use Case confina os side effects

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organizations/create_organization.ex
# BORDA — side effects acontecem aqui, de forma explícita e controlada

defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  require Logger

  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())
    repository = Keyword.get(opts, :repository, @default_repository)

    # 1. PURO — criação da entidade (sem side effect)
    organization = Organization.new(cmd.name, cmd.tribes)

    # 2. SIDE EFFECT — persistência
    case repository.add(repository_pid, organization) do
      {:ok, org} ->
        # 3. SIDE EFFECT — log (explícito)
        Logger.info("Organization created successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )

        # 4. SIDE EFFECT — evento de telemetria (explícito)
        EventEmitter.emit(
          :organization,
          :organization_created,
          %{organization_id: org.id, organization_name: org.name},
          correlation_id
        )

        {:ok, org}

      {:error, reason} = error ->
        # 5. SIDE EFFECT — log de erro (explícito)
        Logger.error("Failed to create organization",
          correlation_id: correlation_id,
          reason: reason
        )
        error
    end
  end
end
```

**Padrão observado:**
- Lógica de negócio (criação de entidade) — sem side effects
- I/O (log, evento, persistência) — explícito, nomeado, na borda
- Side effects declarados claramente, não escondidos dentro de loops ou funções auxiliares

### Separando lógica pura de side effects em código mais complexo

```elixir
# RUIM — side effects misturados com lógica
def process_boards(boards) do
  Enum.each(boards, fn board ->
    Logger.info("Processando #{board.name}")           # side effect no meio
    valid = validate_board(board)
    if valid do
      Repo.save(board)                                  # side effect no meio
      send_event(:board_processed, board)              # side effect no meio
    end
  end)
end

# BOM — separação clara: primeiro calcular, depois executar side effects
def process_boards(boards) do
  # 1. Fase pura — calcular o que precisa ser feito
  {valid_boards, invalid_boards} =
    Enum.split_with(boards, &validate_board/1)

  # 2. Fase de side effects — executar as mudanças
  Enum.each(valid_boards, &Repository.save/1)
  Enum.each(valid_boards, &EventEmitter.emit(:board_processed, &1))
  Enum.each(invalid_boards, &Logger.warning("Board inválido: #{&1.name}"))

  {:ok, length(valid_boards), length(invalid_boards)}
end
```

---

## 4.3 Imutabilidade em Fluxos Complexos (7 min)

Elixir garante imutabilidade, mas é preciso saber usá-la bem em transformações encadeadas.

### Transformações funcionais — pipeline de dados

```elixir
# Cenário: processar boards de uma simulação

# RUIM — estado mutável via variável reatribuída
def summarize_simulation(simulation) do
  result = %{}
  result = Map.put(result, :name, simulation.name)

  boards = simulation.board
  result = Map.put(result, :board_count, length(boards))

  active = Enum.filter(boards, & &1.active)
  result = Map.put(result, :active_count, length(active))

  result
end

# BOM — pipeline imutável de transformações
def summarize_simulation(simulation) do
  %{
    name:         simulation.name,
    board_count:  count_boards(simulation),
    active_count: count_active_boards(simulation),
    step_count:   count_steps(simulation)
  }
end

defp count_boards(%Simulation{board: board}), do: if(board, do: 1, else: 0)

defp count_active_boards(%Simulation{board: nil}), do: 0
defp count_active_boards(%Simulation{board: board}) do
  board.workflow
  |> then(& &1.steps)
  |> Enum.count(& &1.tasks != [])
end
```

### Atualização de estruturas aninhadas — Map/put_in

```elixir
# Estrutura aninhada
simulation = %Simulation{
  board: %Board{
    workflow: %Workflow{
      steps: [%Step{name: "In Progress", tasks: []}]
    }
  }
}

# Adicionando uma task em um step específico (sem mutar!)
nova_task = Task.new(:high)

novo_simulation =
  update_in(simulation, [:board, :workflow, :steps], fn steps ->
    Enum.map(steps, fn step ->
      if step.name == "In Progress" do
        %{step | tasks: [nova_task | step.tasks]}
      else
        step
      end
    end)
  end)

# simulation original não foi alterado
simulation.board.workflow.steps |> hd() |> Map.get(:tasks)  #=> []
novo_simulation.board.workflow.steps |> hd() |> Map.get(:tasks)  #=> [nova_task]
```

### Por que imutabilidade importa para concorrência

```elixir
# Cenário: dois processos acessam a mesma simulation

# Em linguagem mutável:
# Processo A: lê simulation → tasks = [task1]
# Processo B: adiciona task2 → tasks = [task1, task2]
# Processo A: ainda com referência velha → tasks = [task1] → inconsistência!

# Em Elixir (imutável):
# Processo A: lê simulation → recebe CÓPIA com tasks = [task1]
# Processo B: recebe nova simulation com tasks = [task1, task2]
# Processo A: ainda válido com sua cópia → consistente por design!

# O estado compartilhado fica no Agent, com acesso serializado
# Cada processo trabalha com sua própria cópia imutável
```

---

## 4.4 Command and Query Separation (CQS) (8 min)

> *"Um método deve ser um comando que realiza uma ação, OU uma query que retorna dados — nunca os dois ao mesmo tempo."*
> — Bertrand Meyer

### O problema sem CQS

```elixir
# RUIM — função que muda estado E retorna dados ao mesmo tempo
def add_and_get_all(pid, organization) do
  Agent.get_and_update(pid, fn state ->
    new_state = Map.put(state, organization.id, organization)
    {new_state, new_state}  # retorna o estado novo E muda o estado — confuso!
  end)
end

# O caller não sabe se houve efeito colateral apenas lendo a assinatura
# Testar é mais complexo — um test cobre duas responsabilidades
```

### Commands vs Queries no projeto

**Commands — mudam estado, não retornam dados de negócio (só confirmação)**

```elixir
# Command: cria uma organização — MUDA estado
# Input: CreateOrganizationCommand (o que fazer)
# Output: {:ok, Organization} OU {:error, reason} — confirmação, não consulta

defmodule CreateOrganizationCommand do
  @enforce_keys [:name]
  defstruct [:name, tribes: []]

  @spec new(String.t(), list()) :: {:ok, t()} | {:error, atom()}
  def new(name, tribes \\ []) when is_binary(name) and byte_size(name) > 0 do
    {:ok, %__MODULE__{name: name, tribes: tribes}}
  end
  def new(_, _), do: {:error, :invalid_name}
end

# Execução do Command — muda estado
defmodule CreateOrganization do
  def execute(%CreateOrganizationCommand{} = cmd, pid, opts \\ []) do
    organization = Organization.new(cmd.name, cmd.tribes)
    repository.add(pid, organization)
    # Retorna confirmação {:ok, org} — não faz consulta adicional
  end
end
```

**Queries — apenas leem estado, nunca mudam**

```elixir
# Query: busca organização por ID — APENAS LÊ estado
# Input: GetOrganizationByIdQuery (o que consultar)
# Output: {:ok, Organization} OU {:error, reason} — dados consultados

defmodule GetOrganizationByIdQuery do
  @enforce_keys [:id]
  defstruct [:id]

  @spec new(String.t()) :: {:ok, t()} | {:error, atom()}
  def new(id) when is_binary(id) and byte_size(id) > 0 do
    {:ok, %__MODULE__{id: id}}
  end
  def new(_), do: {:error, :invalid_id}
end

# Execução da Query — apenas lê
defmodule GetOrganizationById do
  def execute(%GetOrganizationByIdQuery{} = query, pid, opts \\ []) do
    repository.get_by_id(pid, query.id)
    # Apenas retorna dados — zero efeito colateral
  end
end
```

### CQS no GenServer — API separada

```elixir
defmodule KanbanVisionApi.Usecase.Organization do
  use GenServer

  # ===== QUERIES — apenas leitura =====
  def get_all(pid, opts \\ []) do
    GenServer.call(pid, {:get_all, opts})
  end

  def get_by_id(pid, %GetOrganizationByIdQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_id, query, opts})
  end

  def get_by_name(pid, %GetOrganizationByNameQuery{} = query, opts \\ []) do
    GenServer.call(pid, {:get_by_name, query, opts})
  end

  # ===== COMMANDS — mudam estado =====
  def add(pid, %CreateOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:add, cmd, opts})
  end

  def delete(pid, %DeleteOrganizationCommand{} = cmd, opts \\ []) do
    GenServer.call(pid, {:delete, cmd, opts})
  end
end
```

### CQS no repositório — separação clara

```elixir
defmodule KanbanVisionApi.Agent.Organizations do

  # ===== QUERIES — Agent.get (apenas leitura, não bloqueia outras leituras) =====

  def get_all(pid) do
    Agent.get(pid, fn state -> state.organizations end)
    # Apenas lê — sem side effect, múltiplos processos podem ler simultaneamente
  end

  def get_by_id(pid, id) do
    Agent.get(pid, fn state ->
      case Map.get(state.organizations, id) do
        nil  -> {:error, "not found"}
        org  -> {:ok, org}
      end
    end)
    # Apenas lê — sem efeito no estado
  end

  # ===== COMMANDS — Agent.get_and_update (lê e escreve atomicamente) =====

  def add(pid, %Organization{} = org) do
    Agent.get_and_update(pid, fn state ->
      # Lê estado, decide se adiciona, retorna novo estado
      new_orgs = Map.put(state.organizations, org.id, org)
      {{:ok, org}, %{state | organizations: new_orgs}}
    end)
    # Muda estado — operação atômica
  end

  def delete(pid, id) do
    Agent.get_and_update(pid, fn state ->
      case Map.get(state.organizations, id) do
        nil -> {{:error, "not found"}, state}
        org ->
          new_orgs = Map.delete(state.organizations, org.id)
          {{:ok, org}, %{state | organizations: new_orgs}}
      end
    end)
    # Muda estado — operação atômica
  end
end
```

### Benefícios de CQS

```
1. LEITURA PARALELA — Queries podem executar em paralelo (sem estado mutado)
2. CACHE — Queries são cacheáveis; Commands invalidam cache
3. AUDIT TRAIL — Commands ficam em event log; Queries são voláteis
4. TESTES — Commands testam side effects; Queries testam dados retornados
5. OTIMIZAÇÃO — Read path pode ter implementação diferente do write path (CQRS)
```

---

## 4.5 CQRS — Command Query Responsibility Segregation (2 min)

CQS em nível de **sistema inteiro** (não apenas função):

```
┌─────────────────────────────────────────────────────────────────┐
│                         CQRS Completo                           │
│                                                                 │
│  Client ──► Command ──► Use Case ──► Write Store (Agent/DB)     │
│                │                         │                      │
│                │                     Event Published            │
│                │                         │                      │
│                │                         ▼                      │
│                │                    Read Store (projeção)       │
│                │                         │                      │
│  Client ──► Query ──────────────────────►┘                      │
└─────────────────────────────────────────────────────────────────┘

Write side: consistente, autoritativo, normalizado
Read side:  otimizado para queries específicas (denormalizado, cacheado)
```

O projeto atual usa CQS (nível de função/módulo). CQRS completo seria o próximo passo ao escalar.

---

## Resumo do Módulo 4

| Conceito | Regra | Exemplo no projeto |
|----------|-------|-------------------|
| **Side Effects** | Confinar nas bordas, tornar explícitos | Log e EventEmitter apenas no Use Case |
| **Funções Puras** | Domain = sem I/O, sem estado global | `Organization.new()` é pura |
| **Imutabilidade** | Transformar, nunca mutar | `%{org \| name: novo}` retorna novo struct |
| **CQS — Command** | Muda estado, retorna confirmação | `CreateOrganizationCommand` + `CreateOrganization` |
| **CQS — Query** | Lê estado, sem side effects | `GetOrganizationByIdQuery` + `GetOrganizationById` |

> **Próximo módulo:** Como observar o que acontece em produção sem perder informação crítica.
