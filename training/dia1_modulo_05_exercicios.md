# Dia 1 — Módulo 5: Exercícios Práticos

> Coloque em prática o que foi visto nos módulos 1 a 4.
> Todos os exercícios usam o projeto `kanban_vision_api_iex` como base.
> Não se preocupe em acertar tudo — o objetivo é explorar e observar.

---

## Exercício 1 — Explorando o projeto com Mix e IEx (5 min)

### 1a. Navegue pela estrutura

```bash
# Na raiz do projeto:
mix deps.get
mix compile
```

Responda sem olhar o código:

- Quantos apps existem no umbrella? Quais são?
- Qual app tem `mod:` no `application/0`? Por quê?
- Qual dep externa usa `kanban_domain`?

### 1b. Abra o IEx

```bash
iex -S mix
```

No shell interativo, explore:

```elixir
# Inspecione os módulos disponíveis
h KanbanVisionApi.Domain.Organization
h KanbanVisionApi.Agent.Organizations

# Crie uma entidade na memória
org = KanbanVisionApi.Domain.Organization.new("Acme")
IO.inspect(org)

# Veja o tipo da struct
i org
```

**O que observar:**
- O campo `id` é gerado automaticamente?
- O campo `audit` tem `inserted_at` e `updated_at`?
- Quais campos `tribes` começa com o quê?

---

## Exercício 2 — Fundamentos Elixir na prática (5 min)

Ainda no IEx, execute os exemplos abaixo **um por um** e observe os resultados:

### 2a. Pattern matching

```elixir
# Tupla de sucesso/erro
{:ok, org} = {:ok, KanbanVisionApi.Domain.Organization.new("Acme")}
org.name

# O que acontece se o padrão não bater?
{:ok, org2} = {:error, :invalid_name}
```

### 2b. Pipe operator

```elixir
# Encadeando operações com |>
"  hello world  "
|> String.trim()
|> String.split(" ")
|> Enum.map(&String.capitalize/1)
|> Enum.join(" ")
```

### 2c. Imutabilidade em structs

```elixir
org = KanbanVisionApi.Domain.Organization.new("Original")
org_modificada = %{org | name: "Modificado"}

# Qual o nome de cada um?
org.name
org_modificada.name

# São o mesmo struct?
org == org_modificada
```

### 2d. with — encadeamento seguro

```elixir
# Simule o fluxo de um use case
resultado =
  with {:ok, cmd} <- KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand.new("Acme"),
       {:ok, pid} <- KanbanVisionApi.Usecase.Organization.start_link() do
    KanbanVisionApi.Usecase.Organization.add(pid, cmd)
  end

resultado
```

---

## Exercício 3 — OTP: Agent e GenServer (5 min)

### 3a. Agent direto

```elixir
alias KanbanVisionApi.Agent.Organizations
alias KanbanVisionApi.Domain.Organization

# Inicie o Agent manualmente
{:ok, pid} = Organizations.start_link(Organizations.new())

# Estado inicial
Organizations.get_all(pid)

# Adicione uma organização
org = Organization.new("Acme")
Organizations.add(pid, org)

# Verifique o estado após a operação
Organizations.get_all(pid)

# Busque por ID
Organizations.get_by_id(pid, org.id)
```

### 3b. GenServer completo

```elixir
alias KanbanVisionApi.Usecase.Organization
alias KanbanVisionApi.Usecase.Organization.{
  CreateOrganizationCommand,
  GetOrganizationByIdQuery,
  DeleteOrganizationCommand
}

# Suba o GenServer (ele cria o Agent internamente)
{:ok, gs_pid} = Organization.start_link()

# Criar
{:ok, cmd} = CreateOrganizationCommand.new("Globo")
{:ok, org} = Organization.add(gs_pid, cmd)

# Buscar
{:ok, query} = GetOrganizationByIdQuery.new(org.id)
Organization.get_by_id(gs_pid, query)

# Deletar
{:ok, del} = DeleteOrganizationCommand.new(org.id)
Organization.delete(gs_pid, del)

# Confirmar que foi removida
Organization.get_all(gs_pid)
```

**O que observar:**
- O GenServer aceita o Command diretamente ou ele redireciona para outro módulo?
- O que acontece se você passar uma string vazia para `CreateOrganizationCommand.new("")`?

---

## Exercício 4 — Escrevendo e rodando um teste (5 min)

### 4a. Rode os testes existentes

```bash
# Todos os testes
mix test

# Apenas o domínio
mix test --app kanban_domain

# Apenas um arquivo
mix test apps/usecase/test/kanban_vision_api/usecase/organization_test.exs

# Por tag
mix test --only domain_organizations
```

### 4b. Leia um teste e explique

Abra o arquivo:
```
apps/usecase/test/kanban_vision_api/usecase/organization_test.exs
```

Identifique:
- Qual o `setup` está fazendo?
- Qual teste valida o "ciclo de vida completo"?
- O que `assert {:ok, ^org}` significa? Por que `^`?

### 4c. Desafio: escreva um teste novo (opcional)

Adicione este teste ao arquivo de Organizations do Agent:

```elixir
# apps/persistence/test/kanban_vision_api/agent/organizations_test.exs

test "não encontra organização com id inexistente", %{actor_pid: pid} do
  # dado — id que não existe
  id_inexistente = "00000000-0000-0000-0000-000000000000"

  # quando — buscamos por ele
  resultado = Organizations.get_by_id(pid, id_inexistente)

  # então — esperamos erro
  assert {:error, _} = resultado
end
```

Rode apenas este arquivo:
```bash
mix test apps/persistence/test/kanban_vision_api/agent/organizations_test.exs
```

---

## Resumo do Dia 1

```
┌──────────────────────────────────────────────────────────────┐
│                    O que você aprendeu hoje                  │
│                                                              │
│  Mix (Módulo 1)                                              │
│  ├── mix new --umbrella, apps filhos, mix.exs                │
│  ├── Dependências internas: in_umbrella: true                │
│  └── Comandos: mix test, mix credo, mix format               │
│                                                              │
│  Elixir (Módulo 2)                                           │
│  ├── Tipos: atom, string, tuple, list, map, struct           │
│  ├── Pattern matching: =, case, guards, with                 │
│  └── Imutabilidade: %{struct | field: val}                   │
│                                                              │
│  OTP (Módulo 3)                                              │
│  ├── Processos: spawn, send, receive                         │
│  ├── Agent: estado simples em memória                        │
│  ├── GenServer: cliente-servidor com call/cast               │
│  └── Supervisor: árvore de supervisão                        │
│                                                              │
│  ExUnit (Módulo 4)                                           │
│  ├── describe / test / setup                                 │
│  ├── assert com pattern matching                             │
│  └── @tag para filtrar testes                                │
└──────────────────────────────────────────────────────────────┘
```

> **Amanhã (Dia 2):** Arquitetura Hexagonal, DDD, SOLID, Use Cases isolados,
> controle de side effects, CQS e observabilidade — tudo aplicado neste mesmo projeto.
