defmodule JS.JSParser do
  @moduledoc """
  Parser AST para JavaScript usando Node.js via Port
  """

  @ast_app_root Path.expand("../..", __DIR__)

  def parse(javascript_code) do
    parser_path = Path.join(@ast_app_root, "js_parser.js")
    port = Port.open(
      {:spawn, "node #{parser_path}"},
      [:binary, :exit_status, {:cd, @ast_app_root}]
    )
    Port.command(port, javascript_code)

    collect_port_data(port, "")
  end

  defp collect_port_data(port, acc) do
    receive do
      {^port, {:data, data}} ->
        collect_port_data(port, acc <> data)
      {^port, {:exit_status, 0}} ->
        Jason.decode(acc)
      {^port, {:exit_status, status}} ->
        {:error, {:exit_status, status}} 
    after 5000 ->
      Port.close(port)
      {:error, :timeout}
    end
  end
end
