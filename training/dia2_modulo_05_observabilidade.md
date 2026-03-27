# Dia 2 — Módulo 5: Observabilidade

> *"Uma feature não está pronta sem comportamento observável em produção."*
> — AGENTS.md deste projeto

Observabilidade é a capacidade de entender o estado interno de um sistema
a partir de suas saídas externas: **logs, métricas e traces**.

---

## 5.1 Os Três Pilares

```
┌──────────────────────────────────────────────────────────────────┐
│                    Observabilidade                               │
│                                                                  │
│  ┌─────────────────┐  ┌────────────────┐  ┌───────────────────┐  │
│  │     LOGS        │  │    MÉTRICAS    │  │     TRACES        │  │
│  │                 │  │                │  │                   │  │
│  │ "O que aconteceu│  │ "Quão bem está │  │ "Qual o caminho   │  │
│  │ e quando?"      │  │ funcionando?"  │  │ da requisição?"   │  │
│  │                 │  │                │  │                   │  │
│  │ Eventos         │  │ Contadores     │  │ Span por serviço  │  │
│  │ Erros           │  │ Latências      │  │ Correlação entre  │  │
│  │ Warnings        │  │ Throughput     │  │ sistemas          │  │
│  └─────────────────┘  └────────────────┘  └───────────────────┘  │
│        Logger              Telemetry          Correlation ID     │
└──────────────────────────────────────────────────────────────────┘
```

### Por que observabilidade "by design"?

```elixir
# Sem observabilidade:
# Bug em produção → "o sistema está falhando" → sem contexto
# "Qual organização? Qual operação? Quando? Por quê?"

# Com observabilidade:
# Bug em produção → filtrar logs por correlation_id
# → ver toda a cadeia de eventos de uma requisição específica
# → identificar exatamente onde e por que falhou
```

---

## 5.2 Structured Logging com Logger

### Configuração do Logger no projeto

```elixir
# config/config.exs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :correlation_id,      # ← identificador único da operação
    :organization_id,     # ← contexto de negócio
    :organization_name,
    :simulation_id,
    :simulation_name,
    :board_id,
    :board_name,
    :tribes_count,
    :count,
    :reason
  ]
```

**Por que metadata estruturada?**

```
# Log NÃO estruturado — difícil de filtrar/pesquisar
[info] Organização Acme criada com id abc123 por usuário user456

# Log estruturado — fácil de filtrar, indexar, agregar
[info] correlation_id=req-789 organization_id=abc123 organization_name=Acme count=1
       [info] Organization created successfully
```

### Padrão de log no Use Case

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/organizations/create_organization.ex

defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganization do
  require Logger

  def execute(%CreateOrganizationCommand{} = cmd, repository_pid, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id, UUID.uuid4())

    # LOG 1: início da operação (info) — "o que vou fazer"
    Logger.info("Creating organization",
      correlation_id: correlation_id,
      organization_name: cmd.name,
      tribes_count: length(cmd.tribes)
    )

    organization = Organization.new(cmd.name, cmd.tribes)

    case repository.add(repository_pid, organization) do
      {:ok, org} ->
        # LOG 2: sucesso (info) — "o que aconteceu"
        Logger.info("Organization created successfully",
          correlation_id: correlation_id,
          organization_id: org.id,
          organization_name: org.name
        )
        {:ok, org}

      {:error, reason} = error ->
        # LOG 3: falha (error) — "o que deu errado e por quê"
        Logger.error("Failed to create organization",
          correlation_id: correlation_id,
          organization_name: cmd.name,
          reason: reason
        )
        error
    end
  end
end
```

### Níveis de log — quando usar cada um

```elixir
# :debug — desenvolvimento/diagnóstico (desabilitado em prod)
Logger.debug("Query params", params: inspect(params))

# :info — eventos normais de negócio
Logger.info("Organization created successfully", organization_id: org.id)
Logger.info("Simulation started", simulation_id: sim.id)

# :warning — algo inesperado mas tolerável
Logger.warning("Organization not found, using default", organization_id: id)

# :error — falhas que precisam atenção
Logger.error("Failed to create organization", reason: reason, correlation_id: cid)
```

### O Correlation ID — rastreando uma operação completa

```elixir
# O correlation_id é gerado na borda (adapter HTTP, CLI, etc.)
# e propagado por toda a cadeia de chamadas

# Adapter HTTP recebe request → gera correlation_id
correlation_id = get_req_header(conn, "x-correlation-id") ||
                 UUID.uuid4()

# Passa para o GenServer
Organization.add(pid, cmd, correlation_id: correlation_id)

# GenServer enriquece e passa para o Use Case
def handle_call({:add, cmd, opts}, _from, state) do
  enriched_opts = Keyword.put(opts, :correlation_id,
    Keyword.get(opts, :correlation_id, UUID.uuid4()))
  result = CreateOrganization.execute(cmd, state.repository_pid, enriched_opts)
  {:reply, result, state}
end

# Use Case loga com o correlation_id
Logger.info("Creating organization",
  correlation_id: correlation_id,   # ← mesmo ID em todo o fluxo
  organization_name: cmd.name
)
```

**Resultado:** Filtrando logs por `correlation_id=req-789`, você vê **toda a jornada** de uma operação específica, de ponta a ponta.

---

## 5.3 Telemetria com :telemetry

Telemetria é para **métricas e instrumentação**, não logs. É a base para dashboards, alertas e SLOs.

### EventEmitter — abstração de telemetria

```elixir
# apps/usecase/lib/kanban_vision_api/usecase/event_emitter.ex

defmodule KanbanVisionApi.Usecase.EventEmitter do
  @moduledoc """
  Emite eventos de telemetria para instrumentação de métricas.

  Naming convention: [:kanban_vision_api, context, event_type]

  Exemplos:
  - [:kanban_vision_api, :organization, :organization_created]
  - [:kanban_vision_api, :simulation, :simulation_deleted]
  - [:kanban_vision_api, :board, :board_not_found]
  """

  @spec emit(atom(), atom(), map(), String.t()) :: :ok
  def emit(context, event_type, metadata, correlation_id) do
    :telemetry.execute(
      [:kanban_vision_api, context, event_type],
      %{count: 1},                               # measurement (para contadores)
      Map.put(metadata, :correlation_id, correlation_id)
    )
  end
end
```

### Uso nos Use Cases

```elixir
# Em create_organization.ex — emite evento de sucesso
EventEmitter.emit(
  :organization,
  :organization_created,
  %{organization_id: org.id, organization_name: org.name},
  correlation_id
)
# ↓ emite [:kanban_vision_api, :organization, :organization_created]

# Em delete_organization.ex — emite evento de remoção
EventEmitter.emit(
  :organization,
  :organization_deleted,
  %{organization_id: cmd.id},
  correlation_id
)
# ↓ emite [:kanban_vision_api, :organization, :organization_deleted]
```

### Consumindo eventos de telemetria

```elixir
# Handler de métricas (exemplo de como seria integrado com Prometheus/StatsD)
defmodule KanbanVisionApi.Metrics.Handler do
  def setup do
    :telemetry.attach_many(
      "kanban-metrics",
      [
        [:kanban_vision_api, :organization, :organization_created],
        [:kanban_vision_api, :organization, :organization_deleted],
        [:kanban_vision_api, :simulation, :simulation_created],
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:kanban_vision_api, :organization, :organization_created], measurements, metadata, _config) do
    # Incrementa contador no Prometheus
    :prometheus_counter.inc(:organizations_created_total, [])

    # Registra em StatsD
    :statsd.increment("kanban.organizations.created")

    # Log estruturado para auditoria
    Logger.info("AUDIT: Organization created",
      organization_id: metadata.organization_id,
      correlation_id: metadata.correlation_id
    )
  end
end
```

### Telemetria vs Log — quando usar cada um

| | Log (Logger) | Telemetria (:telemetry) |
|--|-------------|------------------------|
| **Propósito** | Diagnóstico / debug | Métricas / alertas |
| **Volume** | Alto (verboso) | Baixo (contadores, durations) |
| **Consumidor** | Desenvolvedor | Dashboard / PagerDuty |
| **Retenção** | Dias/semanas | Meses/anos |
| **Custo** | I/O por linha | Aggregável em memória |

---

## 5.4 O que Observar — Business Events

Além de logs técnicos, meça o que importa para o **negócio**:

### Eventos de negócio que o projeto já emite

```elixir
# Criação de entidades
[:kanban_vision_api, :organization, :organization_created]
[:kanban_vision_api, :simulation, :simulation_created]

# Remoção de entidades
[:kanban_vision_api, :organization, :organization_deleted]
[:kanban_vision_api, :simulation, :simulation_deleted]
```

### Eventos que poderiam ser adicionados

```elixir
# Uso / adoção
[:kanban_vision_api, :board, :board_workflow_started]
[:kanban_vision_api, :task, :task_moved_to_step]
[:kanban_vision_api, :simulation, :simulation_completed]

# Erros de negócio
[:kanban_vision_api, :organization, :organization_not_found]
[:kanban_vision_api, :organization, :organization_duplicate_name]

# Performance
[:kanban_vision_api, :simulation, :simulation_step_duration]
```

### Checklist de observabilidade para novos Use Cases

Antes de dar uma feature como "pronta", verificar:

```
✓ Logger.info no início da operação (com correlation_id)
✓ Logger.info no sucesso (com IDs dos recursos criados/modificados)
✓ Logger.error na falha (com reason)
✓ EventEmitter.emit no sucesso (evento de domínio)
✓ EventEmitter.emit na falha crítica (para alertas)
✓ correlation_id propagado em todas as chamadas
✓ Nenhum dado sensível (PII) nos logs
```

---

## 5.5 Trace Distribuído — O Correlation ID como Trace Manual (Bônus)

```elixir
# Em sistemas distribuídos, o correlation_id é o trace ID manual
# É propagado via headers HTTP, mensagens de evento, etc.

# Request entra no sistema
POST /organizations
X-Correlation-ID: req-abc123-def456

# GenServer recebe e propaga
handle_call({:add, cmd, [correlation_id: "req-abc123-def456"]}, ...)

# Use Case loga com o ID
Logger.info("Creating organization", correlation_id: "req-abc123-def456", ...)

# Evento de telemetria carrega o ID
EventEmitter.emit(:organization, :created, %{...}, "req-abc123-def456")

# Todos os logs podem ser filtrados por esse ID:
# grep "req-abc123-def456" production.log
# → ver toda a cadeia de eventos da requisição

# Em ferramentas como Datadog, Jaeger, Honeycomb:
# → visualização automática do trace completo
```

---

## Resumo do Módulo 5

```
┌──────────────────────────────────────────────────────────────┐
│             Observabilidade no Projeto                       │
│                                                              │
│  Logger ────────────► config/config.exs                      │
│    ├── metadata: correlation_id, organization_id, ...        │
│    ├── info: início e fim de operações                       │
│    └── error: falhas com reason                              │
│                                                              │
│  EventEmitter ──────► :telemetry.execute/3                   │
│    ├── event: [:kanban_vision_api, context, event_type]      │
│    ├── measurement: %{count: 1}                              │
│    └── metadata: {resource_ids, correlation_id}              │
│                                                              │
│  Correlation ID ────► propagado por toda a cadeia            │
│    ├── gerado na borda (HTTP adapter, CLI)                   │
│    └── passado via opts a cada chamada                       │
└──────────────────────────────────────────────────────────────┘
```

| Pilar | Ferramenta | Responde |
|-------|-----------|----------|
| **Logs** | `Logger` + metadata | "O que aconteceu?" |
| **Métricas** | `:telemetry` + EventEmitter | "Quão frequente/rápido?" |
| **Traces** | `correlation_id` propagado | "Qual o caminho?" |

> **Próximo módulo:** Exercícios práticos para fixar todos os conceitos.
