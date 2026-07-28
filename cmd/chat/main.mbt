///|
/// moon-agent chat — interactive AI assistant in the terminal.
///
/// Configuration:
///   Create `config.json` at project root (see `config.example.json`):
///   ```json
///   {
///     "api_key": "sk-...",
///     "base_url": "https://api.deepseek.com",
///     "model": "deepseek-chat"
///   }
///   ```
///   Or set env vars: OPENAI_API_KEY, OPENAI_BASE_URL (optional), OPENAI_MODEL (optional)
///
/// Usage:
///   moon run cmd/chat --target js
///     → demo mode (built-in questions showcasing tools)
///
///   $env:MOON_AGENT_INPUT = "What is 15 * 23 + 100?"
///   moon run cmd/chat --target js
///     → single-question mode
///
///   $env:MOON_AGENT_LIST_TOOLS = "1"
///   moon run cmd/chat --target js
///     → list all registered tools
///
/// Built-in tools: calculator, get_current_time, http_request, read_file,
/// write_file, shell_exec (6 total)

///|
fn main {
  // Load config from config.json or env vars
  let config = @config.load_config_or_abort()

  let list_tools = @env.get_env_var("MOON_AGENT_LIST_TOOLS")
  match list_tools {
    Some(_) => list_all_tools()
    None => {
      let user_input = @env.get_env_var("MOON_AGENT_INPUT")
      match user_input {
        Some(input) => {
          println("=== moon-agent chat v0.9.0 ===")
          println("Endpoint: " + config.base_url + " | Model: " + config.model)
          println("")
          chat_once(config, input)
        }
        None => run_demo(config)
      }
    }
  }
}

///|
fn list_all_tools() -> Unit {
  println("=== moon-agent built-in tools ===")
  println("  [calculator]       integer arithmetic (+, -, *, /)")
  println("  [get_current_time] current ISO-8601 timestamp")
  println("  [http_request]     HTTP GET/POST requests")
  println("  [read_file]        read local file contents")
  println("  [write_file]       write content to a file")
  println("  [shell_exec]       execute system commands (sandboxed)")
  println("")
  println("Middleware: ToolGuard (allowlist/denylist), RetryTool, with_retry")
  println("")
  println("Configure via config.json (see config.example.json) or env vars.")
}

///|
fn run_demo(config : @config.ChatConfig) -> Unit {
  println("=== moon-agent chat v0.9.0 ===")
  println("Endpoint: " + config.base_url + " | Model: " + config.model)
  println("")

  println(">>> Demo 1: Math (CalculatorTool)")
  chat_once(config, "Calculate 15 * 23 + 100, just give me the numeric result.")
  println("")

  println(">>> Demo 2: Time (DateTimeTool)")
  chat_once(
    config, "What is the current date and time? Use the get_current_time tool.",
  )
  println("")

  println(">>> Demo 3: Multi-turn memory")
  chat_once(config, "My name is Alice. Remember it for the next turn.")
  println("")

  println("---")
  println("Set MOON_AGENT_INPUT env var for custom questions:")
  println("  $env:MOON_AGENT_INPUT = \"your question\"")
  println("List tools:")
  println("  $env:MOON_AGENT_LIST_TOOLS = 1")
}

///|
/// Run a single chat turn with full event visibility:
/// - TextDelta streamed to stdout as it arrives
/// - ToolExecute / ToolResult displayed with prefix markers
/// - Error events surfaced (no more silent failures)
/// - StepComplete / Done shown for debugging
fn chat_once(config : @config.ChatConfig, question : String) -> Unit {
  // Build provider from config (supports DeepSeek, OpenAI, any OpenAI-compatible endpoint)
  let provider = @openai.OpenAIProvider::new_compat(
    config.base_url,
    config.model,
    api_key=config.api_key,
    max_tokens=config.max_tokens,
    system_prompt=config.system_prompt,
  )
  let boxed = @llm.BoxedProvider::new(provider)

  // Build tool registry with all built-in tools
  let registry = @llm_tools.ToolRegistry::new()
  @tools.register_into(registry, @tools.CalculatorTool::new())
  @tools.register_into(registry, @tools.DateTimeTool::new())

  // Build messages (with optional system prompt from config)
  let messages : Array[@llm.Message] = []
  if !config.system_prompt.is_empty() {
    messages.push(@llm.Message::system(config.system_prompt))
  }
  let user_msg = @llm.Message::user(question)
  messages.push(user_msg)

  println("You: " + question)
  println("Agent: ")

  // Run agent loop with a verbose event handler
  @llm.run_agent(boxed, registry, messages, @llm.StopCondition::MaxSteps(8), fn(
    event : @llm.AgentEvent,
  ) -> Unit {
    match event {
      @llm.AgentEvent::Stream(e) =>
        match e {
          @llm.StreamEvent::TextDelta(s) => println(s)
          @llm.StreamEvent::Error(msg) => println("\n[API Error] " + msg)
          _ => ()
        }
      @llm.AgentEvent::ToolExecute(name~, input~) =>
        println(
          "\n  [→ calling tool: " + name + "] input: " + input.stringify(),
        )
      @llm.AgentEvent::ToolResult(name~, result~, is_error~) => {
        let preview = if result.length() > 100 {
          result[0:100].to_owned() + "..."
        } else {
          result
        }
        let tag = if is_error { " (ERROR)" } else { "" }
        println("  [← " + name + " result" + tag + "] " + preview)
      }
      @llm.AgentEvent::Done(reason~) => println("\n  [done: " + reason + "]")
      _ => ()
    }
  })
  println("")
}
