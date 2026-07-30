///|
/// observability — token usage tracking and agent call tracing for moon-agent.
///
/// Provides `UsageTracker` to accumulate token usage across agent turns,
/// and `CallTrace` to record step-by-step agent decision trails.

///|
/// Token usage tracker. Uses cell array pattern so mutations persist
/// across MoonBit's value-passing semantics.
pub struct UsageTracker {
  cell : Array[Int] // [input_tokens, output_tokens]
}

///|
pub fn UsageTracker::new() -> UsageTracker {
  { cell: [0, 0] }
}

///|
pub fn UsageTracker::record(
  self : UsageTracker,
  event : @llm.AgentEvent,
) -> Unit {
  match event {
    @llm.AgentEvent::Stream(e) => UsageTracker::record_stream(self, e)
    _ => ()
  }
}

///|
fn UsageTracker::record_stream(
  self : UsageTracker,
  e : @llm.StreamEvent,
) -> Unit {
  match e {
    @llm.StreamEvent::MessageEnd(finish_reason=_, usage=Some(usage)) => {
      self.cell[0] = self.cell[0] + usage.input_tokens
      self.cell[1] = self.cell[1] + usage.output_tokens
    }
    _ => ()
  }
}

///|
pub fn UsageTracker::input_tokens(self : UsageTracker) -> Int {
  self.cell[0]
}

///|
pub fn UsageTracker::output_tokens(self : UsageTracker) -> Int {
  self.cell[1]
}

///|
pub fn UsageTracker::total_tokens(self : UsageTracker) -> Int {
  self.cell[0] + self.cell[1]
}

///|
pub fn UsageTracker::reset(self : UsageTracker) -> Unit {
  self.cell[0] = 0
  self.cell[1] = 0
}

///|
pub fn UsageTracker::estimated_cost(
  self : UsageTracker,
  input_price_per_1m : Float,
  output_price_per_1m : Float,
) -> Float {
  let input_cost = Float::from_int(self.cell[0]) *
    input_price_per_1m /
    1_000_000.0
  let output_cost = Float::from_int(self.cell[1]) *
    output_price_per_1m /
    1_000_000.0
  input_cost + output_cost
}

///|
pub fn UsageTracker::estimated_cost_deepseek(self : UsageTracker) -> Float {
  UsageTracker::estimated_cost(self, 0.14, 0.28)
}

///|
pub fn UsageTracker::format(self : UsageTracker) -> String {
  "Tokens: in=" +
  self.cell[0].to_string() +
  " out=" +
  self.cell[1].to_string() +
  " total=" +
  (self.cell[0] + self.cell[1]).to_string() +
  " | Est. cost: $" +
  UsageTracker::estimated_cost_deepseek(self).to_string()
}

///|
/// A single step in an agent call trace.
pub(all) enum TraceStep {
  ToolCall(String, String, String, Bool) // name, input, result, is_error
  AgentText(String)
  AgentError(String)
}

///|
/// Records the full decision trail of an agent invocation.
pub struct CallTrace {
  steps : Array[TraceStep]
  current_text : Array[String] // cell[0] = accumulated text
}

///|
pub fn CallTrace::new() -> CallTrace {
  { steps: [], current_text: [""] }
}

///|
fn CallTrace::flush_text(self : CallTrace) -> Unit {
  if self.current_text[0] != "" {
    self.steps.push(TraceStep::AgentText(self.current_text[0]))
    self.current_text[0] = ""
  }
}

///|
pub fn CallTrace::record(self : CallTrace, event : @llm.AgentEvent) -> Unit {
  match event {
    @llm.AgentEvent::Stream(e) => CallTrace::record_trace_stream(self, e)
    @llm.AgentEvent::ToolExecute(name~, input~) => {
      CallTrace::flush_text(self)
      self.steps.push(TraceStep::ToolCall(name, input.stringify(), "", false))
    }
    @llm.AgentEvent::ToolResult(name=_, result~, is_error~) => {
      let len = self.steps.length()
      if len > 0 {
        match self.steps[len - 1] {
          TraceStep::ToolCall(tool_name, prev_input, _, _) =>
            self.steps[len - 1] = TraceStep::ToolCall(
              tool_name, prev_input, result, is_error,
            )
          _ => ()
        }
      }
    }
    @llm.AgentEvent::Done(reason=_) => CallTrace::flush_text(self)
    _ => ()
  }
}

///|
fn CallTrace::record_trace_stream(
  self : CallTrace,
  e : @llm.StreamEvent,
) -> Unit {
  match e {
    @llm.StreamEvent::TextDelta(s) =>
      self.current_text[0] = self.current_text[0] + s
    @llm.StreamEvent::MessageEnd(finish_reason=_, usage=_) =>
      CallTrace::flush_text(self)
    @llm.StreamEvent::Error(msg) => self.steps.push(TraceStep::AgentError(msg))
    _ => ()
  }
}

///|
pub fn CallTrace::step_count(self : CallTrace) -> Int {
  self.steps.length()
}

///|
pub fn CallTrace::format(self : CallTrace) -> String {
  let mut buf = ""
  for i = 0; i < self.steps.length(); i = i + 1 {
    buf = buf + "  Step " + (i + 1).to_string() + ": "
    buf = buf + CallTrace::format_step(self.steps[i]) + "\n"
  }
  buf
}

///|
fn CallTrace::format_step(step : TraceStep) -> String {
  match step {
    TraceStep::ToolCall(name, input, result, is_error) => {
      let tag = if is_error { " (ERROR)" } else { "" }
      let preview = if result.length() > 80 {
        result[0:80].to_owned() + "..."
      } else {
        result
      }
      "[tool: " + name + "] input: " + input + tag + " → " + preview
    }
    TraceStep::AgentText(text) => {
      let preview = if text.length() > 120 {
        text[0:120].to_owned() + "..."
      } else {
        text
      }
      "[text] " + preview
    }
    TraceStep::AgentError(msg) => "[ERROR] " + msg
  }
}

///|
/// Lightweight timing tracker for tool execution latencies.
/// Stores per-tool timing data and computes averages.
pub struct TimingTracker {
  /// Accumulated durations in milliseconds per tool name.
  total_ms : Map[String, Float]
  /// Call count per tool name.
  counts : Map[String, Int]
  /// Ordered list of tool names (for iteration).
  tool_names : Array[String]
}

///|
pub fn TimingTracker::new() -> TimingTracker {
  { total_ms: Map([]), counts: Map([]), tool_names: [] }
}

///|
/// Record a tool execution duration in milliseconds.
pub fn TimingTracker::record(
  self : TimingTracker,
  tool_name : String,
  duration_ms : Float,
) -> Unit {
  let prev_total = match self.total_ms.get(tool_name) {
    Some(f) => f
    None => 0.0
  }
  let prev_count = match self.counts.get(tool_name) {
    Some(i) => i
    None => 0
  }
  self.total_ms[tool_name] = prev_total + duration_ms
  self.counts[tool_name] = prev_count + 1
  if prev_count == 0 {
    self.tool_names.push(tool_name)
  }
}

///|
/// Average duration for a tool in milliseconds. Returns 0.0 if never called.
pub fn TimingTracker::avg_ms(self : TimingTracker, tool_name : String) -> Float {
  match self.total_ms.get(tool_name) {
    Some(total) =>
      match self.counts.get(tool_name) {
        Some(count) =>
          if count > 0 {
            total / Float::from_int(count)
          } else {
            0.0
          }
        None => 0.0
      }
    None => 0.0
  }
}

///|
/// Total calls across all tools.
pub fn TimingTracker::total_calls(self : TimingTracker) -> Int {
  let mut sum = 0
  for i = 0; i < self.tool_names.length(); i = i + 1 {
    let name = self.tool_names[i]
    match self.counts.get(name) {
      Some(c) => sum = sum + c
      None => ()
    }
  }
  sum
}

///|
/// Format a summary of all tool timings.
pub fn TimingTracker::format(self : TimingTracker) -> String {
  let mut buf = "Tool execution stats:\n"
  for i = 0; i < self.tool_names.length(); i = i + 1 {
    let name = self.tool_names[i]
    let _total = match self.total_ms.get(name) {
      Some(f) => f
      None => 0.0
    }
    let count = match self.counts.get(name) {
      Some(c) => c
      None => 0
    }
    let avg = self.avg_ms(name)
    buf = buf +
      "  " +
      name +
      ": " +
      count.to_string() +
      " calls, " +
      avg.to_string() +
      " ms avg\n"
  }
  buf
}

///|
/// Structured error logging with error codes, context, and suggested fixes.
/// Use cell array pattern so mutations persist across MoonBit's value-passing semantics.

///|
/// Error code categories for structured logging.
pub(all) enum ErrorCode {
  ConfigNotFound
  ApiError
  ToolError
  ParseError
  ValidationError
  MemoryError
  NetworkError
}

///|
/// A single error entry with full context.
pub struct ErrorEntry {
  code : ErrorCode
  message : String
  context : String
  suggestion : String
}

///|
pub fn ErrorEntry::new(
  code : ErrorCode,
  message : String,
  context : String,
  suggestion : String,
) -> ErrorEntry {
  { code, message, context, suggestion }
}

///|
/// Format an error entry for display.
pub fn ErrorEntry::format(self : ErrorEntry) -> String {
  let code_str = match self.code {
    ConfigNotFound => "CONFIG_NOT_FOUND"
    ApiError => "API_ERROR"
    ToolError => "TOOL_ERROR"
    ParseError => "PARSE_ERROR"
    ValidationError => "VALIDATION_ERROR"
    MemoryError => "MEMORY_ERROR"
    NetworkError => "NETWORK_ERROR"
  }
  "[" +
  code_str +
  "] " +
  self.message +
  "\n  Context: " +
  self.context +
  "\n  Suggestion: " +
  self.suggestion
}

///|
/// Structured error logger with entries and analytics.
pub struct ErrorLogger {
  entries : Array[ErrorEntry]
  counts : Array[Int] // [config, api, tool, parse, validation, memory, network]
  session_total : Array[Int] // cell[0] = total
}

///|
pub fn ErrorLogger::new() -> ErrorLogger {
  { entries: [], counts: [0, 0, 0, 0, 0, 0, 0], session_total: [0] }
}

///|
/// Log an error to the logger.
pub fn ErrorLogger::log(
  self : ErrorLogger,
  code : ErrorCode,
  message : String,
  context : String,
  suggestion : String,
) -> Unit {
  let entry = ErrorEntry::new(code, message, context, suggestion)
  self.entries.push(entry)
  let idx = ErrorLogger::code_index(code)
  self.counts[idx] = self.counts[idx] + 1
  self.session_total[0] = self.session_total[0] + 1
}

///|
fn ErrorLogger::code_index(code : ErrorCode) -> Int {
  match code {
    ConfigNotFound => 0
    ApiError => 1
    ToolError => 2
    ParseError => 3
    ValidationError => 4
    MemoryError => 5
    NetworkError => 6
  }
}

///|
/// Total errors logged this session.
pub fn ErrorLogger::total_errors(self : ErrorLogger) -> Int {
  self.session_total[0]
}

///|
/// Count of errors for a specific code.
pub fn ErrorLogger::count(self : ErrorLogger, code : ErrorCode) -> Int {
  self.counts[ErrorLogger::code_index(code)]
}

///|
/// Get all logged entries.
pub fn ErrorLogger::entries(self : ErrorLogger) -> Array[ErrorEntry] {
  self.entries
}

///|
/// Clear all logged errors.
pub fn ErrorLogger::clear(self : ErrorLogger) -> Unit {
  self.entries.clear()
  for i = 0; i < self.counts.length(); i = i + 1 {
    self.counts[i] = 0
  }
  self.session_total[0] = 0
}

///|
/// Format all errors as a summary report.
pub fn ErrorLogger::format(self : ErrorLogger) -> String {
  if self.session_total[0] == 0 {
    return "No errors logged this session."
  }
  let mut buf = "Error Report (" +
    self.session_total[0].to_string() +
    " total):\n"
  for i = 0; i < self.entries.length(); i = i + 1 {
    buf = buf + "  " + self.entries[i].format() + "\n"
  }
  buf
}

///|
/// Convenience: log a config not found error.
pub fn ErrorLogger::log_config_not_found(
  self : ErrorLogger,
  context : String,
) -> Unit {
  self.log(
    ConfigNotFound,
    "Configuration not found",
    context,
    "Create a .env file with OPENAI_API_KEY=sk-... or set the environment variable.",
  )
}

///|
/// Convenience: log an API error.
pub fn ErrorLogger::log_api_error(
  self : ErrorLogger,
  message : String,
  context : String,
) -> Unit {
  self.log(
    ApiError,
    message,
    context,
    "Check your API key, network connection, and endpoint URL. Verify the API provider status page.",
  )
}

///|
/// Convenience: log a tool execution error.
pub fn ErrorLogger::log_tool_error(
  self : ErrorLogger,
  tool_name : String,
  message : String,
) -> Unit {
  self.log(
    ToolError,
    "Tool '" + tool_name + "' failed: " + message,
    "Tool execution",
    "Review the tool input parameters and ensure required dependencies are available.",
  )
}
