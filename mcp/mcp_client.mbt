///|
/// MCP Client implementation.
///
/// MCPClient communicates with an MCP server through an injectable
/// transport callback. This design (same pattern as HttpTool) keeps
/// the client cross-target compatible without depending on specific
/// I/O libraries.
///
/// The transport callback receives a JSON-RPC request string and
/// returns the response string. On native it could use subprocess
/// stdio (e.g. via @process); on JS it could use child_process or
/// a WebSocket to an HTTP+SSE endpoint.
///
/// Example (conceptual):
/// ```moonbit nocheck
/// let client = MCPClient::new(fn(request) {
///   // Send request to MCP server via stdio/subprocess
///   // Return the JSON response string
/// })
/// client.initialize()
/// let tools = client.list_tools()
/// for tool in tools {
///   println(tool.name)
/// }
/// ```
pub struct MCPClient {
  transport : (String) -> String
  mut next_id : Int
}

///|
pub fn MCPClient::new(transport : (String) -> String) -> MCPClient {
  { transport, next_id: 1 }
}

///|
/// Send a request and get the parsed result JSON.
fn MCPClient::send_request(
  self : MCPClient,
  request : MCPRequest,
) -> Result[Json, String] {
  let json_str = request.to_json()
  let response_str = (self.transport)(json_str)
  parse_response(response_str)
}

///|
/// Initialize the MCP connection. Returns the server capabilities.
pub fn MCPClient::initialize(self : MCPClient) -> Result[Json, String] {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request = initialize_request(id)
  self.send_request(request)
}

///|
/// List tools available on the MCP server. Returns tool definitions.
pub fn MCPClient::list_tools(
  self : MCPClient,
) -> Result[Array[MCPToolDef], String] {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request = list_tools_request(id)
  let result = self.send_request(request)
  match result {
    Ok(json) => parse_tool_list(json)
    Err(e) => Err(e)
  }
}

///|
/// Call a tool on the MCP server. Returns the tool's result as raw JSON.
pub fn MCPClient::call_tool(
  self : MCPClient,
  tool_name : String,
  arguments : Json,
) -> Result[Json, String] {
  let id = self.next_id
  self.next_id = self.next_id + 1
  let request = call_tool_request(id, tool_name, arguments)
  self.send_request(request)
}

///|
/// Build a bridge factory function for a specific tool name.
///
/// Returns a `(Json) -> String` callback that calls the MCP tool via
/// this client's transport. This is designed for one-tool-per-client
/// usage. For multi-tool servers, pass the transport to each bridge
/// individually.
///
/// Example:
/// ```moonbit nocheck
/// let call_fn = client.bridge_for("read_file")
/// let bridge = MCPToolBridge::new("read_file", "Read a file", schema, call_fn)
/// @tools.register_into(registry, bridge)
/// ```
pub fn MCPClient::bridge_for(
  self : MCPClient,
  tool_name : String,
) -> (Json) -> String {
  fn(input : Json) -> String {
    match self.call_tool(tool_name, input) {
      Ok(json) => json.stringify()
      Err(msg) => "Error: MCP tool call failed: " + msg
    }
  }
}
