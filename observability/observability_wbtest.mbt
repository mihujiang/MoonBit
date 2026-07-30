///|
/// White-box tests for observability module.

///|
test "UsageTracker starts at zero" {
  let t = UsageTracker::new()
  inspect(t.input_tokens(), content="0")
  inspect(t.output_tokens(), content="0")
  inspect(t.total_tokens(), content="0")
}

///|
test "UsageTracker captures MessageEnd with usage" {
  let usage = @llm.Usage::{ input_tokens: 100, output_tokens: 50 }
  let event = @llm.AgentEvent::Stream(
    @llm.StreamEvent::MessageEnd(
      finish_reason=@llm.FinishReason::Stop,
      usage=Some(usage),
    ),
  )
  let t = UsageTracker::new()
  t.record(event)
  inspect(t.input_tokens(), content="100")
  inspect(t.output_tokens(), content="50")
  inspect(t.total_tokens(), content="150")
}

///|
test "UsageTracker ignores non-MessageEnd events" {
  let t = UsageTracker::new()
  t.record(@llm.AgentEvent::Stream(@llm.StreamEvent::TextDelta("hello")))
  inspect(t.total_tokens(), content="0")
}

///|
test "UsageTracker ignores MessageEnd without usage" {
  let event = @llm.AgentEvent::Stream(
    @llm.StreamEvent::MessageEnd(
      finish_reason=@llm.FinishReason::Stop,
      usage=None,
    ),
  )
  let t = UsageTracker::new()
  t.record(event)
  inspect(t.total_tokens(), content="0")
}

///|
test "UsageTracker accumulates multiple events" {
  let u1 = @llm.Usage::{ input_tokens: 10, output_tokens: 5 }
  let u2 = @llm.Usage::{ input_tokens: 20, output_tokens: 15 }
  let t = UsageTracker::new()
  t.record(
    @llm.AgentEvent::Stream(
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=Some(u1),
      ),
    ),
  )
  t.record(
    @llm.AgentEvent::Stream(
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=Some(u2),
      ),
    ),
  )
  inspect(t.input_tokens(), content="30")
  inspect(t.output_tokens(), content="20")
}

///|
test "UsageTracker reset clears counters" {
  let usage = @llm.Usage::{ input_tokens: 100, output_tokens: 50 }
  let t = UsageTracker::new()
  t.record(
    @llm.AgentEvent::Stream(
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=Some(usage),
      ),
    ),
  )
  t.reset()
  inspect(t.total_tokens(), content="0")
}

///|
test "CallTrace starts empty" {
  let t = CallTrace::new()
  inspect(t.step_count(), content="0")
}

///|
test "CallTrace tracks text accumulation" {
  let t = CallTrace::new()
  t.record(@llm.AgentEvent::Stream(@llm.StreamEvent::TextDelta("Hello ")))
  t.record(@llm.AgentEvent::Stream(@llm.StreamEvent::TextDelta("World")))
  inspect(t.step_count(), content="0")
}

///|
test "CallTrace flushes text on MessageEnd" {
  let t = CallTrace::new()
  t.record(@llm.AgentEvent::Stream(@llm.StreamEvent::TextDelta("Hello")))
  t.record(
    @llm.AgentEvent::Stream(
      @llm.StreamEvent::MessageEnd(
        finish_reason=@llm.FinishReason::Stop,
        usage=None,
      ),
    ),
  )
  inspect(t.step_count(), content="1")
}

///|
test "CallTrace records error" {
  let t = CallTrace::new()
  t.record(@llm.AgentEvent::Stream(@llm.StreamEvent::Error("test error")))
  inspect(t.step_count(), content="1")
}

///|
test "TimingTracker starts at zero" {
  let t = TimingTracker::new()
  inspect(t.total_calls(), content="0")
}

///|
test "TimingTracker records and averages" {
  let t = TimingTracker::new()
  t.record("calculator", 100.0)
  t.record("calculator", 200.0)
  t.record("datetime", 50.0)
  inspect(t.total_calls(), content="3")
}

///|
test "ErrorLogger starts empty" {
  let l = ErrorLogger::new()
  inspect(l.total_errors(), content="0")
  inspect(l.format(), content="No errors logged this session.")
}

///|
test "ErrorLogger logs and counts by code" {
  let l = ErrorLogger::new()
  l.log_config_not_found(".env not found")
  l.log_api_error("429 Too Many Requests", "rate limit exceeded")
  l.log_api_error("401 Unauthorized", "invalid key")
  inspect(l.total_errors(), content="3")
  inspect(l.count(ConfigNotFound), content="1")
  inspect(l.count(ApiError), content="2")
  inspect(l.count(ToolError), content="0")
}

///|
test "ErrorLogger clear resets everything" {
  let l = ErrorLogger::new()
  l.log_config_not_found("test")
  l.log_api_error("test", "ctx")
  l.clear()
  inspect(l.total_errors(), content="0")
}

///|
test "ErrorLogger format includes all entries" {
  let l = ErrorLogger::new()
  l.log_tool_error("calculator", "division by zero")
  let formatted = l.format()
  assert_true(formatted.has_prefix("Error Report"))
  assert_true(formatted.contains("TOOL_ERROR"))
  assert_true(formatted.contains("calculator"))
}
