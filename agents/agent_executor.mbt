///|
/// AgentExecutor runs an agent loop with tools, memory, and stop conditions.
///
/// This is a thin wrapper around mizchi/llm's `run_agent`, adding:
/// - Memory integration (load history before, save after)
/// - Sensible defaults (max 10 steps, stop on finish)
/// - A simple `invoke` entry point that takes a plain user string
///
/// For full ReAct-style agent with custom prompts, use the lower-level
/// `@llm.run_agent` directly.
pub struct AgentExecutor {
  provider : @llm.BoxedProvider
  tools : @llm_tools.ToolRegistry
  memory : @memory.BufferMemory?
  max_steps : Int
}

///|
/// Create a new AgentExecutor with the given provider and tool registry.
pub fn AgentExecutor::new(
  provider : @llm.BoxedProvider,
  tools : @llm_tools.ToolRegistry,
) -> AgentExecutor {
  { provider, tools, memory: None, max_steps: 10 }
}

///|
/// Attach a BufferMemory. History is loaded before invocation and
/// the new user input + final assistant reply are saved after.
pub fn AgentExecutor::with_memory(
  self : AgentExecutor,
  memory : @memory.BufferMemory,
) -> AgentExecutor {
  { ..self, memory: Some(memory) }
}

///|
/// Override the default max_steps (10).
pub fn AgentExecutor::with_max_steps(
  self : AgentExecutor,
  max_steps : Int,
) -> AgentExecutor {
  { ..self, max_steps, }
}

///|
/// Run the agent with a user input string.
///
/// Loads memory history (if any), appends the user message, and calls
/// `@llm.run_agent`. The final assistant text is extracted from the
/// stream events and returned.
///
/// Note: this is a synchronous wrapper. For streaming, use `run_agent`
/// directly with a custom `AgentEvent` handler.
pub fn AgentExecutor::invoke(self : AgentExecutor, input : String) -> String {
  let messages : Array[@llm.Message] = []
  // Load history from memory
  match self.memory {
    Some(m) =>
      for msg in m.load_messages() {
        messages.push(msg)
      }
    None => ()
  }
  // Append the new user message
  let user_msg = @llm.Message::user(input)
  messages.push(user_msg)
  // Accumulate final assistant text via stream events
  let mut final_text = ""
  @llm.run_agent(
    self.provider,
    self.tools,
    messages,
    @llm.StopCondition::MaxSteps(self.max_steps),
    fn(event : @llm.AgentEvent) -> Unit {
      match event {
        @llm.AgentEvent::Stream(e) =>
          match e {
            @llm.StreamEvent::TextDelta(s) => final_text = final_text + s
            _ => ()
          }
        _ => ()
      }
    },
  )
  // Save to memory
  match self.memory {
    Some(m) => {
      m.save_message(user_msg)
      if final_text != "" {
        m.save_message(@llm.Message::assistant(final_text))
      }
    }
    None => ()
  }
  final_text
}
