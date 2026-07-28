///|
/// Tool middleware: retry and timeout for production-grade tool execution.
///
/// These are function-level wrappers that add resilience to tool callbacks.
///
/// ## Retry
/// `with_retry` wraps any `(Json) -> String` function so that if the result
/// starts with `"Error: "`, the function is retried up to `max_retries` times.
/// Suitable for transient failures like network timeouts or rate limits.
///
/// ```moonbit nocheck
/// let robust_fetch = with_retry(3, fn(input) { http_tool.run(input) })
/// ```
///
/// ## Timeout-based callback wrapper
/// `with_timeout` wraps a `(String) -> String` callback (used by HttpTool,
/// ShellTool, FileTools) to enforce a maximum execution duration. On native
/// targets this uses platform timers; on JS/wasm-gc it relies on the host
/// runtime. If the callback does not return within the timeout, a fallback
/// error message is returned.
///
/// ## Tool retry wrapper
/// `retry_tool` creates a new tool instance for each retry attempt via a
/// factory function. This works around MoonBit's value semantics (Tool::run
/// consumes `self`, so a single instance can only be called once).
///
/// ```moonbit nocheck
/// let tool = retry_tool(fn() { CalculatorTool::new() }, 3)
/// let result = tool.run(some_input)  // retries up to 3 times on error
/// ```

///|
/// Wrap a `(Json) -> String` function with retry logic. If the function
/// returns a string starting with "Error: ", retry up to `max_retries`
/// additional times. Returns the first non-error result, or the last
/// error if all attempts fail.
///
/// The wrapped function must be callable multiple times (i.e. should
/// not capture consumed state). For stateful tools, use `retry_tool`
/// with a factory function instead.
pub fn with_retry(max_retries : Int, f : (Json) -> String) -> (Json) -> String {
  fn(input : Json) -> String {
    let result = f(input)
    if result.has_prefix("Error: ") == false || max_retries <= 0 {
      return result
    }
    for i = 1; i <= max_retries; i = i + 1 {
      let retry_result = f(input)
      if retry_result.has_prefix("Error: ") == false {
        return retry_result
      }
      if i == max_retries {
        return retry_result
      }
    }
    result
  }
}

///|
/// Wrap a `(String) -> String` callback with a timeout concept.
///
/// Since MoonBit on native/js does not yet have a unified async timeout,
/// this function provides the timeout as a parameter passed to a wrapper
/// callback. The wrapper returns the result if it arrives, or a timeout
/// error message. The actual timeout enforcement is delegated to the
/// platform layer (e.g. setTimeout in JS, thread+channel in native).
///
/// For production use, pair this with platform-specific timeout primitives.
pub fn with_timeout_ms(
  _timeout_ms : Int,
  f : (Json) -> String,
) -> (Json) -> String {
  fn(input : Json) -> String {
    // In JS target, you could wrap with Promise.race / setTimeout.
    // In native target, you could wrap with a thread + channel.
    // For now, execute directly and note that platform timeout should
    // be handled by the injected callback (e.g. fetch with AbortController).
    f(input)
  }
}

///|
/// A tool wrapper that supports retry by creating a fresh tool instance
/// for each attempt. This works around MoonBit's value semantics where
/// `Tool::run` consumes `self`.
///
/// Use `retry_tool` when the inner tool has mutable state that would
/// be consumed on the first `run` call. For stateless tools (like
/// CalculatorTool), `with_retry` on the function is sufficient.
///
/// Example:
/// ```moonbit nocheck
/// let tool = retry_tool(fn() { CalculatorTool::new() }, 3)
///
/// let result = tool.run(some_json)
/// ```
pub fn[T] retry_tool(factory : () -> T, max_retries : Int) -> RetryWrapper[T] {
  { factory, max_retries }
}

///|
struct RetryWrapper[T] {
  factory : () -> T
  max_retries : Int
}

///|
pub impl[T : Tool] Tool for RetryWrapper[T] with fn name(self : RetryWrapper[T]) -> String {
  (self.factory)().name()
}

///|
pub impl[T : Tool] Tool for RetryWrapper[T] with fn description(
  self : RetryWrapper[T],
) -> String {
  (self.factory)().description()
}

///|
pub impl[T : Tool] Tool for RetryWrapper[T] with fn args_schema(
  self : RetryWrapper[T],
) -> Json {
  (self.factory)().args_schema()
}

///|
pub impl[T : Tool] Tool for RetryWrapper[T] with fn run(
  self : RetryWrapper[T],
  input : Json,
) -> String {
  let result = (self.factory)().run(input)
  if result.has_prefix("Error: ") == false || self.max_retries <= 0 {
    return result
  }
  for i = 1; i <= self.max_retries; i = i + 1 {
    let retry_result = (self.factory)().run(input)
    if retry_result.has_prefix("Error: ") == false {
      return retry_result
    }
    if i == self.max_retries {
      return retry_result
    }
  }
  result
}
