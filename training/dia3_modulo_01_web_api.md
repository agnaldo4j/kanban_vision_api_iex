# Dia 3 — Módulo 1: Camada Web com Bandit e Plug

> Neste módulo vamos entender como o `web_api` foi construído:
> como o Elixir recebe requisições HTTP sem Phoenix, usando **Plug** como
> framework de composição e **Bandit** como servidor HTTP.
> Vamos ver cada peça do quebra-cabeça e entender *por que* cada decisão
> foi tomada dessa forma.

---

## 3.1 O Problema: Por Que Não Phoenix?

Phoenix é excelente — mas carrega um conjunto de abstrações voltadas para
aplicações web completas (templates, channels, LiveView, Ecto, etc.).

Para uma **API REST pura**, usar Phoenix seria trazer dependências que nunca
serão usadas. O projeto prefere **Plug direto + Bandit**, que são os próprios
blocos sobre os quais Phoenix é construído.

```
Phoenix  =  Plug  +  Bandit  +  Templates  +  LiveView  +  Ecto  +  ...
web_api  =  Plug  +  Bandit
```

**Vantagem:** menos dependências, startup mais rápido, superfície de ataque menor,
e o código fica mais explícito — sem mágica.

---

## 3.2 O Que É Plug?

**Plug** é uma especificação para compor módulos que transformam conexões HTTP.
Toda a stack web do Elixir é construída sobre ela.

### O contrato básico: `Plug.Conn`

Cada requisição HTTP é representada por uma `%Plug.Conn{}` — uma struct imutável
que carrega tudo sobre a requisição e a resposta em construção:

```elixir
%Plug.Conn{
  # Dados da requisição (vindos do cliente)
  method: "POST",           # "GET", "POST", "DELETE", ...
  request_path: "/api/v1/organizations",
  query_params: %{},        # ?name=Acme → %{"name" => "Acme"}
  body_params: %{},         # corpo JSON já parseado
  path_params: %{},         # /organizations/:id → %{"id" => "uuid..."}
  req_headers: [...],       # cabeçalhos HTTP da requisição

  # Dados da resposta (sendo construídos)
  status: nil,              # 200, 201, 404, ...
  resp_headers: [...],      # cabeçalhos HTTP da resposta
  resp_body: "",            # corpo da resposta

  # Metadados internos
  assigns: %{},             # mapa livre para passar dados entre plugs
  private: %{},             # metadados internos do framework
  halted: false             # true → pipeline interrompida
}
```

> **Princípio central:** um Plug recebe um `conn` e retorna um `conn` transformado.
> Nunca muta — sempre retorna um novo struct.

### Os dois tipos de Plug

**1. Plug como função** — o mais simples:

```elixir
def meu_plug(conn, _opts) do
  assign(conn, :usuario, "admin")
end
```

**2. Plug como módulo** — com `init/1` e `call/2`:

```elixir
defmodule MeuPlug do
  @behaviour Plug

  @impl true
  def init(opts), do: opts        # executado em tempo de compilação

  @impl true
  def call(conn, _opts) do        # executado a cada requisição
    assign(conn, :usuario, "admin")
  end
end
```

> `init/1` é chamado **uma vez** na inicialização (compile time ou startup).
> `call/2` é chamado **a cada requisição**. Coloque lógica cara em `init/1`.

---

## 3.3 Bandit — O Servidor HTTP

**Bandit** é um servidor HTTP puro em Elixir (implementa HTTP/1.1 e HTTP/2),
escrito para ser o servidor de referência do ecossistema Plug.

```elixir
# apps/web_api/mix.exs
defp deps do
  [
    {:bandit, "~> 1.0"},   # servidor HTTP
    {:plug, "~> 1.14"},    # especificação de composição
    {:jason, "~> 1.4"},    # codec JSON
    ...
  ]
end
```

**Por que Bandit e não Cowboy?**

| | Cowboy | Bandit |
|---|---|---|
| Linguagem | Erlang | Elixir |
| HTTP/2 | Plug-in | Nativo |
| Manutenção | Estável, legado | Ativo, moderno |
| Integração Plug | Via adapter | Nativa |

O Bandit é iniciado passando o módulo Router como o handler Plug:

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/application.ex
{Bandit, plug: KanbanVisionApi.WebApi.Router, port: 4000}
```

---

## 3.4 O Application — Ponto de Entrada OTP

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/application.ex
defmodule KanbanVisionApi.WebApi.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:web_api, :port, 4000)
    start_server = Application.get_env(:web_api, :start_server, true)

    children =
      if start_server do
        [{Bandit, plug: KanbanVisionApi.WebApi.Router, port: port}]
      else
        []
      end

    opts = [strategy: :one_for_one, name: KanbanVisionApi.WebApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Por que `start_server: false` em testes?

```elixir
# apps/web_api/config/test.exs
config :web_api, start_server: false
```

Em testes unitários de controllers, **não precisamos de um servidor HTTP real**.
Testamos o controller diretamente, passando um `%Plug.Conn{}` construído manualmente
(via `Plug.Test`). Subir um servidor real em testes seria mais lento e frágil.

```
Teste unitário:  Plug.Test.conn(:post, "/api/v1/organizations", body) → Router.call(conn, [])
Teste integração: HTTP real → localhost:4000 → Router → Controller
```

---

## 3.5 O Router — Pipeline de Plugs

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/router.ex
defmodule KanbanVisionApi.WebApi.Router do
  use Plug.Router

  plug CorrelationId          # 1. extrai/gera correlation_id
  plug RequestLogger          # 2. loga a requisição
  plug OpenApiSpex.Plug.PutApiSpec, module: Spec  # 3. carrega spec OpenAPI

  plug Plug.Parsers,          # 4. parseia o body
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason

  plug :fetch_query_params    # 5. parseia query string
  plug :match                 # 6. encontra a rota
  plug :dispatch              # 7. executa a ação

  get "/api/v1/organizations/search" do
    OrganizationController.call(conn, :search_by_name)
  end

  get "/api/v1/organizations/:id" do
    OrganizationController.call(conn, :get_by_id)
  end

  # ... demais rotas

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end
end
```

### Como a pipeline funciona

Cada `plug` na lista é executado em sequência. O `conn` transformado por um
plug é passado para o próximo:

```
Requisição HTTP
      │
      ▼
[1] CorrelationId.call(conn) → conn com correlation_id
      │
      ▼
[2] RequestLogger.call(conn) → conn + log de entrada
      │
      ▼
[3] PutApiSpec.call(conn)    → conn com spec cacheada
      │
      ▼
[4] Plug.Parsers.call(conn)  → conn com body_params parseados
      │
      ▼
[5] fetch_query_params(conn) → conn com query_params
      │
      ▼
[6] match(conn)              → identifica a rota
      │
      ▼
[7] dispatch(conn)           → executa o bloco da rota
      │
      ▼
OrganizationController.call(conn, :get_by_id)
      │
      ▼
Resposta HTTP enviada
```

### Por que `/search` antes de `/:id`?

```elixir
# CORRETO — específico antes do genérico
get "/api/v1/organizations/search" do ...end   # ← aparece primeiro
get "/api/v1/organizations/:id"    do ...end   # ← aparece depois

# ERRADO — /:id capturaria "search" como um ID
get "/api/v1/organizations/:id"    do ...end   # "search" vira id = "search"
get "/api/v1/organizations/search" do ...end   # nunca seria alcançado
```

O `Plug.Router` faz matching por **ordem de declaração** — a primeira rota que
bater com o padrão é a que executa.

---

## 3.6 Plugs Customizados

### CorrelationId — Rastreabilidade distribuída

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/plugs/correlation_id.ex
defmodule KanbanVisionApi.WebApi.Plugs.CorrelationId do
  import Plug.Conn

  @behaviour Plug

  @header "x-correlation-id"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    correlation_id =
      case get_req_header(conn, @header) do
        [id | _] -> id          # cliente enviou → reutiliza
        []       -> UUID.uuid4()  # não enviou → gera novo
      end

    Logger.metadata(correlation_id: correlation_id)

    conn
    |> assign(:correlation_id, correlation_id)      # disponível para outros plugs
    |> put_resp_header(@header, correlation_id)      # propaga na resposta
  end
end
```

**Por que isso é importante?**

Em sistemas distribuídos, uma requisição pode gerar chamadas para múltiplos
serviços. O `correlation_id` permite rastrear todos os logs de uma requisição,
mesmo que ela passe por vários serviços:

```
Cliente → web_api (X-Correlation-ID: abc-123)
              ↓ log com correlation_id: abc-123
         web_api → usecase → agent → ... (todos logar com abc-123)
              ↓
Cliente ← X-Correlation-ID: abc-123 (propagado na resposta)
```

### RequestLogger — Observabilidade de HTTP

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/plugs/request_logger.ex
defmodule KanbanVisionApi.WebApi.Plugs.RequestLogger do
  require Logger
  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    start_time = System.monotonic_time()              # captura tempo de início
    correlation_id = conn.assigns[:correlation_id]

    Logger.info("HTTP request received",              # log no início
      correlation_id: correlation_id,
      method: conn.method,
      path: conn.request_path
    )

    register_before_send(conn, fn conn ->             # callback antes do envio
      duration_ms =
        System.convert_time_unit(
          System.monotonic_time() - start_time,
          :native,
          :millisecond
        )

      Logger.info("HTTP response sent",               # log no fim, com duração
        correlation_id: correlation_id,
        method: conn.method,
        path: conn.request_path,
        status: conn.status,
        duration_ms: duration_ms
      )

      conn
    end)
  end
end
```

**`register_before_send/2`** é um mecanismo do Plug para registrar callbacks
que são executados **imediatamente antes** da resposta ser enviada ao cliente.
Isso permite medir o tempo real de processamento, incluindo toda a pipeline.

```
[inicio]  RequestLogger.call/2   → loga "request received"
          ... pipeline executa ...
          OrganizationController.call/2 → processa, chama use case
          ... conn.status = 201 ...
[fim]     register_before_send callback → loga "response sent" com status + duration_ms
          Bandit envia a resposta
```

---

## 3.7 Controllers — Adapters HTTP

O controller é um **adapter de entrada** (driving adapter) na arquitetura Hexagonal.
Sua única responsabilidade: **traduzir HTTP → Command/Query → chamar use case → HTTP**.

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/organizations/organization_controller.ex
defmodule KanbanVisionApi.WebApi.Organizations.OrganizationController do
  import Plug.Conn

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand
  alias KanbanVisionApi.WebApi.Organizations.OrganizationSerializer

  def call(conn, :create) do
    # 1. Extrai dados do HTTP
    name   = conn.body_params["name"]
    tribes = conn.body_params["tribes"] || []

    # 2. Traduz para Command (validação feita aqui)
    with {:ok, cmd} <- CreateOrganizationCommand.new(name, tribes),
         # 3. Chama o use case via Port
         {:ok, org} <- org_usecase().add(cmd, build_opts(conn)) do
      # 4. Serializa para JSON e responde
      respond(conn, 201, OrganizationSerializer.serialize(org))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :get_by_id) do
    id = conn.path_params["id"]   # /organizations/:id → "uuid-aqui"

    with {:ok, query} <- GetOrganizationByIdQuery.new(id),
         {:ok, org}   <- org_usecase().get_by_id(query, build_opts(conn)) do
      respond(conn, 200, OrganizationSerializer.serialize(org))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  def call(conn, :search_by_name) do
    name = conn.query_params["name"]   # ?name=Acme

    with {:ok, query} <- GetOrganizationByNameQuery.new(name),
         {:ok, orgs}  <- org_usecase().get_by_name(query, build_opts(conn)) do
      respond(conn, 200, OrganizationSerializer.serialize_many_list(orgs))
    else
      {:error, reason} -> respond_error(conn, reason)
    end
  end

  # Normaliza erros de aplicação e mapeia o status por código sem fazer parsing de texto
  defp respond_error(conn, reason) do
    error = ErrorMapper.normalize(reason)
    respond(conn, ErrorMapper.http_status(error), %{error: error.message})
  end
end
```

### O mapeamento de erros

Os command/query DTOs ainda podem retornar átomos de validação (`:invalid_name`),
mas os adapters externos devem trabalhar com erros estruturados:

```elixir
{:error, %{code: :not_found, message: "...", details: %{...}}}
```

O controller traduz isso para HTTP status codes usando `code`, sem depender do texto:

```
Erro estruturado   →   HTTP
:invalid_input     →   422 Unprocessable Entity
:not_found         →   404 Not Found
:conflict          →   409 Conflict
:internal_error    →   500 Internal Server Error
```

### O padrão `with` para pipelines de sucesso

```elixir
with {:ok, cmd} <- CreateOrganizationCommand.new(name, tribes),
     {:ok, org} <- org_usecase().add(cmd, build_opts(conn)) do
  respond(conn, 201, OrganizationSerializer.serialize(org))
else
  {:error, reason} -> respond_error(conn, reason)
end
```

O `with` executa cada cláusula em sequência. Se qualquer uma retornar `{:error, reason}`,
o bloco `else` é executado — sem necessidade de ifs aninhados.

---

## 3.8 Ports do web_api — Desacoplamento para Testes

O controller **não chama o GenServer diretamente**. Ele chama um Port:

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/ports/organization_usecase.ex
defmodule KanbanVisionApi.WebApi.Ports.OrganizationUsecase do
  @moduledoc """
  Port: define a interface do use case de Organization para a camada web.
  Desacopla o controller HTTP da implementação concreta do GenServer,
  permitindo testes com Mox.
  """

  alias KanbanVisionApi.Usecase.Organization.CreateOrganizationCommand

  @callback get_all(opts :: keyword()) :: {:ok, map()}
  @callback get_by_id(GetOrganizationByIdQuery.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}
  @callback add(CreateOrganizationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}
  @callback delete(DeleteOrganizationCommand.t(), opts :: keyword()) ::
              {:ok, any()} | {:error, String.t()}
end
```

### Por que um Port na camada web?

Sem o Port:
```elixir
# Controller chama GenServer diretamente — acoplado
KanbanVisionApi.Usecase.Organization.add(OrgUsecase, cmd, opts)
# Em testes: precisa subir o GenServer completo (Agent + supervisor + ...)
```

Com o Port:
```elixir
# Controller chama o Port — desacoplado
org_usecase().add(cmd, build_opts(conn))
# Em testes: injeta um mock Mox que implementa o Port
```

### O Adapter concreto — chamada real ao GenServer

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/adapters/organization_adapter.ex
defmodule KanbanVisionApi.WebApi.Adapters.OrganizationAdapter do
  @behaviour KanbanVisionApi.WebApi.Ports.OrganizationUsecase

  alias KanbanVisionApi.Usecase.Organization, as: OrgUsecase

  @impl true
  def get_all(opts), do: OrgUsecase.get_all(OrgUsecase, opts)

  @impl true
  def add(cmd, opts), do: OrgUsecase.add(OrgUsecase, cmd, opts)

  @impl true
  def delete(cmd, opts), do: OrgUsecase.delete(OrgUsecase, cmd, opts)
end
```

O adapter usa `OrgUsecase` como referência do GenServer (o módulo age como PID
de processo registrado por nome — `use GenServer` registra com `name: __MODULE__`
quando o Supervisor o inicia).

### Injeção via Application config

```elixir
# No controller
defp org_usecase do
  Application.get_env(
    :web_api,
    :organization_usecase,
    KanbanVisionApi.WebApi.Adapters.OrganizationAdapter  # default em prod
  )
end
```

```elixir
# Em testes (config/test.exs ou diretamente no teste)
config :web_api, :organization_usecase, MockOrganizationUsecase
```

```
Produção:  org_usecase() → OrganizationAdapter → GenServer → Agent
Testes:    org_usecase() → MockOrganizationUsecase (Mox) → resposta controlada
```

---

## 3.9 Serializers — Funções Puras de Conversão

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/organizations/organization_serializer.ex
defmodule KanbanVisionApi.WebApi.Organizations.OrganizationSerializer do
  alias KanbanVisionApi.Domain.Organization

  @spec serialize(Organization.t()) :: map()
  def serialize(%Organization{} = org) do
    %{
      id: org.id,
      name: org.name,
      tribes: Enum.map(org.tribes, &serialize_tribe/1),  # recursivo
      created_at: DateTime.to_iso8601(org.audit.created),
      updated_at: DateTime.to_iso8601(org.audit.updated)
    }
  end

  def serialize_many(organizations) when is_map(organizations) do
    organizations
    |> Map.values()        # %{uuid => %Organization{}} → [%Organization{}, ...]
    |> Enum.map(&serialize/1)
  end

  def serialize_many_list(organizations) when is_list(organizations) do
    Enum.map(organizations, &serialize/1)
  end

  # Serialização recursiva da hierarquia
  defp serialize_tribe(%Tribe{} = tribe) do
    %{id: tribe.id, name: tribe.name,
      squads: Enum.map(tribe.squads, &serialize_squad/1)}
  end

  defp serialize_squad(%Squad{} = squad) do
    %{id: squad.id, name: squad.name,
      workers: Enum.map(squad.workers, &serialize_worker/1)}
  end

  defp serialize_worker(%Worker{} = worker) do
    %{id: worker.id, name: worker.name,
      abilities: Enum.map(worker.abilities, &serialize_ability/1)}
  end

  defp serialize_ability(%Ability{} = ability) do
    %{id: ability.id, name: ability.name}
  end
end
```

**Por que serializers separados?**

Structs de domínio têm campos com `DateTime` e hierarquias aninhadas que
`Jason.encode!/1` não sabe serializar diretamente. O serializer:

1. Converte `DateTime` para ISO8601 string
2. Transforma structs (que Jason não conhece) em maps simples
3. Aplica a recursão na hierarquia (Organization → Tribe → Squad → Worker → Ability)
4. Mantém as funções de domínio **puras e sem acoplamento** ao formato HTTP

```elixir
# ERRO — Jason não sabe serializar %Organization{} com %DateTime{}
Jason.encode!(%Organization{})   # ** (Protocol.UndefinedError)

# CORRETO — serializa primeiro para map simples
Jason.encode!(OrganizationSerializer.serialize(org))   # ok
```

---

## 3.10 OpenAPI — Documentação como Código

O projeto usa `open_api_spex` para gerar documentação OpenAPI 3.0 a partir
de código Elixir — a documentação **nunca fica desatualizada** porque é o código.

```elixir
# apps/web_api/lib/kanban_vision_api/web_api/open_api/spec.ex
defmodule KanbanVisionApi.WebApi.OpenApi.Spec do
  @behaviour OpenApiSpex.OpenApi

  @impl OpenApiSpex.OpenApi
  def spec do
    %OpenApiSpex.OpenApi{
      openapi: "3.0.0",
      info: %OpenApiSpex.Info{title: "Kanban Vision API", version: "1.0.0"},
      paths: %{
        "/api/v1/organizations" => %OpenApiSpex.PathItem{
          get: %OpenApiSpex.Operation{
            summary: "List all organizations",
            operationId: "listOrganizations",
            tags: ["Organizations"],
            responses: %{
              200 => %OpenApiSpex.Response{
                description: "List of organizations",
                content: json_content(org_list_schema())
              }
            }
          },
          post: %OpenApiSpex.Operation{
            summary: "Create an organization",
            requestBody: %OpenApiSpex.RequestBody{
              required: true,
              content: json_content(%OpenApiSpex.Schema{
                type: :object,
                properties: %{name: %OpenApiSpex.Schema{type: :string}},
                required: [:name]
              })
            },
            responses: %{
              201 => ...,
              409 => ...,
              422 => ...
            }
          }
        }
      }
    }
  end
end
```

### As rotas de documentação no Router

```elixir
# Renderiza a spec em JSON (para ferramentas como Postman, client generators)
get "/api/openapi" do
  opts = OpenApiSpex.Plug.RenderSpec.init([])
  OpenApiSpex.Plug.RenderSpec.call(conn, opts)
end

# Renderiza a Swagger UI (interface visual interativa)
get "/api/swagger" do
  opts = OpenApiSpex.Plug.SwaggerUI.init(path: "/api/openapi")
  OpenApiSpex.Plug.SwaggerUI.call(conn, opts)
end
```

Após `mix run --no-halt` (ou `iex -S mix`), acesse:
- `http://localhost:4000/api/openapi` — spec JSON
- `http://localhost:4000/api/swagger` — Swagger UI interativo

---

## 3.11 Testando a Camada Web

### Testes de Controller com Plug.Test e Mox

```elixir
# apps/web_api/test/kanban_vision_api/web_api/organizations/
#   organization_controller_test.exs

defmodule KanbanVisionApi.WebApi.Organizations.OrganizationControllerTest do
  use ExUnit.Case, async: true

  import Plug.Test    # conn/3, init_test_session, etc.

  alias KanbanVisionApi.WebApi.Router

  # 1. Configura o mock Mox do usecase
  setup do
    Application.put_env(:web_api, :organization_usecase, MockOrganizationUsecase)
    :ok
  end

  describe "POST /api/v1/organizations" do
    test "cria organização com sucesso" do
      # Arrange — configura o mock para retornar uma org
      org = %{id: "uuid-1", name: "Acme", tribes: [], ...}
      MockOrganizationUsecase
      |> expect(:add, fn _cmd, _opts -> {:ok, org} end)

      # Act — simula uma requisição HTTP real
      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{name: "Acme"}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(Router.init([]))

      # Assert — verifica resposta HTTP
      assert conn.status == 201
      body = Jason.decode!(conn.resp_body)
      assert body["name"] == "Acme"
    end

    test "retorna 422 quando nome está ausente" do
      conn =
        :post
        |> conn("/api/v1/organizations", Jason.encode!(%{}))
        |> put_req_header("content-type", "application/json")
        |> Router.call(Router.init([]))

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "Invalid name"
    end
  end

  describe "GET /api/v1/organizations/:id" do
    test "retorna 404 quando não encontrado" do
      MockOrganizationUsecase
      |> expect(:get_by_id, fn _query, _opts ->
        {:error, %{code: :not_found, message: "Organization not found", details: %{}}}
      end)

      conn =
        :get
        |> conn("/api/v1/organizations/uuid-inexistente")
        |> Router.call(Router.init([]))

      assert conn.status == 404
    end
  end
end
```

### Testes de integração com servidor real

```elixir
# @moduletag :integration — excluídos por padrão, rodam com --only integration
defmodule KanbanVisionApi.WebApi.IntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  test "GET /api/v1/organizations retorna lista vazia" do
    {:ok, resp} = HTTPoison.get("http://localhost:4000/api/v1/organizations")
    assert resp.status_code == 200
    assert Jason.decode!(resp.body) == []
  end
end
```

---

## 3.12 Arquitetura Completa da Camada Web

```
                         HTTP Client
                              │
                              ▼
                    ┌─────────────────┐
                    │     Bandit      │  ← servidor HTTP (OTP process)
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     Router      │  ← Plug.Router + pipeline
                    │  (plug chain)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  CorrelationId  │  ← Plug: gera/propaga trace ID
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ RequestLogger   │  ← Plug: log estruturado
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Plug.Parsers   │  ← Plug: parseia JSON body
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Controller    │  ← Adapter: HTTP → Command/Query
                    │(OrganizationCtl)│
                    └────────┬────────┘
                             │  chama Port
                    ┌────────▼────────┐
                    │  Port (behaviour)│  ← OrganizationUsecase behaviour
                    └────────┬────────┘
                             │  implementado por
              ┌──────────────┴───────────────┐
              │                              │
   ┌──────────▼──────────┐       ┌───────────▼──────────┐
   │  OrganizationAdapter │       │  MockOrganizationUsecase │
   │  (produção)          │       │  (testes com Mox)    │
   └──────────┬───────────┘       └──────────────────────┘
              │
              ▼
   ┌─────────────────────┐
   │  GenServer (Usecase) │  ← KanbanVisionApi.Usecase.Organization
   └─────────────────────┘
```

---

## 3.13 Resumo dos Conceitos

| Conceito | O que é | No projeto |
|----------|---------|------------|
| `Plug.Conn` | Struct imutável representando req/resp HTTP | Passa por toda a pipeline |
| `Plug` | Módulo/função que transforma `conn` | `CorrelationId`, `RequestLogger`, `Parsers` |
| `Plug.Router` | Roteador baseado em padrão + pipeline | `Router` com `use Plug.Router` |
| Bandit | Servidor HTTP para Plug | Iniciado no `Application` como child |
| Controller | Adapter HTTP → Use Case | `OrganizationController`, `SimulationController` |
| Port (web) | Interface do use case para o controller | `OrganizationUsecase` behaviour |
| Adapter (web) | Implementação que chama o GenServer | `OrganizationAdapter` |
| Serializer | Converte structs de domínio para maps JSON | `OrganizationSerializer` |
| `register_before_send` | Callback executado antes do envio | `RequestLogger` usa para medir duração |
| `start_server: false` | Não sobe Bandit em testes | Configurado em `config/test.exs` |

### O fluxo completo resumido

```
HTTP POST /api/v1/organizations {"name": "Acme"}
  │
  ├─ Bandit recebe a conexão TCP
  ├─ CorrelationId: gera X-Correlation-ID: uuid-abc
  ├─ RequestLogger: loga "request received"
  ├─ Plug.Parsers: body_params = %{"name" => "Acme"}
  ├─ Router.match: casa com POST /api/v1/organizations
  ├─ OrganizationController.call(conn, :create)
  │    ├─ cmd = %CreateOrganizationCommand{name: "Acme"}
  │    ├─ org_usecase().add(cmd, opts)   ← Port
  │    │    └─ OrganizationAdapter.add  ← Adapter
  │    │         └─ OrgUsecase.add      ← GenServer
  │    └─ respond(conn, 201, serialize(org))
  ├─ register_before_send: loga "response sent" status=201 duration_ms=3
  └─ Bandit envia HTTP 201 {"id": "...", "name": "Acme", ...}
```

> **Próximo módulo:** Exercícios do Dia 3 — implementar novas rotas,
> escrever testes de controller com Mox e testar a documentação OpenAPI.
