///|
/// SummaryMemory maintains a running summary of the conversation.
///
/// When the number of pending (un-summarized) messages exceeds
/// `max_pending`, it calls the LLM to produce a summary of the older
/// messages, then keeps only the most recent few as context.
///
/// Equivalent to LangChain's `ConversationSummaryMemory`.
///
/// On `load_messages`, returns:
/// 1. A system message with the current summary (if any)
/// 2. The pending (recent, un-summarized) messages
pub struct SummaryMemory {
  provider : @llm.BoxedProvider
  // Mutable cell: summary_cell[0] is the current summary, "" if none.
  // (Using Array rather than `mut` because MoonBit struct methods take
  // self by value, so `mut` field reassignment would not persist.)
  summary_cell : Array[String]
  pending : Array[@llm.Message]
  max_pending : Int
}

///|
/// Create a SummaryMemory that summarizes when pending messages exceed
/// `max_pending`. After summarization, keeps the last 2 messages as
/// recent context.
pub fn SummaryMemory::new(
  provider : @llm.BoxedProvider,
  max_pending : Int,
) -> SummaryMemory {
  { provider, summary_cell: [""], pending: [], max_pending }
}

///|
/// Trigger summarization if pending messages exceed the threshold.
/// Calls the LLM with the existing summary + pending messages, then
/// keeps only the last 2 messages as recent context.
fn SummaryMemory::maybe_summarize(self : SummaryMemory) -> Unit {
  if self.pending.length() <= self.max_pending {
    return
  }
  // Build messages for the summarization call
  let messages : Array[@llm.Message] = []
  let prev = self.summary_cell[0]
  let sys = if prev != "" {
    "You are a conversation summarizer. Update the existing summary with the new messages. Be concise but retain key facts, decisions, and context.\n\nPrevious summary:\n" +
    prev
  } else {
    "You are a conversation summarizer. Summarize the conversation concisely, retaining key facts, decisions, and context."
  }
  messages.push(@llm.Message::system(sys))
  for msg in self.pending {
    messages.push(msg)
  }
  // Call LLM to produce the new summary
  let result = @llm.collect_text(self.provider.inner, messages)
  self.summary_cell[0] = result
  // Keep only the last 2 messages as recent context
  let n = self.pending.length()
  if n > 2 {
    let kept : Array[@llm.Message] = []
    for i in (n - 2)..<n {
      kept.push(self.pending[i])
    }
    self.pending.clear()
    for msg in kept {
      self.pending.push(msg)
    }
  }
}

///|
pub impl Memory for SummaryMemory with fn save_message(
  self : SummaryMemory,
  message : @llm.Message,
) -> Unit {
  self.pending.push(message)
  self.maybe_summarize()
}

///|
pub impl Memory for SummaryMemory with fn load_messages(self : SummaryMemory) -> Array[
  @llm.Message,
] {
  let result : Array[@llm.Message] = []
  let s = self.summary_cell[0]
  if s != "" {
    result.push(@llm.Message::system("Summary of earlier conversation:\n" + s))
  }
  for msg in self.pending {
    result.push(msg)
  }
  result
}

///|
pub impl Memory for SummaryMemory with fn clear(self : SummaryMemory) -> Unit {
  self.summary_cell[0] = ""
  self.pending.clear()
}

///|
pub extend SummaryMemory with Memory::{load_messages, save_message, clear}
