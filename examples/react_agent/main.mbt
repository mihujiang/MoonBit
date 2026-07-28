///|
/// moon-agent ReAct agent demo with built-in tools.
///
/// This example demonstrates:
/// 1. Loading unified config from `config.json` or env vars
/// 2. Using built-in CalculatorTool for math
/// 3. Using built-in DateTimeTool for time queries
/// 4. Running an AgentExecutor with both tools and memory
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
/// Run with:
///   moon run examples/react_agent --target js
///
/// The agent can answer questions like:
///   "What is 15 * 23 + 100?" (uses CalculatorTool)
///   "What time is it now?" (uses DateTimeTool)
///   "Multiply 7 by 8 and tell me the answer"

///|
fn main {
  // Load config from config.json or env vars (unified with cmd/chat)
  let config = match @config.load_config() {
    Some(c) => c
    None => {
      println("Please configure API access first.")
      println(
        "Create `config.json` at project root (see `config.example.json`)",
      )
      println(
        "or set env vars: OPENAI_API_KEY, OPENAI_BASE_URL (optional), OPENAI_MODEL (optional)",
      )
      return
    }
  }

  // Build provider from config (supports DeepSeek, OpenAI, any OpenAI-compatible endpoint)
  let model = @openai.OpenAIProvider::new_compat(
    config.base_url,
    config.model,
    api_key=config.api_key,
    max_tokens=config.max_tokens,
    system_prompt=config.system_prompt,
  )
  let provider = @llm.BoxedProvider::new(model)

  // Build a tool registry with built-in tools
  let registry = @llm_tools.ToolRegistry::new()
  @tools.register_into(registry, @tools.CalculatorTool::new())
  @tools.register_into(registry, @tools.DateTimeTool::new())

  println("Endpoint: " + config.base_url + " | Model: " + config.model)
  println("")

  // Demo: ask a math question
  println("=== Demo 1: Calculator ===")
  let executor = @agents.AgentExecutor::new(provider, registry)
    |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
    |> @agents.AgentExecutor::with_max_steps(5)
  let result1 = executor.invoke(
    "What is 15 * 23 + 100? Please use the calculator tool.",
  )
  println("Agent: " + result1)

  // Demo: ask about time
  println("\n=== Demo 2: DateTime ===")
  let executor2 = @agents.AgentExecutor::new(provider, registry)
    |> @agents.AgentExecutor::with_max_steps(3)
  let result2 = executor2.invoke(
    "What is the current date and time? Use the get_current_time tool.",
  )
  println("Agent: " + result2)

  // Demo: multi-tool query
  println("\n=== Demo 3: Multi-tool ===")
  let executor3 = @agents.AgentExecutor::new(provider, registry)
    |> @agents.AgentExecutor::with_max_steps(8)
  let result3 = executor3.invoke(
    "First get the current time, then calculate 3600 / 60 (seconds per hour divided by minutes per hour). Tell me both results.",
  )
  println("Agent: " + result3)
}
