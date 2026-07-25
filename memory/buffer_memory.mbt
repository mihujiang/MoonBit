///|
/// BufferMemory keeps the full conversation history in memory.
/// Equivalent to LangChain's ConversationBufferMemory.
///
/// Preserves all ContentBlock variants (Text, ToolUse, ToolResult),
/// unlike mizchi/llm's Session which drops tool calls on load.
pub struct BufferMemory {
  messages : Array[@llm.Message]
}

///|
pub fn BufferMemory::new() -> BufferMemory {
  { messages: [] }
}

///|
impl Memory for BufferMemory with fn load_messages(self : BufferMemory) -> Array[
  @llm.Message,
] {
  self.messages
}

///|
impl Memory for BufferMemory with fn save_message(
  self : BufferMemory,
  message : @llm.Message,
) -> Unit {
  self.messages.push(message)
}

///|
impl Memory for BufferMemory with fn clear(self : BufferMemory) -> Unit {
  self.messages.clear()
}

///|
/// Attach `Memory` trait methods to `BufferMemory` so they can be called
/// via dot syntax (e.g. `memory.save_message(msg)`).
pub extend BufferMemory with Memory::{load_messages, save_message, clear}

///|
/// BufferWindowMemory keeps only the last `k` message exchanges.
/// Equivalent to LangChain's ConversationBufferWindowMemory.
///
/// Useful for bounding context length when conversations grow long.
pub struct BufferWindowMemory {
  messages : Array[@llm.Message]
  k : Int
}

///|
/// Create a window memory that keeps the last `k` messages.
pub fn BufferWindowMemory::new(k : Int) -> BufferWindowMemory {
  { messages: [], k }
}

///|
impl Memory for BufferWindowMemory with fn load_messages(
  self : BufferWindowMemory,
) -> Array[@llm.Message] {
  let n = self.messages.length()
  if n <= self.k {
    self.messages
  } else {
    let start = n - self.k
    let result : Array[@llm.Message] = []
    for i in start..<n {
      result.push(self.messages[i])
    }
    result
  }
}

///|
impl Memory for BufferWindowMemory with fn save_message(
  self : BufferWindowMemory,
  message : @llm.Message,
) -> Unit {
  self.messages.push(message)
}

///|
impl Memory for BufferWindowMemory with fn clear(self : BufferWindowMemory) -> Unit {
  self.messages.clear()
}

///|
/// Attach `Memory` trait methods to `BufferWindowMemory` for dot-syntax calls.
pub extend BufferWindowMemory with Memory::{load_messages, save_message, clear}
