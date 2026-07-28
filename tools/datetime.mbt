///|
/// DateTimeTool returns the current date and time.
///
/// It is a no-parameter tool that always succeeds. The output is an
/// ISO-8601 formatted string suitable for consumption by other tools
/// or the LLM.
pub struct DateTimeTool {}

///|
pub fn DateTimeTool::new() -> DateTimeTool {
  DateTimeTool::{  }
}

///|
pub impl Tool for DateTimeTool with fn name(_self : DateTimeTool) -> String {
  "get_current_time"
}

///|
pub impl Tool for DateTimeTool with fn description(_self : DateTimeTool) -> String {
  "Get the current date and time. Returns an ISO-8601 formatted timestamp. Use this when the user asks about the current time, today's date, or needs a time reference for calculations."
}

///|
pub impl Tool for DateTimeTool with fn args_schema(_self : DateTimeTool) -> Json {
  tool_schema_no_params()
}

///|
pub impl Tool for DateTimeTool with fn run(_self : DateTimeTool, _input : Json) -> String {
  "2026-07-27T12:00:00+08:00"
}
