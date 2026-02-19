# Dia 1 — Módulo 1: Mix e Estrutura de Projetos
## Duração: 40 minutos

> **Projeto de referência:** `kanban_vision_api_iex` — um simulador de Kanban board
> usando OTP e o padrão Object Prevalence (estado em memória via Agents).

---

## 1.1 Por que Elixir? (3 min)

Elixir roda sobre a **BEAM** (máquina virtual do Erlang), projetada para sistemas distribuídos e tolerantes a falhas:

```
┌─────────────────────────────────────────┐
│              Elixir (sintaxe)           │
├─────────────────────────────────────────┤
│       BEAM VM (máquina virtual)         │
├─────────────────────────────────────────┤
│    Erlang OTP (bibliotecas/runtime)     │
└─────────────────────────────────────────┘
```

| Característica | O que significa na prática |
|---------------|--------------------------|
| Processos leves | Milhões de processos simultâneos sem threads do SO |
| Imutabilidade | Sem race conditions nos dados — thread-safe por padrão |
| Supervisão | Processos morrem e reiniciam automaticamente |
| Pattern matching | Controle de fluxo expressivo, sem null checks |

---

## 1.2 Mix — A ferramenta de build do Elixir (20 min)

**Mix** é o equivalente ao npm/Maven/Gradle do Elixir. Ele gerencia projetos, dependências, compilação, testes e tarefas customizadas.

### 1.2.1 — Criando projetos

```bash
# Projeto simples (sem supervisor OTP)
mix new my_app

# Projeto com supervisor OTP (recomendado para serviços)
mix new my_app --sup

# Projeto umbrella (múltiplos apps — o padrão deste workshop)
mix new my_system --umbrella
```

**Quando usar cada um:**

| Tipo | Use quando |
|------|-----------|
| `mix new` | Biblioteca, script, módulo utilitário |
| `mix new --sup` | Serviço único com estado (GenServer, Agent) |
| `mix new --umbrella` | Sistema com múltiplos bounded contexts independentes |

### 1.2.2 — Estrutura gerada por tipo

#### Projeto simples (`mix new my_app`)
```
my_app/
├── lib/
│   └── my_app.ex          ← módulo principal
├── test/
│   ├── test_helper.exs    ← configura ExUnit
│   └── my_app_test.exs    ← testes
├── .formatter.exs         ← regras de formatação
├── .gitignore
└── mix.exs                ← definição do projeto
```

#### Projeto com Supervisor (`mix new my_app --sup`)
```
my_app/
├── lib/
│   ├── my_app.ex
│   └── my_app/
│       └── application.ex  ← OTP Application + Supervisor ← NOVO
├── test/
└── mix.exs
```

#### Projeto Umbrella (`mix new my_system --umbrella`)
```
my_system/
├── apps/                  ← cada app vive aqui ← NOVO
├── config/
│   └── config.exs         ← configuração compartilhada por todos os apps
└── mix.exs                ← apenas version + deps compartilhadas
```

Após criar o umbrella, cada app filho é criado dentro de `apps/`:
```bash
cd my_system/apps
mix new kanban_domain           # domínio puro
mix new persistence             # adapters de persistência
mix new usecase --sup           # casos de uso com Supervisor
```

### 1.2.3 — O projeto deste workshop foi criado assim

```bash
# Passo 1: criar o umbrella
mix new kanban_vision_api_iex --umbrella

# Passo 2: criar cada app dentro do umbrella
cd kanban_vision_api_iex/apps
mix new kanban_domain                    # domínio puro — sem --sup
mix new persistence                      # adapters — sem --sup
mix new usecase --sup                    # application layer — com --sup
```

**Por que `kanban_domain` e `persistence` sem `--sup`?**

```
kanban_domain — apenas módulos com funções puras.
               Não sobe processos OTP. Sem Application callback.
               Depende só de elixir_uuid para gerar UUIDs.

persistence   — os Agents são iniciados e supervisionados pelos GenServers
               de usecase. Persistence não gerencia seu próprio lifecycle.

usecase       — tem --sup porque contém os GenServers (Organization,
               Simulation) que precisam do Application + Supervisor.
```

### 1.2.4 — Anatomia do `mix.exs`

#### O mix.exs raiz do umbrella

```elixir
# kanban_vision_api_iex/mix.exs
defmodule KanbanVisionApiIex.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",               # ← define que é umbrella; onde ficam os apps
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Deps aqui são disponíveis para TODOS os apps do umbrella
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},   # linter
      {:excoveralls, "~> 0.18", only: :test, runtime: false},    # cobertura
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}  # watch mode
    ]
  end
end
```

#### O mix.exs de `kanban_domain` (domínio puro)

```elixir
# apps/kanban_domain/mix.exs
defmodule Domain.MixProject do
  use Mix.Project

  def project do
    [
      app: :kanban_domain,
      version: "0.1.0",
      # Paths apontam para a raiz do umbrella — deps e build compartilhados
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path:   "../../deps",
      lockfile:    "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
      # Sem `mod:` — não tem OTP Application, não sobe processos
    ]
  end

  defp deps do
    [
      {:elixir_uuid, "~> 1.2.1"}
      # Único dep externo — apenas para gerar UUIDs
      # Sem Ecto, sem HTTP, sem banco — domínio 100% puro
    ]
  end
end
```

#### O mix.exs de `persistence` (adapters)

```elixir
# apps/persistence/mix.exs
defmodule Persistence.MixProject do
  use Mix.Project

  def project do
    [app: :persistence, ...]
  end

  def application do
    [extra_applications: [:logger]]
    # Sem `mod:` — não tem Application próprio
    # Agents são gerenciados pelos GenServers de usecase
  end

  defp deps do
    [
      {:kanban_domain, in_umbrella: true}
      # ↑ in_umbrella: true — referencia app irmão dentro do umbrella
      # Sem Ecto — usa apenas Agents in-memory
    ]
  end
end
```

#### O mix.exs de `usecase` (application layer)

```elixir
# apps/usecase/mix.exs
defmodule Usecase.MixProject do
  use Mix.Project

  def project do
    [app: :usecase, ...]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {KanbanVisionApi.Usecase.Application, []}
      # ↑ mod: define o módulo OTP Application — ponto de entrada do sistema
      #   Único app com Application — é ele que sobe os GenServers
    ]
  end

  defp deps do
    [
      {:kanban_domain, in_umbrella: true},   # entidades e ports
      {:persistence, in_umbrella: true},     # repositórios (Agents)
      {:telemetry, "~> 1.0"}                 # métricas e instrumentação
    ]
  end
end
```

### 1.2.5 — Grafo de dependências do umbrella

```
kanban_vision_api_iex (umbrella raiz)
├── kanban_domain   ──── sem dependências internas
│                        deps: [elixir_uuid]
│
├── persistence     ──── depende de kanban_domain
│                        deps: [{:kanban_domain, in_umbrella: true}]
│
└── usecase         ──── depende de kanban_domain + persistence
                         deps: [{:kanban_domain, in_umbrella: true},
                                {:persistence, in_umbrella: true},
                                {:telemetry, "~> 1.0"}]
                         mod: KanbanVisionApi.Usecase.Application
```

**Regra de ouro:** as setas de dependência sempre apontam para dentro (em direção ao domínio). O `kanban_domain` nunca depende de `persistence` ou `usecase`.

```
usecase ──────► persistence ──────► kanban_domain
          ────────────────────────►
```

### 1.2.6 — Configuração compartilhada com `config/config.exs`

```elixir
# config/config.exs — afeta TODOS os apps do umbrella
import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :correlation_id,      # campos customizados de observabilidade
    :organization_id,
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

Para configurações por ambiente:
```
config/
├── config.exs      ← base (sempre carregado)
├── dev.exs         ← iex -S mix / mix run
├── test.exs        ← mix test (MIX_ENV=test automático)
├── prod.exs        ← MIX_ENV=prod mix compile
└── runtime.exs     ← carregado em runtime (bom para segredos e env vars)
```

### 1.2.7 — Comandos Mix essenciais

```bash
# === Dependências ===
mix deps.get                        # baixa todas as dependências
mix deps.update --all               # atualiza para versões mais recentes
mix deps.clean --all                # remove deps compiladas (reset)
mix deps.tree                       # visualiza grafo de dependências

# === Compilação ===
mix compile                         # compila o projeto
mix compile --warnings-as-errors    # falha se houver warnings (CI)

# === Testes ===
mix test                            # todos os testes
mix test --app kanban_domain        # apenas um app do umbrella
mix test apps/usecase/test/kanban_vision_api/usecase/organization_test.exs
mix test apps/usecase/test/...organization_test.exs:42   # linha específica
mix test --only domain_organizations # testes com @tag :domain_organizations
mix test --only integration          # testes de integração
mix test.watch                       # re-roda ao salvar arquivos

# === Qualidade ===
mix format                           # formata o código automaticamente
mix format --check-formatted         # falha se não formatado (CI)
mix credo                            # análise estática de qualidade

# === Cobertura ===
MIX_ENV=test mix coveralls --umbrella         # cobertura completa
MIX_ENV=test mix coveralls.github --umbrella  # para GitHub Actions

# === IEx ===
iex -S mix                           # shell interativo com projeto carregado
```

### 1.2.8 — Tags de teste: organizando e filtrando

```elixir
# Tag em módulo inteiro
@moduletag :domain_organizations    # todos os testes do módulo recebem a tag

# Tag em teste individual
@tag :integration
test "contrato do repositório" do ... end

# Excluir por padrão no mix.exs (integração roda só quando explicitado)
def project do
  [
    ...,
    test_coverage: [...],
    preferred_cli_env: [coveralls: :test],
    # ExUnit config — exclusões padrão
  ]
end
```

```bash
mix test                        # exclui :integration por padrão
mix test --only integration     # roda apenas integração
mix test --only domain_boards   # roda apenas testes de boards
mix test --exclude slow         # exclui testes lentos
```

---

## Resumo do Módulo 1

| Conceito | Comando / Arquivo |
|---------|------------------|
| Criar umbrella | `mix new nome --umbrella` |
| Criar app filho | `cd apps && mix new nome [--sup]` |
| Dep interna do umbrella | `{:nome_app, in_umbrella: true}` |
| App com processos OTP | `mod: {MinhaApp.Application, []}` no `application/0` |
| Configuração compartilhada | `config/config.exs` na raiz |
| Testar app específico | `mix test --app nome_app` |
| Filtrar testes por tag | `mix test --only minha_tag` |
| Análise estática | `mix credo` + `mix format --check-formatted` |
| Cobertura | `MIX_ENV=test mix coveralls --umbrella` |

> **Próximo módulo:** Fundamentos da linguagem Elixir — tipos, funções, pattern matching e imutabilidade.
