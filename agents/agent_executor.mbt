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
  memory : @memory.BoxedMemory?
  output_parser : @parsers.BoxedOutputParser?
  max_steps : Int
}

///|
/// Create a new AgentExecutor with the given provider and tool registry.
pub fn AgentExecutor::new(
  provider : @llm.BoxedProvider,
  tools : @llm_tools.ToolRegistry,
) -> AgentExecutor {
  { provider, tools, memory: None, output_parser: None, max_steps: 10 }
}

///|
/// Attach a Memory. Accepts any `Memory` implementation
/// (BufferMemory, BufferWindowMemory, etc.).
pub fn AgentExecutor::with_memory(
  self : AgentExecutor,
  memory : &@memory.Memory,
) -> AgentExecutor {
  { ..self, memory: Some(@memory.BoxedMemory::new(memory)) }
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
/// Attach an OutputParser to the executor. Use `invoke_and_parse` to
/// get the parsed result; `invoke` still returns raw text.
pub fn AgentExecutor::with_output_parser(
  self : AgentExecutor,
  parser : &@parsers.OutputParser,
) -> AgentExecutor {
  { ..self, output_parser: Some(@parsers.BoxedOutputParser::new(parser)) }
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

///|
/// Run the agent with streaming, calling `on_delta` for each text chunk
/// as it arrives from the model. Returns the full text after completion.
///
/// This is the streaming version of `invoke`. Memory is loaded and saved
/// the same way. The `on_delta` callback is invoked for every
/// `TextDelta` event; tool call events and other stream events are
/// handled internally by `run_agent` and not exposed.
///
/// Example:
/// ```moonbit nocheck
/// let result = executor.invoke_stream("What's the weather?", fn(delta) {
///   print(delta) // stream to stdout as text arrives
/// })
/// ```
pub fn AgentExecutor::invoke_stream(
  self : AgentExecutor,
  input : String,
  on_delta : (String) -> Unit,
) -> String {
  let messages : Array[@llm.Message] = []
  match self.memory {
    Some(m) =>
      for msg in m.load_messages() {
        messages.push(msg)
      }
    None => ()
  }
  let user_msg = @llm.Message::user(input)
  messages.push(user_msg)
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
            @llm.StreamEvent::TextDelta(s) => {
              final_text = final_text + s
              on_delta(s)
            }
            _ => ()
          }
        _ => ()
      }
    },
  )
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

///|
/// Run the agent and parse the result with the attached OutputParser.
///
/// Calls `invoke` to get the raw text, then parses it. Returns `Err`
/// if no parser is attached or parsing fails.
pub fn AgentExecutor::invoke_and_parse(
  self : AgentExecutor,
  input : String,
) -> Result[Json, String] {
  let text = self.invoke(input)
  match self.output_parser {
    Some(p) => p.parse(text)
    None =>
      Err(
        "No output parser configured. Use AgentExecutor::with_output_parser to set one.",
      )
  }
}
