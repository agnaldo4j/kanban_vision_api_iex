defmodule JS.JSParser do
  @moduledoc """
  Parser AST para JavaScript usando Node.js via Port
  """

  def parse(javascript_code) do
    port = Port.open({:spawn, "node js_parser.js" }, [:binary])
    Port.command(port, javascript_code)

    receive do
      {^port, {:data, result}} ->
        Port.close(port)
        Jason.decode(result)
    after 5000 ->
      Port.close(port)
      {:error, :timeout}
    end
  end
end