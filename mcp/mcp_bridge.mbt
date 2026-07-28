///|
/// MCPToolBridge adapts an MCP tool to moon-agent's Tool trait.
///
/// This is the key bridge between MCP ecosystem tools and moon-agent's
/// agent runtime. Once bridged, any MCP tool can be used in AgentExecutor
/// exactly like a native tool.
///
/// Each MCPToolBridge holds the tool's metadata and a `call` callback
/// that invokes the remote tool. The callback is typically created
/// by `MCPClient::bridge_for`.
///
/// Example:
/// ```moonbit nocheck
/// let transport = fn(req) { @process.pipe("mcp-server", req) }
/// let client = MCPClient::new(transport)
/// client.initialize()
/// let tools = client.list_tools()
/// for def in tools {
///   let call_fn = client.bridge_for(def.name)
///   let bridge = MCPToolBridge::new(def.name, def.description, def.inputSchema, call_fn)
///   @tools.register_into(registry, bridge)
/// }
/// ```
pub struct MCPToolBridge {
  tool_name : String
  tool_description : String
  tool_schema : Json
  call : (Json) -> String
}

///|
pub fn MCPToolBridge::new(
  tool_name : String,
  tool_description : String,
  tool_schema : Json,
  call : (Json) -> String,
) -> MCPToolBridge {
  { tool_name, tool_description, tool_schema, call }
}

///|
pub impl @tools.Tool for MCPToolBridge with fn name(self : MCPToolBridge) -> String {
  "mcp_" + self.tool_name
}

///|
pub impl @tools.Tool for MCPToolBridge with fn description(self : MCPToolBridge) -> String {
  self.tool_description
}

///|
pub impl @tools.Tool for MCPToolBridge with fn args_schema(self : MCPToolBridge) -> Json {
  self.tool_schema
}

///|
pub impl @tools.Tool for MCPToolBridge with fn run(
  self : MCPToolBridge,
  input : Json,
) -> String {
  (self.call)(input)
}
