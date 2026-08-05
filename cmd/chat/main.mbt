///|
/// moon-agent chat — interactive AI assistant in the terminal.
///
/// Configuration:
///   Create `.env` at project root (see `.env.example`):
///     OPENAI_API_KEY=sk-...
///     OPENAI_BASE_URL=https://api.deepseek.com
///     OPENAI_MODEL=deepseek-chat
///
/// Usage:
///   moon run cmd/chat --target js
///     → interactive REPL mode (default)
///
///   $env:MOON_AGENT_INPUT = "What is 15 * 23 + 100?"
///   moon run cmd/chat --target js
///     → single-question mode (legacy)
///
///   $env:MOON_AGENT_LIST_TOOLS = "1"
///   moon run cmd/chat --target js
///     → list all registered tools
///
/// REPL commands:
///   /exit, /quit    — exit
///   /help           — show commands
///   /tools          — list registered tools
///   /clear          — clear conversation memory
///   /usage          — show accumulated token usage & cost
///   /trace          — show last turn's decision trail
///   /errors         — show structured error log
///
/// Built-in tools: calculator, get_current_time (2 in REPL)

///|
fn main {
  let config = @config.load_config_or_abort()

  // Legacy env-var modes (backward compatible)
  let list_tools = @env.get_env_var("MOON_AGENT_LIST_TOOLS")
  match list_tools {
    Some(_) => {
      list_all_tools()
      return
    }
    None => ()
  }
  let user_input = @env.get_env_var("MOON_AGENT_INPUT")
  match user_input {
    Some(input) => {
      println("=== moon-agent chat v0.3.1 ===")
      println("Endpoint: " + config.base_url + " | Model: " + config.model)
      println("")
      let provider = build_provider(config)
      let registry = build_registry()
      chat_turn(
        provider,
        registry,
        @memory.BufferMemory::new(),
        @observability.UsageTracker::new(),
        @observability.CallTrace::new(),
        @observability.ErrorLogger::new(),
        input,
      )
      return
    }
    None => ()
  }

  // REPL mode (default)
  repl(config)
}

///|
fn build_provider(config : @config.ChatConfig) -> @llm.BoxedProvider {
  let provider = @openai.OpenAIProvider::new_compat(
    config.base_url,
    config.model,
    api_key=config.api_key,
    max_tokens=config.max_tokens,
    system_prompt=config.system_prompt,
  )
  @llm.BoxedProvider::new(provider)
}

///|
fn build_registry() -> @llm_tools.ToolRegistry {
  let registry = @llm_tools.ToolRegistry::new()
  @tools.register_into(registry, @tools.CalculatorTool::new())
  @tools.register_into(registry, @tools.DateTimeTool::new())
  registry
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
  println("Configure via .env (see .env.example) or config.json.")
}

///|
fn repl(config : @config.ChatConfig) -> Unit {
  println("=== moon-agent chat v0.3.1 ===")
  println("Endpoint: " + config.base_url + " | Model: " + config.model)
  println("Type /help for commands, /exit to quit")
  println("")

  let provider = build_provider(config)
  let registry = build_registry()
  let memory = @memory.BufferMemory::new()
  let usage = @observability.UsageTracker::new()
  let error_logger = @observability.ErrorLogger::new()

  while true {
    print("You: ")
    let line = read_line()
    if line == "" {
      continue
    }
    let trimmed : String = line.trim().to_owned()
    if trimmed == "" {
      continue
    }

    // Commands
    if trimmed == "/exit" || trimmed == "/quit" {
      println("")
      println(usage.format())
      if error_logger.total_errors() > 0 {
        println(error_logger.format())
      }
      println("Goodbye!")
      break
    }
    if trimmed == "/help" {
      show_repl_help()
      continue
    }
    if trimmed == "/tools" {
      list_all_tools()
      continue
    }
    if trimmed == "/clear" {
      memory.clear()
      println("[Memory cleared]")
      continue
    }
    if trimmed == "/usage" {
      println(usage.format())
      continue
    }
    if trimmed == "/errors" {
      println(error_logger.format())
      continue
    }

    // Chat turn
    let trace = @observability.CallTrace::new()
    if trimmed == "/trace" {
      // /trace alone: show last trace (stored from previous turn)
      println("(no previous turn to trace)")
      continue
    }
    chat_turn(provider, registry, memory, usage, trace, error_logger, trimmed)
    println("")
  }
}

///|
fn show_repl_help() -> Unit {
  println("Commands:")
  println("  /exit, /quit    Exit the chat")
  println("  /help           Show this help")
  println("  /tools          List registered tools")
  println("  /clear          Clear conversation memory")
  println("  /usage          Show token usage & cost")
  println("  /errors         Show structured error log")
  println("")
  println("Anything else is sent to the AI agent.")
  println("Built-in tools: calculator, get_current_time")
}

///|
/// Run a single chat turn with memory persistence, event visibility,
/// and observability (token usage + call trace + error logging).
fn chat_turn(
  provider : @llm.BoxedProvider,
  registry : @llm_tools.ToolRegistry,
  memory : @memory.BufferMemory,
  usage : @observability.UsageTracker,
  trace : @observability.CallTrace,
  error_logger : @observability.ErrorLogger,
  question : String,
) -> Unit {
  // Build messages from memory (preserves conversation history)
  let messages = memory.load_messages()
  let user_msg = @llm.Message::user(question)
  messages.push(user_msg)

  println("Agent: ")
  // Use cell arrays for closure-captured mutable state
  let has_output : Array[Bool] = [false]
  let response_text : Array[String] = [""]

  // Run agent loop with observability hooks
  @llm.run_agent(
    provider,
    registry,
    messages,
    @llm.StopCondition::MaxSteps(8),
    fn(event : @llm.AgentEvent) -> Unit {
      usage.record(event)
      trace.record(event)
      match event {
        @llm.AgentEvent::Stream(e) =>
          match e {
            @llm.StreamEvent::TextDelta(s) => {
              print(s)
              has_output[0] = true
              response_text[0] = response_text[0] + s
            }
            @llm.StreamEvent::Error(msg) => {
              println("\n  [API Error] " + msg)
              error_logger.log_api_error(msg, "Agent stream error")
            }
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
          if is_error {
            error_logger.log_tool_error(name, result)
          }
        }
        _ => ()
      }
    },
  )

  // Flush final newline if there was output
  if has_output[0] {
    println("")
  }

  // Save to memory: user message + assistant response
  memory.save_message(user_msg)
  if response_text[0] != "" {
    memory.save_message(@llm.Message::assistant(response_text[0]))
  }

  // Show token stats
  if usage.total_tokens() > 0 {
    println(usage.format())
  }
}
