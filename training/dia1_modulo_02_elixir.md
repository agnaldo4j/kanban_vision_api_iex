# Dia 1 — Módulo 2: Fundamentos de Elixir

> Vamos aprender a linguagem usando o próprio projeto como referência.
> A cada conceito novo, você vai reconhecer onde ele aparece no código.

---

## 2.1 Tipos Primitivos (8 min)

### Atoms — identificadores imutáveis

```elixir
:ok
:error
:not_found
nil       # é um atom
true      # é um atom
false     # é um atom
```

Atoms são constantes cujo nome é seu valor. São leves, rápidos de comparar e **nunca coletados pelo GC**. Por isso não crie atoms dinamicamente a partir de input externo.

No projeto, atoms são usados em toda parte como retornos de status:

```elixir
# apps/usecase/lib/.../organizations/create_organization.ex
{:ok, org}              # retorno de sucesso
{:error, :invalid_name} # retorno de falha
{:error, reason}        # falha com razão descritiva
```

### Strings — binários UTF-8

```elixir
"Olá, mundo!"
"Nome: #{name}"          # interpolação — executa qualquer expressão
"Id: #{org.id}"

# Operações comuns
String.upcase("elixir")           #=> "ELIXIR"
String.split("a,b,c", ",")        #=> ["a", "b", "c"]
String.contains?("hello", "ell")  #=> true
String.length("héllo")            #=> 5  (conta caracteres Unicode)
byte_size("hello")                #=> 5  (conta bytes — útil em guards)
```

### Números

```elixir
42          # integer
3.14        # float
1_000_000   # underscore como separador visual (válido!)
0xFF        # hexadecimal = 255
0b1010      # binário = 10
```

### Tuplas — retornos com status

Convenção central em Elixir: funções retornam `{:ok, valor}` ou `{:error, razão}`:

```elixir
{:ok, "resultado"}
{:error, "algo deu errado"}
{:error, :not_found}

# Acessando elementos
elem({:ok, 42}, 0)   #=> :ok
elem({:ok, 42}, 1)   #=> 42
```

### Listas

```elixir
[1, 2, 3]
["alice", "bob"]
[]                         # lista vazia

# Operações básicas
length([1, 2, 3])          #=> 3
hd([1, 2, 3])              #=> 1    (head — primeiro elemento)
tl([1, 2, 3])              #=> [2, 3] (tail — resto)
[0 | [1, 2, 3]]            #=> [0, 1, 2, 3]  (prepend — O(1))
[1, 2] ++ [3, 4]           #=> [1, 2, 3, 4]  (concatenar — O(n))
```

### Maps — chave-valor

```elixir
%{nome: "Alice", idade: 30}         # chaves atom
%{"nome" => "Alice", "id" => 1}     # chaves string

# Acesso
mapa = %{nome: "Alice"}
mapa.nome          #=> "Alice"      (só funciona com chaves atom)
mapa[:nome]        #=> "Alice"
mapa[:inexistente] #=> nil          (não lança erro)

# "Atualização" — cria novo map
%{mapa | nome: "Bob"}   #=> %{nome: "Bob"}
# mapa ainda é %{nome: "Alice"} — imutável!
```

### Keyword lists — opções de função

```elixir
# Lista de tuplas {atom, valor} — usada para passar opções
opts = [timeout: 5000, retry: 3, verbose: true]

opts[:timeout]              #=> 5000
Keyword.get(opts, :retry)   #=> 3
Keyword.get(opts, :debug, false)  # com default

# Veja no projeto — Use Cases recebem opts
CreateOrganization.execute(cmd, pid, [
  correlation_id: "req-123",
  repository: MockRepository
])
```

---

## 2.2 Funções e Módulos (8 min)

### Definindo módulos e funções

```elixir
defmodule Calculadora do
  # Função pública
  def soma(a, b), do: a + b

  # Função pública com corpo em bloco
  def multiplica(a, b) do
    a * b
  end

  # Função privada — só acessível dentro do módulo
  defp valida(n) when n > 0, do: :ok
  defp valida(_), do: :error
end

Calculadora.soma(3, 4)         #=> 7
Calculadora.multiplica(3, 4)   #=> 12
```

### Aridade e argumentos padrão

```elixir
defmodule KanbanVisionApi.Domain.Organization do
  # new/1 e new/2 e new/3 e new/4 — todos gerados pelo \\ (default)
  def new(name, tribes \\ [], id \\ UUID.uuid4(), audit \\ Audit.new()) do
    %__MODULE__{id: id, audit: audit, name: name, tribes: tribes}
  end
end

Organization.new("Acme")               # usa todos os defaults
Organization.new("Acme", [tribe1])     # passa tribes
Organization.new("Acme", [], "uuid-custom")  # passa id customizado
```

### Pipe operator `|>`

O pipe passa o resultado da expressão da esquerda como **primeiro argumento** da função da direita:

```elixir
# Sem pipe — difícil de ler (de dentro para fora)
Enum.uniq(Enum.sort(Enum.map(Enum.filter(orgs, & &1.active), & &1.name)))

# Com pipe — fácil de ler (de cima para baixo)
orgs
|> Enum.filter(& &1.active)
|> Enum.map(& &1.name)
|> Enum.sort()
|> Enum.uniq()
```

---

## 2.3 Pattern Matching — o coração do Elixir (12 min)

O operador `=` em Elixir não é atribuição — é **correspondência de padrão**:

```elixir
# Bind simples (funciona como atribuição)
x = 42
x   #=> 42

# Desestruturação — extrai valores de estruturas
{:ok, resultado} = {:ok, "dados"}
resultado  #=> "dados"

# Falha de match — lança MatchError
{:ok, _} = {:error, "falhou"}   # ** (MatchError) no match of right hand side

# Pin operator ^ — não rebinda, apenas verifica
x = 42
^x = 42    # OK — verifica que x ainda é 42
^x = 43    # ** (MatchError)
```

### Pattern matching em maps e structs

```elixir
mapa = %{nome: "Alice", idade: 30}

# Extrai campos específicos (campos extras são ignorados)
%{nome: nome} = mapa
nome  #=> "Alice"

# Em structs — verifica o tipo também
%Organization{name: name, id: id} = org
name  #=> "Acme"
id    #=> "uuid-..."

# _ ignora um valor
{:ok, _} = {:ok, "não me importo com isso"}
```

### Pattern matching em funções — cláusulas

```elixir
# Cada cláusula é testada em ordem; a primeira que casa executa
def processar({:ok, dado}),      do: "sucesso: #{dado}"
def processar({:error, motivo}), do: "erro: #{motivo}"
def processar(_),                do: "desconhecido"

processar({:ok, "resultado"})   #=> "sucesso: resultado"
processar({:error, "falhou"})   #=> "erro: falhou"
processar(:outro)               #=> "desconhecido"
```

### case — match com múltiplas cláusulas

```elixir
# Do projeto real — create_organization.ex
case repository.add(repository_pid, organization) do
  {:ok, org} ->
    Logger.info("Organization created successfully", ...)
    {:ok, org}

  {:error, reason} = error ->
    Logger.error("Failed to create organization", reason: reason)
    error
end
```

### Guards — condições nas cláusulas

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

def new(_name, _tribes) do
  {:error, :invalid_tribes}
end
```

Guards built-in mais usados:

```elixir
is_binary(x)    # é string?
is_integer(x)   # é inteiro?
is_list(x)      # é lista?
is_map(x)       # é map?
is_atom(x)      # é atom?
is_nil(x)       # é nil?
is_pid(x)       # é PID de processo?
byte_size(x)    # tamanho em bytes (para strings em guards)
length(x)       # tamanho de lista
```

### with — encadeamento de happy path

```elixir
# Problema sem with — "pyramid of doom"
case CreateOrganizationCommand.new(name) do
  {:ok, cmd} ->
    case Organization.new(cmd.name) do
      org ->
        case repository.add(pid, org) do
          {:ok, saved} -> {:ok, saved}
          {:error, r}  -> {:error, r}
        end
    end
  {:error, reason} -> {:error, reason}
end

# Com with — linear e limpo
with {:ok, cmd} <- CreateOrganizationCommand.new(name),
     {:ok, org} <- repository.add(pid, Organization.new(cmd.name)) do
  {:ok, org}
else
  {:error, :invalid_name} -> {:error, "nome inválido"}
  {:error, reason}        -> {:error, reason}
end
# Se qualquer <- falhar, cai no else (ou propaga se não houver else)
```

---

## 2.4 Structs, @type e @spec (12 min)

### Structs — maps tipados e nomeados

```elixir
defmodule KanbanVisionApi.Domain.Tribe do
  defstruct [:id, :audit, :name, :squads]
  # ↑ define os campos permitidos; campos não listados são inválidos
end

# Criando
tribe = %Tribe{id: "uuid", name: "Backend", squads: [], audit: Audit.new()}

# Acessando
tribe.name      #=> "Backend"
tribe.squads    #=> []

# "Atualizando" — retorna NOVO struct
tribe2 = %{tribe | name: "Frontend"}
tribe.name   #=> "Backend"   # original intacto — imutável!
tribe2.name  #=> "Frontend"  # nova referência

# Verificação de tipo
is_struct(tribe, Tribe)   #=> true
is_struct(tribe, Squad)   #=> false
```

### @enforce_keys — campos obrigatórios

```elixir
defmodule CreateOrganizationCommand do
  @enforce_keys [:name]          # lança erro se :name não for passado
  defstruct [:name, tribes: []]  # :tribes tem default []

  # Criar sem :name → ** (ArgumentError) the following keys must also be given...
  # %CreateOrganizationCommand{tribes: []}     # ERRO
  # %CreateOrganizationCommand{name: "Acme"}   # OK
end
```

### @type — documentação de tipos para Dialyzer

```elixir
defmodule KanbanVisionApi.Domain.Organization do
  alias KanbanVisionApi.Domain.{Audit, Tribe}

  defstruct [:id, :audit, :name, :tribes]

  @type t :: %__MODULE__{       # t() é o tipo canônico do próprio módulo
    id:     String.t(),         # String.t() = tipo da stdlib Elixir
    audit:  Audit.t(),          # Audit.t() = tipo definido em Audit
    name:   String.t(),
    tribes: [Tribe.t()]         # lista de Tribe.t()
  }
end

# Em outros módulos você usa Organization.t() para referenciar o tipo
```

### @spec — contrato de funções

```elixir
defmodule CreateOrganizationCommand do
  @type t :: %__MODULE__{name: String.t(), tribes: list()}

  # @spec nome_da_função(tipos_dos_args) :: tipo_do_retorno
  @spec new(String.t(), list()) :: {:ok, t()} | {:error, atom()}
  def new(name, tribes \\ [])

  def new(name, tribes) when is_binary(name) and byte_size(name) > 0 do
    {:ok, %__MODULE__{name: name, tribes: tribes}}
  end

  def new(_name, _tribes), do: {:error, :invalid_name}
end
```

**Por que usar `@spec`?**

```
1. Documentação: quem lê sabe exatamente o que entra e o que sai
2. Dialyzer: ferramenta de análise estática usa @spec para encontrar
   bugs antes de rodar o programa
3. IDE: autocompletion funciona melhor com specs definidas
```

---

## 2.5 Imutabilidade (8 min)

**Toda estrutura de dados em Elixir é imutável.** Isso não é uma limitação — é uma garantia de segurança, especialmente em sistemas concorrentes.

### Como funciona na prática

```elixir
# Listas
lista = [1, 2, 3]
nova_lista = [0 | lista]      # cria nova lista com 0 na frente
lista        #=> [1, 2, 3]    # original intacta
nova_lista   #=> [0, 1, 2, 3] # nova referência

# Maps
org = %{nome: "Acme", ativo: true}
org_nova = %{org | ativo: false}
org.ativo      #=> true    # original
org_nova.ativo #=> false   # novo

# Structs — mesmo comportamento
org = Organization.new("Acme")
org2 = %{org | name: "Acme Corp"}
org.name   #=> "Acme"      # original
org2.name  #=> "Acme Corp" # novo
```

### Por que isso importa para concorrência

```elixir
# Imagine dois processos acessando a mesma organização ao mesmo tempo:

# Processo A recebe uma cópia da org → nome = "Acme"
# Processo B "muda" a org → cria nova org com nome = "Acme Corp"

# Em linguagem com estado mutável:
# Processo A ainda tem referência → vê nome = "Acme Corp" ← race condition!

# Em Elixir:
# Processo A tem sua cópia imutável → sempre vê "Acme"
# Processo B criou nova estrutura → não afeta A

# Thread-safe por design, sem locks ou mutex
```

### Structural sharing — sem cópia desnecessária

A BEAM é inteligente: não copia dados desnecessariamente.

```elixir
lista = [1, 2, 3, 4, 5]
nova  = [0 | lista]
# nova = [0, →[1, 2, 3, 4, 5]]
#              ↑ aponta para a mesma memória que lista
# Apenas o nó 0 é novo — o resto é compartilhado
```

### Onde vive o estado mutável?

Se tudo é imutável, como o sistema "guarda" dados?

```
Estado mutável fica em processos OTP (Agent, GenServer).
O processo é o guardião do estado.
Cada mensagem recebida pode retornar um novo estado.
A imutabilidade garante que o estado antigo não "vaza" para fora.
```

```elixir
# O Agent guarda o estado:
{:ok, pid} = Agent.start_link(fn -> %{} end)

# Você "atualiza" enviando uma função que retorna o NOVO estado
Agent.update(pid, fn estado_atual ->
  Map.put(estado_atual, :chave, "valor")
  # ↑ retorna novo map — o estado_atual original não é mutado
end)
```

---

## 2.6 Enum — processando coleções (7 min)

```elixir
# map — transforma cada elemento
Enum.map([1, 2, 3], fn x -> x * 2 end)   #=> [2, 4, 6]
Enum.map([1, 2, 3], &(&1 * 2))            #=> [2, 4, 6]  (shorthand)

# filter — mantém elementos que satisfazem a condição
Enum.filter([1, 2, 3, 4], fn x -> rem(x, 2) == 0 end)  #=> [2, 4]
Enum.filter([1, 2, 3, 4], &(rem(&1, 2) == 0))            #=> [2, 4]

# reduce — acumula um resultado
Enum.reduce([1, 2, 3, 4], 0, fn x, acc -> acc + x end)  #=> 10
Enum.reduce([1, 2, 3, 4], 0, &+/2)  #=> 10  (shorthand)

# find — primeiro que satisfaz
Enum.find([1, 2, 3], fn x -> x > 2 end)   #=> 3

# any? / all?
Enum.any?([1, 2, 3], &(&1 > 2))    #=> true
Enum.all?([1, 2, 3], &(&1 > 0))    #=> true

# Comum no projeto: processar coleções de entidades
orgs
|> Enum.filter(& &1.name != "")
|> Enum.map(& &1.id)
|> Enum.sort()
```

---

## Resumo do Módulo 2

| Conceito | Sintaxe |
|---------|---------|
| Atom | `:ok`, `:error`, `nil`, `true` |
| Tupla de status | `{:ok, valor}` / `{:error, motivo}` |
| Pattern matching | `{:ok, x} = resultado` |
| Cláusulas de função | `def f({:ok, x}), do:` / `def f({:error, _}), do:` |
| Guards | `when is_binary(x) and byte_size(x) > 0` |
| Happy path | `with {:ok, x} <- f(), do: x` |
| Struct | `defstruct [:campo1, campo2: default]` |
| Tipo | `@type t :: %__MODULE__{...}` |
| Contrato | `@spec f(String.t()) :: {:ok, t()} \| {:error, atom()}` |
| Imutabilidade | `%{struct \| campo: novo}` retorna novo struct |
| Coleções | `Enum.map/filter/reduce/find` |

> **Próximo módulo:** OTP — como Elixir gerencia estado e concorrência com Agents, GenServer e Supervisor.
