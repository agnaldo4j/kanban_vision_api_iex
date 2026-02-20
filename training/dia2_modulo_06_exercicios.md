# Dia 2 — Módulo 6: Exercícios Práticos

> Hora de colocar em prática! Os exercícios são progressivos:
> cada um aplica os conceitos do workshop no projeto real.

---

## Setup inicial

```bash
# Clone e prepare o ambiente
cd kanban_vision_api_iex
mix deps.get
mix test              # todos os testes devem passar
iex -S mix            # abrir o shell interativo
```

---

## Exercício 1 — Exploração no IEx (5 min)

**Objetivo:** Entender o fluxo completo de uma operação

```elixir
# No IEx (iex -S mix):

alias KanbanVisionApi.Usecase.Organization
alias KanbanVisionApi.Usecase.Organization.{
  CreateOrganizationCommand,
  DeleteOrganizationCommand,
  GetOrganizationByIdQuery,
  GetOrganizationByNameQuery
}

# 1. Iniciar o GenServer manualmente
{:ok, pid} = Organization.start_link()

# 2. Criar uma organização via Command
{:ok, cmd} = CreateOrganizationCommand.new("Empresa Alpha")
{:ok, org} = Organization.add(pid, cmd)
IO.inspect(org, label: "Organização criada")

# 3. Criar uma segunda organização
{:ok, cmd2} = CreateOrganizationCommand.new("Empresa Beta")
{:ok, org2} = Organization.add(pid, cmd2)

# 4. Listar todas
{:ok, todas} = Organization.get_all(pid)
IO.inspect(Map.keys(todas), label: "IDs das organizações")

# 5. Buscar por ID
{:ok, query} = GetOrganizationByIdQuery.new(org.id)
{:ok, encontrada} = Organization.get_by_id(pid, query)
IO.inspect(encontrada.name, label: "Encontrada")

# 6. Tentar criar com nome duplicado
{:ok, cmd_dup} = CreateOrganizationCommand.new("Empresa Alpha")
resultado = Organization.add(pid, cmd_dup)
IO.inspect(resultado, label: "Resultado com duplicata")

# 7. Deletar
{:ok, del_cmd} = DeleteOrganizationCommand.new(org.id)
{:ok, removida} = Organization.delete(pid, del_cmd)
IO.inspect(removida.name, label: "Removida")

# PERGUNTAS PARA REFLEXÃO:
# - Onde está sendo gerado o UUID da organização?
# - O GenServer tem lógica de negócio ou apenas orquestra?
# - O que acontece se você passar um ID inválido para get_by_id?
```

---

## Exercício 2 — Adicionar um novo Use Case (10 min)

**Objetivo:** Implementar `GetOrganizationByName` seguindo os padrões do projeto

**Contexto:** A query `GetOrganizationByNameQuery` já existe em `organization/queries.ex`.
O Use Case `GetOrganizationByName` já existe em `organizations/get_organization_by_name.ex`.
O método `get_by_name` já existe no Agent.

Sua tarefa: **escrever o teste do Use Case** seguindo o padrão existente.

```elixir
# Crie o arquivo:
# apps/usecase/test/kanban_vision_api/usecase/get_organization_by_name_test.exs

defmodule KanbanVisionApi.Usecase.GetOrganizationByNameTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Usecase.Organization
  alias KanbanVisionApi.Usecase.Organization.{
    CreateOrganizationCommand,
    GetOrganizationByNameQuery
  }

  describe "get_by_name" do
    setup do
      {:ok, pid} = Organization.start_link()
      {:ok, pid: pid}
    end

    # ESCREVA OS TESTES:

    # Teste 1: encontra organização pelo nome (happy path)
    test "encontra organização pelo nome", %{pid: pid} do
      # dado que uma organização existe
      # quando busco pelo nome
      # então devo receber a organização correta
      # IMPLEMENTE
    end

    # Teste 2: retorna erro quando não encontra
    test "retorna erro quando organização não existe", %{pid: pid} do
      # IMPLEMENTE
    end

    # Teste 3: query com nome vazio é inválida
    test "rejeita query com nome vazio" do
      # IMPLEMENTE (não precisa do pid)
    end

    # Teste 4 (DESAFIO): cria duas orgs com nomes diferentes, busca por uma
    test "retorna apenas a organização com o nome buscado", %{pid: pid} do
      # IMPLEMENTE
    end
  end
end
```

**Dicas:**
- Veja `apps/usecase/test/kanban_vision_api/usecase/organization_test.exs` como referência
- Use o padrão given-when-then nos comentários
- Execute com: `mix test apps/usecase/test/kanban_vision_api/usecase/get_organization_by_name_test.exs`

---

## Exercício 3 — Criar uma nova Entidade de Domínio (10 min)

**Objetivo:** Adicionar a entidade `Tag` ao domínio, seguindo todos os padrões

**Contexto:** Uma `Tag` pode ser associada a uma `Organization` para categorizá-la (ex: "fintech", "startup", "enterprise").

### Passo 1: Criar a entidade

```elixir
# Crie: apps/kanban_domain/lib/kanban_vision_api/domain/tag.ex
# Seguindo o padrão de organization.ex, ability.ex, etc.

defmodule KanbanVisionApi.Domain.Tag do
  # IMPLEMENTE:
  # - defstruct com campos: id, audit, name, color
  # - @type t()
  # - def new(name, color \\ "blue")
end
```

### Passo 2: Adicionar tags à Organization

```elixir
# Modifique: apps/kanban_domain/lib/kanban_vision_api/domain/organization.ex
# Adicione o campo :tags ao defstruct e ao @type
# Atualize o new/N para aceitar tags (default: [])
```

### Passo 3: Escrever o teste

```elixir
# Crie: apps/kanban_domain/test/kanban_vision_api/domain/tag_test.exs

defmodule KanbanVisionApi.Domain.TagTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.Tag

  describe "new/2" do
    # ESCREVA:
    # - Teste de criação com defaults (color azul)
    # - Teste de criação com cor customizada
    # - Teste que gera UUID único para cada tag
    # - Teste que cria Audit com timestamps
  end
end
```

### Verificação

```bash
mix test apps/kanban_domain/test/kanban_vision_api/domain/tag_test.exs
mix credo                  # sem violações de estilo
mix format --check-formatted
```

**Perguntas para reflexão:**
- Tag é uma Entidade ou Value Object? (tem identidade própria?)
- A relação `Organization → Tag` é `has_many` ou `belongs_to`?
- Como adicionar a Tag sem quebrar testes existentes de Organization?

---

## Exercício 4 — Análise de Arquitetura (5 min)

**Objetivo:** Identificar violações arquiteturais no código hipotético abaixo

```elixir
# Analise este código e identifique TODOS os problemas:

defmodule KanbanVisionApi.Usecase.Organizations.CreateOrganizationBad do
  alias KanbanVisionApi.Agent.Organizations  # ← problema?

  def execute(name, tribes \\ []) do
    # Cria diretamente sem Command
    if String.length(name) == 0 do
      raise ArgumentError, "nome inválido"   # ← problema?
    end

    id = UUID.uuid4()
    now = DateTime.utc_now()
    org = %{id: id, name: name, tribes: tribes,  # ← problema?
            created_at: now, updated_at: now}

    {:ok, pid} = Organizations.start_link()      # ← problema?

    result = Organizations.add(pid, org)

    IO.puts("Criado: #{name}")                   # ← problema?

    case result do
      {:ok, o} ->
        get_org = Organizations.get_by_id(pid, o.id)  # ← problema?
        {:ok, get_org}
      error -> error
    end
  end
end
```

**Identifique:**
1. Qual princípio SOLID é violado em cada linha problemática?
2. Qual conceito de arquitetura hexagonal está sendo ignorado?
3. O que está errado com a separação de Command/Query?
4. Quais side effects são problemáticos e por quê?

**Solução comentada:** disponível em `training/gabarito_exercicio_4.md`

---

## Gabarito do Exercício 4

```
1. alias KanbanVisionApi.Agent.Organizations
   → DIP violado: Use Case de alto nível depende diretamente do Adapter concreto

2. raise ArgumentError
   → Viola CQS e padrão do projeto: use {:error, :invalid_name}
   → Exceptions para controle de fluxo são anti-pattern em Elixir idiomático

3. %{id: ..., name: ..., created_at: ...}
   → Não usa a entidade de domínio Organization.new()
   → Map genérico em vez de struct tipado viola type-safety e DDD

4. {:ok, pid} = Organizations.start_link()
   → SRP violado: Use Case não deve gerenciar lifecycle do repositório
   → Cria Agent sem supervisão — process leak!
   → Viola Hexagonal: deveria receber o pid como parâmetro

5. IO.puts("Criado: #{name}")
   → Side effect não estruturado — sem correlation_id, sem metadata
   → Use Logger.info/2 com metadata estruturada

6. get_org = Organizations.get_by_id(pid, o.id) após add
   → CQS violado: Command (add) não deve fazer Query adicional
   → O add já retorna o {:ok, org} — redundante e viola CQS
```

---

## Desafio Final — Para casa

Implemente o **Use Case `AddTagToOrganization`** completo, seguindo **todos** os padrões do projeto:

```
□ Command: AddTagToOrganizationCommand (com validação)
□ Use Case: AddTagToOrganization.execute/3
  □ Logger.info no início
  □ Logger.info no sucesso
  □ Logger.error na falha
  □ EventEmitter.emit no sucesso
  □ correlation_id propagado
□ Port: método add_tag em OrganizationRepository behaviour
□ Adapter: implementação em Agent.Organizations
□ GenServer: método add_tag em Usecase.Organization
□ Testes unitários do Command
□ Testes unitários do Use Case (com mock do repositório)
□ Teste de integração via GenServer
□ mix test → todos passando
□ mix credo → sem erros
```

---

## Resumo do Workshop

```
4 horas de imersão:

┌─────────────────────────────────────────────────────────────┐
│  Módulo 1 (50 min): Fundamentos Elixir                      │
│  Types • Structs • @type • Pattern Matching                 │
│  Imutabilidade • Agents • GenServer • Supervisores          │
├─────────────────────────────────────────────────────────────┤
│  BREAK (10 min)                                             │
├─────────────────────────────────────────────────────────────┤
│  Módulo 2 (45 min): Arquitetura                             │
│  Screaming Architecture • Hexagonal Architecture • DDD      │
│  Ports & Adapters • Bounded Contexts • Ubiquitous Language  │
├─────────────────────────────────────────────────────────────┤
│  Módulo 3 (40 min): SOLID em Elixir                         │
│  SRP • OCP • LSP (contract tests) • ISP • DIP               │
├─────────────────────────────────────────────────────────────┤
│  BREAK (10 min)                                             │
├─────────────────────────────────────────────────────────────┤
│  Módulo 4 (35 min): Side Effects, Imutabilidade e CQS       │
│  Funções puras • Push para a borda • Commands • Queries     │
├─────────────────────────────────────────────────────────────┤
│  Módulo 5 (25 min): Observabilidade                         │
│  Logger estruturado • Telemetria • Correlation ID           │
├─────────────────────────────────────────────────────────────┤
│  Módulo 6 (30 min): Exercícios Práticos                     │
│  IEx exploration • Novo Use Case • Nova Entidade            │
│  Análise de code smells                                     │
└─────────────────────────────────────────────────────────────┘
```

### Referências

| Livro/Recurso | Relevância |
|---------------|-----------|
| Clean Architecture — Robert C. Martin | Screaming Architecture, componentes |
| Domain-Driven Design — Eric Evans | Bounded Contexts, Ubiquitous Language |
| [Screaming Architecture (blog)](https://blog.cleancoder.com/uncle-bob/2011/09/30/Screaming-Architecture.html) | Artigo original do Uncle Bob |
| SOLID Principles — Clean Coders | Todos os 5 princípios com exemplos |
| Elixir in Action — Saša Jurić | GenServer, Agents, OTP patterns |
| [Hexdocs — Elixir 1.18](https://hexdocs.pm/elixir/1.18.4/) | Documentação oficial |
| [Telemetry Docs](https://hexdocs.pm/telemetry/) | Instrumentação em Elixir |
