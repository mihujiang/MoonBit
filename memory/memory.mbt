///|
/// Memory manages conversation history for an agent or chain.
///
/// Inspired by LangChain's BaseMemory. Implementations include
/// BufferMemory (full history), BufferWindowMemory (sliding window),
/// and SummaryMemory (periodic summarization).
///
/// Unlike mizchi/llm's Session, moon-agent's Memory preserves full
/// ContentBlock arrays (including ToolUse and ToolResult), so tool-calling
/// context is never lost when loading history.
pub(open) trait Memory {
  /// Load history into a list of messages (most recent last).
  fn load_messages(Self) -> Array[@llm.Message]

  /// Save a new message (user, assistant, or tool) into history.
  fn save_message(Self, @llm.Message) -> Unit

  /// Clear all history.
  fn clear(Self) -> Unit
}
