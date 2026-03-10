defmodule AstraplexWeb.McpRouterTest do
  use AstraplexWeb.ConnCase

  @initialize_request %{
    "jsonrpc" => "2.0",
    "id" => 1,
    "method" => "initialize",
    "params" => %{
      "protocolVersion" => "2024-11-05",
      "capabilities" => %{},
      "clientInfo" => %{"name" => "test", "version" => "0.1.0"}
    }
  }

  describe "POST /mcp" do
    test "initialize returns a valid MCP response", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> post("/mcp", @initialize_request)

      assert %{"jsonrpc" => "2.0", "id" => 1, "result" => result} = json_response(conn, 200)
      assert %{"protocolVersion" => "2024-11-05"} = result
      assert %{"serverInfo" => %{"name" => _name}} = result
      assert %{"capabilities" => _capabilities} = result

      # Session ID header is returned
      assert [_session_id] = get_resp_header(conn, "mcp-session-id")
    end

    test "tools/list includes check_health tool", %{conn: conn} do
      # First initialize to get a session ID
      init_conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> post("/mcp", @initialize_request)

      [session_id] = get_resp_header(init_conn, "mcp-session-id")

      # Now list tools using the session
      tools_request = %{
        "jsonrpc" => "2.0",
        "id" => 2,
        "method" => "tools/list"
      }

      tools_conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> put_req_header("accept", "application/json")
        |> put_req_header("mcp-session-id", session_id)
        |> post("/mcp", tools_request)

      assert %{"jsonrpc" => "2.0", "id" => 2, "result" => %{"tools" => tools}} =
               json_response(tools_conn, 200)

      tool_names = Enum.map(tools, & &1["name"])
      assert "check_health" in tool_names
    end
  end
end
