///|
/// moon-agent ReAct agent demo.
///
/// This example demonstrates:
/// 1. Defining a Tool via the `Tool` trait
/// 2. Registering it into a mizchi/llm ToolRegistry
/// 3. Running an AgentExecutor with the tool
///
/// The example tool is a simple "echo" tool that returns its input.
/// In a real application, you would implement tools that fetch data,
/// call APIs, query databases, etc.
///
/// Run with:
///   $env:OPENAI_API_KEY = "sk-..."
///   moon run examples/react_agent

///|
/// EchoTool: a minimal Tool implementation for demonstration.
/// Returns the input as a JSON string.
struct EchoTool {
  prefix : String
}

///|
fn EchoTool::new(prefix : String) -> EchoTool {
  { prefix, }
}

///|
impl @tools.Tool for EchoTool with fn name(_self : EchoTool) -> String {
  "echo"
}

///|
impl @tools.Tool for EchoTool with fn description(_self : EchoTool) -> String {
  "Echo back the input message. Useful for testing tool calling."
}

///|
impl @tools.Tool for EchoTool with fn args_schema(_self : EchoTool) -> Json {
  let props : Map[String, Json] = Map([])
  props["message"] = Json::object(
    Map([
      ("type", Json::string("string")),
      ("description", Json::string("The message to echo back.")),
    ]),
  )
  let schema : Map[String, Json] = Map([
    ("type", Json::string("object")),
    ("properties", Json::object(props)),
    ("required", Json::array([Json::string("message")])),
  ])
  Json::object(schema)
}

///|
impl @tools.Tool for EchoTool with fn run(self : EchoTool, input : Json) -> String {
  let msg = match input {
    Json::Object(map) =>
      match map.get("message") {
        Some(Json::String(s)) => s
        _ => "<no message field>"
      }
    _ => "<input is not an object>"
  }
  self.prefix + msg
}

///|
fn main {
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  match api_key {
    Some(key) => {
      let model = @openai.OpenAIProvider::new(key)
      // Build a tool registry with our EchoTool
      let registry = @llm_tools.ToolRegistry::new()
      @tools.register_into(registry, EchoTool::new("Echo: "))
      // Create the agent executor
      let executor = @agents.AgentExecutor::new(
          @llm.BoxedProvider::new(model),
          registry,
        )
        |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
        |> @agents.AgentExecutor::with_max_steps(5)
      // Run a query that should trigger the echo tool
      let result = executor.invoke(
        "Use the echo tool to repeat: Hello, moon-agent!",
      )
      println("\nAgent result:")
      println(result)
    }
    None =>
      println(
        "Please set OPENAI_API_KEY environment variable to run the agent demo.",
      )
  }
}
