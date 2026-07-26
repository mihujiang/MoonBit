///|
/// LLMChain combines a prompt template, a model (Provider), and optional
/// memory into a single unit.
///
/// This is moon-agent's equivalent of LangChain's `LLMChain`. It is the
/// simplest non-trivial chain: render prompt → call model → return text.
///
/// Memory is optional. When present, history is prepended to the rendered
/// prompt messages, and both the user input and assistant output are
/// appended to memory after each invocation.
pub struct LLMChain {
  provider : @llm.BoxedProvider
  prompt : @prompts.ChatPromptTemplate
  memory : @memory.BoxedMemory?
  output_parser : @parsers.BoxedOutputParser?
}

///|
/// Create a new LLMChain with the given provider and prompt template.
pub fn LLMChain::new(
  provider : @llm.BoxedProvider,
  prompt : @prompts.ChatPromptTemplate,
) -> LLMChain {
  { provider, prompt, memory: None, output_parser: None }
}

///|
/// Attach a Memory to the chain. Accepts any `Memory` implementation
/// (BufferMemory, BufferWindowMemory, etc.). History will be loaded
/// before each invocation and saved after.
pub fn LLMChain::with_memory(
  self : LLMChain,
  memory : &@memory.Memory,
) -> LLMChain {
  { ..self, memory: Some(@memory.BoxedMemory::new(memory)) }
}

///|
/// Attach an OutputParser to the chain. Accepts any `OutputParser`
/// implementation (JsonOutputParser, etc.). Use `invoke_and_parse` to
/// get the parsed result; `invoke` still returns raw text.
pub fn LLMChain::with_output_parser(
  self : LLMChain,
  parser : &@parsers.OutputParser,
) -> LLMChain {
  { ..self, output_parser: Some(@parsers.BoxedOutputParser::new(parser)) }
}

///|
/// Run the chain: render the prompt with `vars`, optionally prepend
/// memory history, call the model, and return the assistant text.
pub fn LLMChain::invoke(self : LLMChain, vars : Map[String, String]) -> String {
  let rendered = self.prompt.render(vars)
  let messages : Array[@llm.Message] = []
  // Prepend memory history if present
  match self.memory {
    Some(m) =>
      for msg in m.load_messages() {
        messages.push(msg)
      }
    None => ()
  }
  // Append rendered prompt messages
  for msg in rendered {
    messages.push(msg)
  }
  // Call the model (non-streaming collect)
  let result = @llm.collect_text(self.provider.inner, messages)
  // Save user input (last rendered user message) and assistant reply
  match self.memory {
    Some(m) => {
      // Find last user message in rendered
      for msg in rendered {
        match msg.role {
          @llm.Role::User => m.save_message(msg)
          _ => ()
        }
      }
      m.save_message(@llm.Message::assistant(result))
    }
    None => ()
  }
  result
}

///|
/// Run the chain and parse the result with the attached OutputParser.
///
/// Calls `invoke` to get the raw text, then parses it with the
/// configured `output_parser`. Returns `Err` if no parser is attached
/// or parsing fails.
///
/// The parser's `format_instructions` are NOT auto-injected into the
/// prompt; include them manually if needed (e.g. as a system message).
pub fn LLMChain::invoke_and_parse(
  self : LLMChain,
  vars : Map[String, String],
) -> Result[Json, String] {
  let text = self.invoke(vars)
  match self.output_parser {
    Some(p) => p.parse(text)
    None =>
      Err(
        "No output parser configured. Use LLMChain::with_output_parser to set one.",
      )
  }
}
