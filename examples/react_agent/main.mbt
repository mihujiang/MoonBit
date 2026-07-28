///|
/// moon-agent ReAct agent demo with built-in tools.
///
/// This example demonstrates:
/// 1. Using built-in CalculatorTool for math
/// 2. Using built-in DateTimeTool for time queries
/// 3. Running an AgentExecutor with both tools and memory
///
/// Run with:
///   $env:OPENAI_API_KEY = "sk-..."
///   moon run examples/react_agent --target js
///
/// The agent can answer questions like:
///   "What is 15 * 23 + 100?" (uses CalculatorTool)
///   "What time is it now?" (uses DateTimeTool)
///   "Multiply 7 by 8 and tell me the answer"

///|
fn main {
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  match api_key {
    Some(key) => {
      let model = @openai.OpenAIProvider::new(key)
      let provider = @llm.BoxedProvider::new(model)

      // Build a tool registry with built-in tools
      let registry = @llm_tools.ToolRegistry::new()
      @tools.register_into(registry, @tools.CalculatorTool::new())
      @tools.register_into(registry, @tools.DateTimeTool::new())

      // Create the agent executor with memory
      let executor = @agents.AgentExecutor::new(provider, registry)
        |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
        |> @agents.AgentExecutor::with_max_steps(5)

      // Demo: ask a math question
      println("=== Demo 1: Calculator ===")
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
    None =>
      println(
        "Please set OPENAI_API_KEY environment variable to run the agent demo.",
      )
  }
}
