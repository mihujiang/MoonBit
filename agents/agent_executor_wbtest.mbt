///|
/// Whitebox tests for AgentExecutor, using a local TestMockProvider.
///
/// We define TestMockProvider locally because mizchi/llm's MockProvider
/// has a non-`pub` impl (same issue as chains/llm_chain_wbtest.mbt).

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
test "AgentExecutor::invoke_stream calls on_delta for each chunk" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("Hello, "),
      @llm.StreamEvent::TextDelta("world!"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let chunks : Array[String] = []
  let result = executor.invoke_stream("hi", fn(delta) { chunks.push(delta) })
  assert_eq(result, "Hello, world!")
  assert_eq(chunks.length(), 2)
  assert_eq(chunks[0], "Hello, ")
  assert_eq(chunks[1], "world!")
}

///|
test "AgentExecutor::invoke returns text without streaming" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("agent response"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let result = executor.invoke("hello")
  assert_eq(result, "agent response")
}
