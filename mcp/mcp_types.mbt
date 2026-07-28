///|
/// MCP (Model Context Protocol) type definitions.
///
/// These model the core JSON-RPC 2.0 types used by MCP:
/// - Request: client → server call with id, rpc_method, params
/// - Response: server → client with result or error
///
/// MCP specific methods:
/// - initialize     — handshake, exchange capabilities
/// - tools/list     — list available tools on the server
/// - tools/call     — invoke a remote tool
/// - resources/list — list available resources
/// - resources/read — read a resource

///|
/// JSON-RPC request sent from client to server.
struct MCPRequest {
  jsonrpc : String
  id : Int
  rpc_method : String
  params : Json?
}

///|
/// MCP Tool definition returned by tools/list.
pub struct MCPToolDef {
  name : String
  description : String
  inputSchema : Json
}

///|
/// Create an initialize request.
pub fn initialize_request(id : Int) -> MCPRequest {
  let capabilities : Map[String, Json] = Map([])
  MCPRequest::{
    jsonrpc: "2.0",
    id,
    rpc_method: "initialize",
    params: Some(Json::object(capabilities)),
  }
}

///|
/// Create a tools/list request.
pub fn list_tools_request(id : Int) -> MCPRequest {
  MCPRequest::{ jsonrpc: "2.0", id, rpc_method: "tools/list", params: None }
}

///|
/// Create a tools/call request.
pub fn call_tool_request(
  id : Int,
  tool_name : String,
  arguments : Json,
) -> MCPRequest {
  let params : Map[String, Json] = Map([])
  params["name"] = Json::string(tool_name)
  params["arguments"] = arguments
  MCPRequest::{
    jsonrpc: "2.0",
    id,
    rpc_method: "tools/call",
    params: Some(Json::object(params)),
  }
}

///|
/// Serialize a request to JSON string for sending over transport.
pub fn MCPRequest::to_json(self : MCPRequest) -> String {
  let m : Map[String, Json] = Map([])
  m["jsonrpc"] = Json::string(self.jsonrpc)
  m["id"] = Json::number(Double::from_int(self.id))
  m["method"] = Json::string(self.rpc_method)
  match self.params {
    Some(p) => m["params"] = p
    None => ()
  }
  Json::object(m).stringify()
}

///|
/// Parse a JSON-RPC response from a string.
/// Returns the result value on success.
pub fn parse_response(text : String) -> Result[Json, String] {
  let json = @json.parse(text) catch {
    e => return Err("MCP response parse failed: " + e.to_string())
  }
  match json {
    Json::Object(map) =>
      match map.get("error") {
        Some(err) => {
          let msg = match err {
            Json::Object(em) =>
              match em.get("message") {
                Some(Json::String(s)) => s
                _ => "unknown error"
              }
            _ => "unknown error"
          }
          Err("MCP error: " + msg)
        }
        None =>
          match map.get("result") {
            Some(r) => Ok(r)
            None => Err("MCP response missing both result and error")
          }
      }
    _ => Err("MCP response is not a JSON object")
  }
}

///|
/// Parse tools/list result into an array of MCPToolDef.
pub fn parse_tool_list(result : Json) -> Result[Array[MCPToolDef], String] {
  match result {
    Json::Object(map) =>
      match map.get("tools") {
        Some(Json::Array(tools)) => {
          let defs : Array[MCPToolDef] = []
          for t in tools {
            match t {
              Json::Object(tm) => {
                let name = match tm.get("name") {
                  Some(Json::String(n)) => n
                  _ => continue
                }
                let description = match tm.get("description") {
                  Some(Json::String(d)) => d
                  _ => ""
                }
                let schema = match tm.get("inputSchema") {
                  Some(s) => s
                  None => {
                    let empty : Map[String, Json] = Map([])
                    Json::object(empty)
                  }
                }
                defs.push(MCPToolDef::{ name, description, inputSchema: schema })
              }
              _ => ()
            }
          }
          Ok(defs)
        }
        _ => Err("tools/list result missing 'tools' array")
      }
    _ => Err("tools/list result is not a JSON object")
  }
}
