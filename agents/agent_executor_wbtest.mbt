///|
/// Whitebox tests for AgentExecutor, using a local TestMockProvider.
///
/// We define TestMockProvider locally because mizchi/llm's MockProvider
/// has a non-`pub` impl (same issue as chains/llm_chain_wbtest.mbt).
/// Tests cover invoke, invoke_stream, invoke_and_parse.

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

///|
test "AgentExecutor::invoke_and_parse returns parsed Json" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("{\"status\": \"ok\"}"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
    |> AgentExecutor::with_output_parser(
      @parsers.JsonOutputParser::new("schema"),
    )
  let result = executor.invoke_and_parse("query")
  let ok = match result {
    Ok(json) =>
      match json {
        Json::Object(map) =>
          match map.get("status") {
            Some(Json::String(s)) => s == "ok"
            _ => false
          }
        _ => false
      }
    Err(_) => false
  }
  assert_true(ok)
}

///|
test "AgentExecutor::invoke_and_parse returns Err without parser" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("some text"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let result = executor.invoke_and_parse("query")
  let is_err = match result {
    Ok(_) => false
    Err(msg) => msg.contains("No output parser")
  }
  assert_true(is_err)
}

///|
test "AgentExecutor::invoke_tracked records usage" {
  let usage_info = @llm.Usage::{ input_tokens: 100, output_tokens: 50 }
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("tracked response"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=Some(usage_info),
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let usage = @observability.UsageTracker::new()
  let trace = @observability.CallTrace::new()
  let logger = @observability.ErrorLogger::new()
  let result = executor.invoke_tracked("hello", usage, trace, logger)
  assert_eq(result, "tracked response")
  inspect(usage.input_tokens(), content="100")
  inspect(usage.output_tokens(), content="50")
}

///|
test "AgentExecutor::invoke_tracked records trace steps" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::TextDelta("tracked text"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let usage = @observability.UsageTracker::new()
  let trace = @observability.CallTrace::new()
  let logger = @observability.ErrorLogger::new()
  let result = executor.invoke_tracked("query", usage, trace, logger)
  assert_eq(result, "tracked text")
  // One step for the text chunk
  assert_true(trace.step_count() > 0)
}

///|
test "AgentExecutor::invoke_tracked logs stream errors" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::MessageStart,
      @llm.StreamEvent::Error("api timeout"),
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ],
  ])
  let registry = @llm_tools.ToolRegistry::new()
  let executor = AgentExecutor::new(@llm.BoxedProvider::new(mock), registry)
  let usage = @observability.UsageTracker::new()
  let trace = @observability.CallTrace::new()
  let logger = @observability.ErrorLogger::new()
  let result = executor.invoke_tracked("test", usage, trace, logger)
  assert_eq(result, "")
  inspect(logger.total_errors(), content="1")
  inspect(logger.count(ApiError), content="1")
}
