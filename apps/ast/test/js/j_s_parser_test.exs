defmodule JS.JSParserTest do
  use ExUnit.Case, async: false

  # This module is tagged as :capture_log and :integration.
  # By default, :integration tests are excluded (see test_helper.exs).
  # Run with: `mix test --only integration` to include it.
  @moduletag :capture_log

  describe "parse/1" do
    test "returns {:ok, :json_ast} when Node script is available" do
      # Given: a simple JavaScript snippet
      js_code = "console.log('hello')"

      result = JS.JSParser.parse(js_code)

      assert result == {
               :ok,
               %{
                 "ast" => %{
                   "body" => [%{"end" => 20, "expression" => %{"arguments" => [%{"end" => 19, "raw" => "'hello'", "start" => 12, "type" => "Literal", "value" => "hello"}], "callee" => %{"computed" => false, "end" => 11, "object" => %{"end" => 7, "name" => "console", "start" => 0, "type" => "Identifier"}, "optional" => false, "property" => %{"end" => 11, "name" => "log", "start" => 8, "type" => "Identifier"}, "start" => 0, "type" => "MemberExpression"}, "end" => 20, "optional" => false, "start" => 0, "type" => "CallExpression"}, "start" => 0, "type" => "ExpressionStatement"}],
                   "end" => 20,
                   "sourceType" => "script",
                   "start" => 0,
                   "type" => "Program"
                 },
                 "parser" => "javascript"
               }
             }
    end
  end

  describe "parse/1 with TypeScript" do
    test "returns {:ok, map} with parser = 'typescript' and a SourceFile AST" do
      # Given: a simple TypeScript snippet that includes a type annotation
      ts_code = """
      interface User { id: number; name: string }
      const x: number = 1
      """

      # When
      result = JS.JSParser.parse(ts_code)

      # Then
      assert {:ok, parsed} = result
      assert is_map(parsed)

      assert parsed["parser"] == "typescript"

      ast = parsed["ast"]
      assert is_map(ast)
      assert ast["kind"] == "SourceFile"

      # Children should exist and be a list with at least one node
      assert is_list(ast["children"]) and length(ast["children"]) > 0
    end
  end
end

