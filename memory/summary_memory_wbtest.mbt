///|
/// Whitebox tests for SummaryMemory.
///
/// Uses a local TestMockProvider because mizchi/llm's MockProvider has a
/// non-`pub` impl (same issue as chains/llm_chain_wbtest.mbt).

///|
struct TestMockProvider {
  responses : Array[Array[@llm.StreamEvent]]
  mut call_count : Int
}

///|
fn TestMockProvider::new(
  responses : Array[Array[@llm.StreamEvent]],
) -> TestMockProvider {
  { responses, call_count: 0 }
}

///|
impl @llm.Provider for TestMockProvider with fn stream(
  self,
  _messages,
  _tools,
  handler,
) {
  if self.call_count < self.responses.length() {
    let events = self.responses[self.call_count]
    self.call_count = self.call_count + 1
    for event in events {
      (handler.on_event)(event)
    }
  }
}

///|
impl @llm.Provider for TestMockProvider with fn name(_self) -> String {
  "test-mock"
}

///|
test "SummaryMemory stores messages under threshold" {
  let mock = TestMockProvider::new([])
  let m = SummaryMemory::new(@llm.BoxedProvider::new(mock), 5)
  m.save_message(@llm.Message::user("hello"))
  m.save_message(@llm.Message::assistant("hi there"))
  let msgs = m.load_messages()
  // No summary yet, all messages returned
  assert_eq(msgs.length(), 2)
  // Mock provider was never called (no summarization)
  assert_eq(mock.call_count, 0)
}

///|
test "SummaryMemory triggers summarization when threshold exceeded" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("Summary: user greeted assistant")],
  ])
  let m = SummaryMemory::new(@llm.BoxedProvider::new(mock), 2)
  m.save_message(@llm.Message::user("hello"))
  m.save_message(@llm.Message::assistant("hi"))
  // Third message triggers summarization (3 > 2)
  m.save_message(@llm.Message::user("how are you?"))
  assert_eq(mock.call_count, 1)
  let msgs = m.load_messages()
  // Should have: 1 summary system message + 2 recent messages
  assert_eq(msgs.length(), 3)
  assert_eq(@llm.Role::to_string(msgs[0].role), "system")
}

///|
test "SummaryMemory includes summary in load_messages" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("Conversation about greetings")],
  ])
  let m = SummaryMemory::new(@llm.BoxedProvider::new(mock), 2)
  m.save_message(@llm.Message::user("hi"))
  m.save_message(@llm.Message::assistant("hello"))
  m.save_message(@llm.Message::user("bye"))
  let msgs = m.load_messages()
  // First message is the summary
  let summary_text = msgs[0].get_text()
  assert_true(summary_text.contains("Conversation about greetings"))
}

///|
test "SummaryMemory clear resets state" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("some summary")],
  ])
  let m = SummaryMemory::new(@llm.BoxedProvider::new(mock), 2)
  m.save_message(@llm.Message::user("msg1"))
  m.save_message(@llm.Message::user("msg2"))
  m.save_message(@llm.Message::user("msg3")) // triggers summarization
  // Clear
  m.clear()
  let msgs = m.load_messages()
  assert_eq(msgs.length(), 0)
}

///|
test "SummaryMemory preserves recent messages after summarization" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("early summary")],
  ])
  let m = SummaryMemory::new(@llm.BoxedProvider::new(mock), 2)
  m.save_message(@llm.Message::user("msg1"))
  m.save_message(@llm.Message::user("msg2"))
  m.save_message(@llm.Message::user("msg3")) // triggers summarization, keeps last 2
  let msgs = m.load_messages()
  // 1 summary + 2 recent
  assert_eq(msgs.length(), 3)
  // Last two should be msg2 and msg3
  assert_eq(msgs[1].get_text(), "msg2")
  assert_eq(msgs[2].get_text(), "msg3")
}
