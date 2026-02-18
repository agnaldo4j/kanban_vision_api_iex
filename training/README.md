# Workshop: Arquitetura de Software com Elixir
## Duração total: 4 horas e 40 minutos

> Workshop prático usando o projeto **kanban_vision_api_iex** como estudo de caso real.
> Um simulador de Kanban board implementado com Elixir/OTP, que aplica
> Hexagonal Architecture, DDD, SOLID e boas práticas de engenharia.

---

## Agenda

| Horário | Módulo | Tópicos |
|---------|--------|---------|
| 00:00–00:50 | [Módulo 1](./modulo_01_fundamentos_elixir.md) | Fundamentos de Elixir |
| 00:50–01:00 | ☕ Break | |
| 01:00–01:45 | [Módulo 2](./modulo_02_arquitetura.md) | Screaming + Hexagonal + DDD |
| 01:45–02:25 | [Módulo 3b](./modulo_03b_use_cases.md) | **Use Cases — isolamento e importância** |
| 02:25–03:05 | [Módulo 3](./modulo_03_solid.md) | Princípios SOLID |
| 03:05–03:15 | ☕ Break | |
| 03:15–03:50 | [Módulo 4](./modulo_04_side_effects_imutabilidade_cqs.md) | Side Effects, Imutabilidade e CQS |
| 03:50–04:15 | [Módulo 5](./modulo_05_observabilidade.md) | Observabilidade |
| 04:15–04:45 | [Módulo 6](./modulo_06_exercicios.md) | Exercícios Práticos |

---

## Mapa de Conceitos

```
                    ┌───────────────────────────────────┐
                    │       SCREAMING ARCHITECTURE       │
                    │  "A estrutura revela o negócio"   │
                    └───────────────┬───────────────────┘
                                    │
                    ┌───────────────▼───────────────────┐
                    │      HEXAGONAL ARCHITECTURE        │
                    │  Ports & Adapters                  │
                    │  Domínio isolado de infra          │
                    └───────────────┬───────────────────┘
                                    │
               ┌────────────────────▼──────────────────────┐
               │               DDD                         │
               │  Ubiquitous Language • Bounded Contexts   │
               │  Entities • Value Objects • Aggregates    │
               │  Repositories • Domain Events             │
               └────────────────────┬──────────────────────┘
                                    │
          ┌─────────────────────────▼──────────────────────────┐
          │                   USE CASES                        │
          │  Uma operação = um módulo = uma razão para mudar   │
          │  Isolados de HTTP, Ecto, Framework, GenServer      │
          │  Command (escrita) | Query (leitura)               │
          │  Testáveis com mock • Documentação viva do sistema │
          └─────────────────────────┬──────────────────────────┘
                                    │
     ┌──────────────────────────────▼────────────────────────────┐
     │                        SOLID                              │
     │  S: Uma razão para mudar   D: Depender de abstrações     │
     │  O: Aberto para extensão   I: Interfaces focadas          │
     │  L: Substituível           → Behaviours como contratos    │
     └──────────────────────────────┬────────────────────────────┘
                                    │
        ┌───────────────────────────▼───────────────────────────┐
        │          SIDE EFFECTS + IMUTABILIDADE + CQS           │
        │  Funções puras no núcleo • Side effects nas bordas    │
        │  Commands (escrita) vs Queries (leitura)              │
        └───────────────────────────┬───────────────────────────┘
                                    │
                   ┌────────────────▼────────────────┐
                   │         OBSERVABILIDADE          │
                   │  Logger estruturado              │
                   │  Telemetria (:telemetry)         │
                   │  Correlation ID propagado        │
                   └─────────────────────────────────┘
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
    ├── modulo_01_fundamentos_elixir.md
    ├── modulo_02_arquitetura.md
    ├── modulo_03_solid.md
    ├── modulo_04_side_effects_imutabilidade_cqs.md
    ├── modulo_05_observabilidade.md
    └── modulo_06_exercicios.md
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
