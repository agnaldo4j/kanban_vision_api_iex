# Workshop: Arquitetura de Software com Elixir

> Workshop prático usando o projeto **kanban_vision_api_iex** como estudo de caso real.
> Um simulador de Kanban board implementado com Elixir/OTP, que aplica
> Hexagonal Architecture, DDD, SOLID e boas práticas de engenharia.
>
> Público-alvo: iniciantes em Elixir **e** em arquitetura de software.

---

## Dia 1 — Fundamentos da Linguagem

1. [Módulo 1 — Mix](./dia1_modulo_01_mix.md) — Criação de projetos umbrella, mix.exs, dependências, comandos
2. [Módulo 2 — Elixir](./dia1_modulo_02_elixir.md) — Tipos, pattern matching, guards, with, structs, @type, imutabilidade
3. [Módulo 3 — OTP](./dia1_modulo_03_otp.md) — Processos, Agent, GenServer, Supervisor
4. [Módulo 4 — Testes](./dia1_modulo_04_testes.md) — ExUnit, describe/test/setup, tags, três níveis de teste
5. [Módulo 5 — Exercícios Dia 1](./dia1_modulo_05_exercicios.md) — IEx, criar entidades, Agent, GenServer, escrever testes

---

## Dia 2 — Arquitetura de Software

1. [Módulo 1 — Arquitetura](./dia2_modulo_01_arquitetura.md) — Screaming Architecture, Hexagonal (Ports & Adapters), DDD
2. [Módulo 2 — SOLID](./dia2_modulo_02_solid.md) — SRP, OCP, LSP, ISP, DIP aplicados em Elixir
3. [Módulo 3 — Use Cases](./dia2_modulo_03_use_cases.md) — Isolamento, estrutura, testes, anti-padrões
4. [Módulo 4 — Side Effects e CQS](./dia2_modulo_04_side_effects_cqs.md) — Funções puras, imutabilidade em fluxos, Commands vs Queries
5. [Módulo 5 — Observabilidade](./dia2_modulo_05_observabilidade.md) — Logger estruturado, :telemetry, Correlation ID
6. [Módulo 6 — Exercícios Dia 2](./dia2_modulo_06_exercicios.md) — Exercícios de arquitetura no projeto real

---

## Dia 3 — Camada Web

1. [Módulo 1 — Web API](./dia3_modulo_01_web_api.md) — Bandit, Plug, Router, Plugs customizados, Controllers, Serializers, OpenAPI

---

## Mapa de Conceitos

```
┌─────────────────────────────────────────────────────────────────┐
│                         DIA 1                                   │
│                                                                 │
│  Mix ──→ Elixir ──→ OTP (Agent / GenServer / Supervisor)        │
│                         │                                       │
│                         ▼                                       │
│                     ExUnit (testes)                             │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DIA 2                                   │
│                                                                 │
│  SCREAMING ARCHITECTURE                                         │
│  "A estrutura revela o negócio"                                 │
│            │                                                    │
│            ▼                                                    │
│  HEXAGONAL ARCHITECTURE (Ports & Adapters)                      │
│  Domínio isolado de infra                                       │
│            │                                                    │
│            ▼                                                    │
│  DDD — Ubiquitous Language · Bounded Contexts                   │
│  Entities · Value Objects · Repositories · Domain Events        │
│            │                                                    │
│            ▼                                                    │
│  SOLID — Behaviours como contratos · Injeção de dependência     │
│            │                                                    │
│            ▼                                                    │
│  USE CASES — Uma operação = um módulo = uma razão para mudar    │
│  Isolados de HTTP, Ecto, Framework · Command | Query            │
│            │                                                    │
│            ▼                                                    │
│  SIDE EFFECTS + IMUTABILIDADE + CQS                             │
│  Funções puras no núcleo · Side effects nas bordas              │
│            │                                                    │
│            ▼                                                    │
│  OBSERVABILIDADE                                                │
│  Logger estruturado · :telemetry · Correlation ID               │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         DIA 3                                   │
│                                                                 │
│  CAMADA WEB (Plug + Bandit)                                     │
│  HTTP sem Phoenix — composição explícita de plugs              │
│            │                                                    │
│            ▼                                                    │
│  PLUG PIPELINE                                                  │
│  CorrelationId · RequestLogger · Parsers · Router               │
│            │                                                    │
│            ▼                                                    │
│  CONTROLLERS como ADAPTERS HTTP                                 │
│  HTTP → Command/Query → Port → JSON                             │
│            │                                                    │
│            ▼                                                    │
│  PORTS + ADAPTERS na camada web                                 │
│  Mox para testes de controller isolados do GenServer            │
│            │                                                    │
│            ▼                                                    │
│  OPENAPI — documentação como código                             │
│  open_api_spex · /api/openapi · /api/swagger                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Estrutura do Projeto (Referência)

```
kanban_vision_api_iex/            ← umbrella project
├── apps/
│   ├── kanban_domain/            ← domínio puro (zero infra)
│   │   └── lib/kanban_vision_api/domain/
│   │       ├── organization.ex   ← Aggregate Root
│   │       ├── tribe.ex          ← Entidade filha
│   │       ├── squad.ex
│   │       ├── worker.ex
│   │       ├── ability.ex        ← Value Object
│   │       ├── simulation.ex     ← Aggregate Root
│   │       ├── board.ex
│   │       ├── workflow.ex
│   │       ├── step.ex
│   │       ├── task.ex
│   │       ├── service_class.ex  ← Value Object
│   │       ├── audit.ex          ← Value Object (timestamps)
│   │       └── ports/            ← PORT interfaces (behaviours)
│   │           ├── organization_repository.ex
│   │           ├── simulation_repository.ex
│   │           └── board_repository.ex
│   │
│   ├── persistence/              ← adapters de persistência
│   │   └── lib/kanban_vision_api/agent/
│   │       ├── organizations.ex  ← ADAPTER: OrganizationRepository (Agent)
│   │       ├── simulations.ex    ← ADAPTER: SimulationRepository (Agent)
│   │       └── boards.ex         ← ADAPTER: BoardRepository (Agent)
│   │
│   └── usecase/                  ← casos de uso + orquestradores
│       └── lib/kanban_vision_api/usecase/
│           ├── application.ex    ← OTP Application + Supervisor
│           ├── event_emitter.ex  ← telemetria centralizada
│           ├── organization.ex   ← GenServer (orquestrador)
│           ├── organization/
│           │   ├── commands.ex   ← CreateOrganizationCommand, DeleteOrganizationCommand
│           │   └── queries.ex    ← GetOrganizationByIdQuery, GetOrganizationByNameQuery
│           └── organizations/    ← Use Cases (um por operação)
│               ├── create_organization.ex
│               ├── delete_organization.ex
│               ├── get_organization_by_id.ex
│               ├── get_organization_by_name.ex
│               └── get_all_organizations.ex
└── training/                     ← este workshop
    ├── README.md                 ← este arquivo
    ├── dia1_modulo_01_mix.md
    ├── dia1_modulo_02_elixir.md
    ├── dia1_modulo_03_otp.md
    ├── dia1_modulo_04_testes.md
    ├── dia1_modulo_05_exercicios.md
    ├── dia2_modulo_01_arquitetura.md
    ├── dia2_modulo_02_solid.md
    ├── dia2_modulo_03_use_cases.md
    ├── dia2_modulo_04_side_effects_cqs.md
    ├── dia2_modulo_05_observabilidade.md
    └── dia2_modulo_06_exercicios.md
```

---

## Fluxo de Dados

```
Client (HTTP/CLI/IEx)
         │
         ▼ Command ou Query
   ┌─────────────┐
   │  GenServer  │  ← orquestra, não decide
   │ Organization│
   └──────┬──────┘
          │ delega para
          ▼
   ┌─────────────────────┐
   │     Use Case        │  ← aqui está a lógica de negócio
   │ CreateOrganization  │  ← Logger + EventEmitter aqui
   └──────────┬──────────┘
              │ usa PORT (behaviour)
              ▼
   ┌─────────────────────┐
   │  Port (interface)   │  ← OrganizationRepository behaviour
   └──────────┬──────────┘
              │ implementado por
              ▼
   ┌─────────────────────┐
   │  Adapter (Agent)    │  ← estado em memória via OTP Agent
   │  Organizations      │  ← Agent.get_and_update (atômico)
   └─────────────────────┘
```

---

## Comandos Úteis

```bash
# Testes
mix test                                          # todos os testes
mix test --app kanban_domain                      # apenas o domínio
mix test --only domain_organizations              # por tag
mix test --only integration                       # testes de integração

# Qualidade
mix credo                                         # análise estática
mix format --check-formatted                      # verificar formatação

# Cobertura
MIX_ENV=test mix coveralls --umbrella             # cobertura completa

# IEx
iex -S mix                                        # shell com projeto carregado
```

---

## Pré-requisitos do Workshop

- Elixir 1.18.4 instalado (`elixir --version`)
- Erlang/OTP 28 instalado
- Editor com suporte a Elixir (VS Code + ElixirLS, IntelliJ + Elixir plugin)
- Git configurado

```bash
# Verificar instalação
elixir --version
erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
mix --version
```
