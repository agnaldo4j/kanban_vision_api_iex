# Dia 1 — Módulo 4: Testes com ExUnit

> Testes em Elixir não são opcionais — são parte do design.
> O próprio projeto define thresholds mínimos de cobertura por app.
> Vamos entender como testar domínio, Agents e GenServers.

---

## 4.1 Estrutura básica do ExUnit (5 min)

```elixir
# test/meu_modulo_test.exs
defmodule MeuModuloTest do
  use ExUnit.Case, async: true   # async: true = testes rodam em paralelo

  describe "contexto ou função sendo testada" do
    test "descrição do comportamento esperado" do
      # dado — preparação
      valor = 42

      # quando — execução
      resultado = MeuModulo.dobrar(valor)

      # então — verificação
      assert resultado == 84
    end
  end
end
```

### `async: true` — quando usar

```elixir
# async: true  — testes que não compartilham estado global
#                (maioria dos testes de domínio e unidade)
use ExUnit.Case, async: true

# async: false — testes que escrevem em banco, arquivos ou estado global
use ExUnit.Case  # default é false
```

### Assertions essenciais

```elixir
assert valor == esperado             # igualdade
assert valor != outro                # diferença
refute condicao                      # nega (assert not)

assert is_binary(str)                # verifica tipo
assert length(lista) == 3           # verifica tamanho

# Pattern matching em assert — verifica estrutura E faz bind
assert {:ok, org} = Organization.add(pid, new_org)
# Se o resultado for {:ok, _}, continua e org fica disponível
# Se o resultado for {:error, _}, o teste falha com mensagem clara

assert {:error, :invalid_name} = CreateOrganizationCommand.new("")

# Exceções
assert_raise RuntimeError, fn -> funcao_que_explode() end
assert_raise ArgumentError, ~r/invalid/, fn -> bad_call() end
```

---

## 4.2 Setup e fixtures (7 min)

### setup — executado antes de cada test

```elixir
defmodule KanbanVisionApi.Agent.OrganizationsTest do
  use ExUnit.Case, async: true

  # setup recebe o contexto e retorna kw-list que vira o contexto do test
  setup do
    org = Organization.new("ExampleOrg")
    initial_state = Organizations.new(%{org.id => org})
    {:ok, pid} = Organizations.start_link(initial_state)

    # Tudo que está nesta kw-list fica disponível nos tests como %{key: val}
    [actor_pid: pid, domain: org]
  end

  test "deve encontrar organização por id", %{actor_pid: pid, domain: org} do
    assert Organizations.get_by_id(pid, org.id) == {:ok, org}
  end
end
```

### Múltiplos setup por describe

```elixir
defmodule OrganizationsTest do
  use ExUnit.Case, async: true

  describe "com estado vazio" do
    setup [:prepare_empty_context]

    test "não tem organizações", %{actor_pid: pid} do
      assert Organizations.get_all(pid) == %{}
    end
  end

  describe "com uma organização no estado" do
    setup [:prepare_context_with_default_organization]

    test "tem uma organização", %{actor_pid: pid, domain: org} do
      assert Organizations.get_all(pid) == %{org.id => org}
    end
  end

  # Funções de setup reutilizáveis
  defp prepare_empty_context(_context) do
    {:ok, pid} = Organizations.start_link(Organizations.new())
    [actor_pid: pid]
  end

  defp prepare_context_with_default_organization(_context) do
    org = Organization.new("ExampleOrg")
    state = Organizations.new(%{org.id => org})
    {:ok, pid} = Organizations.start_link(state)
    [actor_pid: pid, domain: org]
  end
end
```

---

## 4.3 Tags — filtrando e organizando testes (5 min)

```elixir
# Tag no módulo inteiro
defmodule OrganizationDomainTest do
  use ExUnit.Case, async: true

  @moduletag :domain_organizations   # todos os tests recebem essa tag
end

# Tag em test individual
defmodule ContractTest do
  use ExUnit.Case

  @tag :integration                  # apenas este test
  test "contrato do repositório" do
    # teste mais lento — bate no Agent real
  end

  @tag :skip
  test "teste pendente de implementação" do
    # será ignorado
  end
end
```

```bash
# Rodando com filtro de tag
mix test --only domain_organizations     # apenas testes do domínio
mix test --only integration              # apenas testes de integração
mix test --exclude integration           # exclui integração
mix test --exclude slow                  # exclui testes lentos
```

---

## 4.4 Os três níveis de teste no projeto (13 min)

### Nível 1 — Testes de domínio (mais rápidos, mais simples)

```elixir
# apps/kanban_domain/test/kanban_vision_api/domain/organization_test.exs
# Testa APENAS a entidade — zero infraestrutura

defmodule KanbanVisionApi.Domain.OrganizationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Domain.{Organization, Tribe, Audit}

  describe "new/1" do
    test "cria organization com nome e defaults" do
      # dado
      nome = "Acme"

      # quando
      org = Organization.new(nome)

      # então
      assert org.name == nome
      assert org.tribes == []
      assert is_binary(org.id)        # UUID gerado
      assert %Audit{} = org.audit     # timestamps criados
    end

    test "gera UUIDs únicos para cada instância" do
      org1 = Organization.new("Org A")
      org2 = Organization.new("Org B")
      refute org1.id == org2.id
    end

    test "aceita tribes opcionais" do
      tribe = Tribe.new("Backend")
      org = Organization.new("Acme", [tribe])
      assert org.tribes == [tribe]
    end
  end
end
```

**Características:**
- Sem Agent, sem GenServer, sem network
- `async: true` — roda em paralelo
- Tempo de execução: < 1ms cada
- Testa comportamento puro da entidade

### Nível 2 — Testes do repositório (Agent)

```elixir
# apps/persistence/test/kanban_vision_api/agent/organizations_test.exs
# Testa o Agent em memória — sem banco real, mas com estado

defmodule KanbanVisionApi.Agent.OrganizationsTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Agent.Organizations
  alias KanbanVisionApi.Domain.Organization

  describe "sistema com estado vazio" do
    setup [:prepare_empty_context]

    @tag :domain_organizations
    test "não tem organizações", %{actor_pid: pid} do
      assert Organizations.get_all(pid) == %{}
    end

    @tag :domain_organizations
    test "pode adicionar organização", %{actor_pid: pid} do
      org = Organization.new("Acme")
      assert {:ok, ^org} = Organizations.add(pid, org)
    end

    test "rejeita organização com nome duplicado", %{actor_pid: pid} do
      org = Organization.new("Acme")
      Organizations.add(pid, org)
      assert {:error, _} = Organizations.add(pid, org)
    end
  end

  defp prepare_empty_context(_) do
    {:ok, pid} = Organizations.start_link(Organizations.new())
    [actor_pid: pid]
  end
end
```

### Nível 3 — Testes de Use Case via GenServer (integração)

```elixir
# apps/usecase/test/kanban_vision_api/usecase/organization_test.exs
# Testa o fluxo completo: GenServer → Use Case → Agent

defmodule KanbanVisionApi.Usecase.OrganizationTest do
  use ExUnit.Case, async: true

  alias KanbanVisionApi.Usecase.Organization
  alias KanbanVisionApi.Usecase.Organization.{
    CreateOrganizationCommand,
    DeleteOrganizationCommand,
    GetOrganizationByIdQuery
  }

  describe "fluxo completo de organização" do
    setup do
      {:ok, pid} = Organization.start_link()
      [pid: pid]
    end

    test "ciclo de vida: criar → buscar → deletar", %{pid: pid} do
      # criar
      {:ok, cmd} = CreateOrganizationCommand.new("Acme")
      assert {:ok, org} = Organization.add(pid, cmd)
      assert org.name == "Acme"

      # buscar
      {:ok, query} = GetOrganizationByIdQuery.new(org.id)
      assert {:ok, ^org} = Organization.get_by_id(pid, query)

      # deletar
      {:ok, del_cmd} = DeleteOrganizationCommand.new(org.id)
      assert {:ok, ^org} = Organization.delete(pid, del_cmd)

      # confirmar remoção
      assert {:ok, %{}} = Organization.get_all(pid)
    end

    test "rejeita Command inválido antes de chegar no GenServer" do
      # Validação acontece na criação do Command — nem chega no GenServer
      assert {:error, :invalid_name} = CreateOrganizationCommand.new("")
      assert {:error, :invalid_name} = CreateOrganizationCommand.new(nil)
    end

    test "não permite nomes duplicados", %{pid: pid} do
      {:ok, cmd} = CreateOrganizationCommand.new("Acme")
      {:ok, _} = Organization.add(pid, cmd)

      {:ok, cmd2} = CreateOrganizationCommand.new("Acme")
      assert {:error, _} = Organization.add(pid, cmd2)
    end
  end
end
```

### Comparação dos três níveis

| Nível | Velocidade | Isolamento | Detecta |
|-------|-----------|------------|---------|
| Domínio | < 1ms | Total | Bugs nas entidades |
| Agent | ~5ms | Parcial | Bugs na persistência |
| GenServer | ~10ms | Mínimo | Bugs no fluxo completo |

---

## Resumo do Módulo 4

```
┌─────────────────────────────────────────────────────────────┐
│                   Estratégia de testes                      │
│                                                             │
│  Domínio (kanban_domain/test/)                              │
│  ├── async: true                                            │
│  ├── Sem infraestrutura                                     │
│  └── Testa entidades, value objects, factories              │
│                                                             │
│  Repositório (persistence/test/)                            │
│  ├── async: true                                            │
│  ├── Agent real em memória                                  │
│  └── Testa CRUD, validações, estado                         │
│                                                             │
│  Use Cases (usecase/test/)                                  │
│  ├── async: true                                            │
│  ├── GenServer + Agent real                                 │
│  └── Testa fluxo de ponta a ponta                           │
└─────────────────────────────────────────────────────────────┘
```

| Conceito | Como usar |
|---------|-----------|
| Módulo de teste | `use ExUnit.Case, async: true` |
| Teste simples | `test "descrição" do ... end` |
| Agrupamento | `describe "contexto" do ... end` |
| Fixture | `setup do ... [chave: valor] end` |
| Tag no módulo | `@moduletag :nome_da_tag` |
| Tag no teste | `@tag :nome_da_tag` |
| Filtrar | `mix test --only nome_da_tag` |
| Pattern em assert | `assert {:ok, org} = Organization.add(...)` |

> **Próximo módulo:** Exercícios práticos do Dia 1 — colocar tudo em prática no projeto real.
