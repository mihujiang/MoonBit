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
  memory : @memory.BufferMemory?
}

///|
/// Create a new LLMChain with the given provider and prompt template.
pub fn LLMChain::new(
  provider : @llm.BoxedProvider,
  prompt : @prompts.ChatPromptTemplate,
) -> LLMChain {
  { provider, prompt, memory: None }
}

///|
/// Attach a BufferMemory to the chain. History will be loaded before
/// each invocation and saved after.
pub fn LLMChain::with_memory(
  self : LLMChain,
  memory : @memory.BufferMemory,
) -> LLMChain {
  { ..self, memory: Some(memory) }
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
