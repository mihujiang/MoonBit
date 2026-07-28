///|
/// MCP Server — expose moon-agent tools as MCP services.
///
/// MCPServer implements the server side of the Model Context Protocol.
/// It accepts moon-agent Tool implementations and exposes them to any
/// MCP-compatible client (Claude Desktop, Cursor, etc.).
///
/// The request handling is pure — transport is injected via a callback
/// that receives the response JSON. This keeps the server cross-target.
///
/// Example (conceptual):
/// ```moonbit nocheck
/// let server = MCPServer::new("moon-agent-tools", "0.7.0")
/// server.register_tool(CalculatorTool::new())
/// server.register_tool(DateTimeTool::new())
/// server.handle_request(request_json, fn(response) {
///   // Send response back over transport (stdio/HTTP/etc.)
///   transport.send(response)
/// })
/// ```
pub struct MCPServer {
  name : String
  version : String
  tools : Array[MCPToolDef]
  tool_handlers : Map[String, (Json) -> String]
}

///|
pub fn MCPServer::new(name : String, version : String) -> MCPServer {
  { name, version, tools: [], tool_handlers: Map([]) }
}

///|
/// Register a moon-agent Tool with the MCP server. The tool becomes
/// discoverable by any MCP client that connects.
pub fn[T : @tools.Tool] MCPServer::register_tool(
  self : MCPServer,
  tool : T,
) -> MCPServer {
  let tool_name = tool.name()
  let def = MCPToolDef::{
    name: tool_name,
    description: tool.description(),
    inputSchema: tool.args_schema(),
  }
  self.tools.push(def)
  self.tool_handlers[tool_name] = fn(input : Json) -> String { tool.run(input) }
  self
}

///|
/// Handle an incoming JSON-RPC request string. Calls `on_response` with
/// the response JSON string to be sent back to the client.
pub fn MCPServer::handle_request(
  self : MCPServer,
  request_json : String,
  on_response : (String) -> Unit,
) -> Unit {
  let request = @json.parse(request_json) catch {
    _ => {
      on_response(error_response(0, -32700, "Parse error: invalid JSON"))
      return
    }
  }
  match request {
    Json::Object(map) => {
      let rpc_method = match map.get("method") {
        Some(Json::String(m)) => m
        _ => {
          on_response(
            error_response(0, -32600, "Invalid Request: missing method"),
          )
          return
        }
      }
      let id = match map.get("id") {
        Some(Json::Number(n, ..)) => n.to_int()
        _ => 0
      }
      let params = map.get("params")

      match rpc_method {
        "initialize" => {
          let capabilities : Map[String, Json] = Map([])
          let tools_cap : Map[String, Json] = Map([])
          // Use JSON false via parse as MoonBit Json has no Bool constructor
          tools_cap["listChanged"] = @json.parse("false") catch {
            _ => Json::string("false")
          }
          capabilities["tools"] = Json::object(tools_cap)
          let result : Map[String, Json] = Map([])
          result["protocolVersion"] = Json::string("2024-11-05")
          result["serverInfo"] = Json::object(
            {
              let info : Map[String, Json] = Map([])
              info["name"] = Json::string(self.name)
              info["version"] = Json::string(self.version)
              info
            },
          )
          result["capabilities"] = Json::object(capabilities)
          on_response(success_response(id, Json::object(result)))
        }
        "tools/list" => {
          let tools_json : Array[Json] = []
          for tool in self.tools {
            let t : Map[String, Json] = Map([])
            t["name"] = Json::string(tool.name)
            t["description"] = Json::string(tool.description)
            t["inputSchema"] = tool.inputSchema
            tools_json.push(Json::object(t))
          }
          on_response(
            success_response(
              id,
              {
                let r : Map[String, Json] = Map([])
                r["tools"] = Json::array(tools_json)
                Json::object(r)
              },
            ),
          )
        }
        "tools/call" =>
          match params {
            Some(p) =>
              match p {
                Json::Object(pmap) => {
                  let tool_name = match pmap.get("name") {
                    Some(Json::String(n)) => n
                    _ => {
                      on_response(
                        error_response(
                          id, -32602, "Invalid params: missing tool name",
                        ),
                      )
                      return
                    }
                  }
                  let arguments = match pmap.get("arguments") {
                    Some(a) => a
                    None => {
                      let empty : Map[String, Json] = Map([])
                      Json::object(empty)
                    }
                  }
                  match self.tool_handlers.get(tool_name) {
                    Some(handler) => {
                      let tool_result = handler(arguments)
                      let result : Map[String, Json] = Map([])
                      let content : Array[Json] = []
                      let c : Map[String, Json] = Map([])
                      c["type"] = Json::string("text")
                      c["text"] = Json::string(tool_result)
                      content.push(Json::object(c))
                      result["content"] = Json::array(content)
                      on_response(success_response(id, Json::object(result)))
                    }
                    None =>
                      on_response(
                        error_response(
                          id,
                          -32601,
                          "Tool not found: " + tool_name,
                        ),
                      )
                  }
                }
                _ =>
                  on_response(
                    error_response(id, -32602, "Invalid params: not an object"),
                  )
              }
            None =>
              on_response(
                error_response(id, -32602, "Invalid params: missing params"),
              )
          }
        _ =>
          on_response(
            error_response(id, -32601, "Method not found: " + rpc_method),
          )
      }
    }
    _ =>
      on_response(
        error_response(0, -32600, "Invalid Request: not a JSON object"),
      )
  }
}

///|
/// Build a success JSON-RPC response string.
fn success_response(id : Int, result : Json) -> String {
  let m : Map[String, Json] = Map([])
  m["jsonrpc"] = Json::string("2.0")
  m["id"] = Json::number(Double::from_int(id))
  m["result"] = result
  Json::object(m).stringify()
}

///|
/// Build an error JSON-RPC response string.
fn error_response(id : Int, code : Int, message : String) -> String {
  let m : Map[String, Json] = Map([])
  m["jsonrpc"] = Json::string("2.0")
  m["id"] = Json::number(Double::from_int(id))
  let err : Map[String, Json] = Map([])
  err["code"] = Json::number(Double::from_int(code))
  err["message"] = Json::string(message)
  m["error"] = Json::object(err)
  Json::object(m).stringify()
}

///|
/// Number of registered tools.
pub fn MCPServer::tool_count(self : MCPServer) -> Int {
  self.tools.length()
}
