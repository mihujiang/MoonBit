///|
/// BoxedMemory wraps any `Memory` implementation into a uniform type,
/// allowing `LLMChain` and `AgentExecutor` to accept any Memory variant.
///
/// This follows the same boxing pattern as `@llm.BoxedProvider`.
///
/// Example:
/// ```moonbit nocheck
/// let chain = LLMChain::new(provider, prompt)
///   |> LLMChain::with_memory(BufferWindowMemory::new(5))
/// ```
pub struct BoxedMemory {
  inner : &Memory
}

///|
pub fn BoxedMemory::new(inner : &Memory) -> BoxedMemory {
  { inner, }
}

///|
pub impl Memory for BoxedMemory with fn load_messages(self : BoxedMemory) -> Array[
  @llm.Message,
] {
  self.inner.load_messages()
}

///|
pub impl Memory for BoxedMemory with fn save_message(
  self : BoxedMemory,
  message : @llm.Message,
) -> Unit {
  self.inner.save_message(message)
}

///|
pub impl Memory for BoxedMemory with fn clear(self : BoxedMemory) -> Unit {
  self.inner.clear()
}

///|
pub extend BoxedMemory with Memory::{load_messages, save_message, clear}
