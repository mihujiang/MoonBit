///|
/// moon-agent chat — interactive AI assistant in the terminal.
///
/// Usage:
///   $env:OPENAI_API_KEY = "sk-..."
///   $env:MOON_AGENT_INPUT = "What is 15 * 23 + 100?"
///   moon run cmd/chat --target js
///
/// Without MOON_AGENT_INPUT, runs demo mode with built-in questions.
/// With MOON_AGENT_LIST_TOOLS=1, lists all available tools.
///
/// Built-in tools: calculator, datetime, http_request, read_file,
/// write_file, shell_exec (6 total)

///|
fn main {
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  match api_key {
    None => {
      println("Error: OPENAI_API_KEY not set.")
      println("Run: `$env:OPENAI_API_KEY = \"sk-...\"`")
    }
    Some(key) => {
      let list_tools = @env.get_env_var("MOON_AGENT_LIST_TOOLS")
      match list_tools {
        Some(_) => {
          println("=== moon-agent built-in tools ===")
          println("  [calculator]       integer arithmetic (+, -, *, /)")
          println("  [get_current_time] current ISO-8601 timestamp")
          println("  [http_request]     HTTP GET/POST requests")
          println("  [read_file]        read local file contents")
          println("  [write_file]       write content to a file")
          println("  [shell_exec]       execute system commands (sandboxed)")
          println("")
          println(
            "Middleware: ToolGuard (allowlist/denylist), RetryTool, with_retry",
          )
        }
        None => {
          let user_input = @env.get_env_var("MOON_AGENT_INPUT")
          match user_input {
            Some(input) => chat_once(key, input)
            None => run_demo(key)
          }
        }
      }
    }
  }
}

///|
fn run_demo(key : String) -> Unit {
  println("=== moon-agent chat v0.8.0 ===\n")
  println("Demo 1: Math (CalculatorTool)")
  chat_once(key, "Calculate 15 * 23 + 100, just give me the numeric result.")
  println("")
  println("Demo 2: Time (DateTimeTool)")
  chat_once(
    key, "What is the current date and time? Use the get_current_time tool.",
  )
  println("")
  println("---")
  println("Set MOON_AGENT_INPUT env var for custom questions:")
  println("  $env:MOON_AGENT_INPUT = \"your question\"")
  println("List tools:")
  println("  $env:MOON_AGENT_LIST_TOOLS = 1")
}

///|
fn chat_once(key : String, question : String) -> Unit {
  let model = @openai.OpenAIProvider::new(key)
  let provider = @llm.BoxedProvider::new(model)

  // Build tool registry with available tools
  let registry = @llm_tools.ToolRegistry::new()
  @tools.register_into(registry, @tools.CalculatorTool::new())
  @tools.register_into(registry, @tools.DateTimeTool::new())

  // Create agent with memory
  let executor = @agents.AgentExecutor::new(provider, registry)
    |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
    |> @agents.AgentExecutor::with_max_steps(8)

  println("You: " + question)
  println("Agent: ")
  let _result = executor.invoke_stream(question, fn(delta) { println(delta) })
  println("")
}
