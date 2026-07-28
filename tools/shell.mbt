///|
/// ShellTool lets an Agent execute system commands (sandboxed).
///
/// The actual command execution is injected via an `exec` callback so
/// the tool works on all targets. The callback is responsible for
/// sandboxing — limit allowed commands, set timeouts, restrict file
/// system access, etc.
///
/// The callback receives the command string and returns stdout/stderr
/// combined as a string. If the command fails, the callback should
/// return an error string prefixed with "Error: ".
///
/// Example (native, using @process):
/// ```moonbit nocheck
/// let shell = ShellTool::new(fn(cmd) {
///   let output = @process.system(cmd)
///   if output.exit_code == 0 {
///     output.stdout
///   } else {
///     output.stderr
///   }
/// })
/// ```
struct ShellTool {
  exec : (String) -> String
}

///|
pub fn ShellTool::new(exec : (String) -> String) -> ShellTool {
  { exec, }
}

///|
pub impl Tool for ShellTool with fn name(_self : ShellTool) -> String {
  "shell_exec"
}

///|
pub impl Tool for ShellTool with fn description(_self : ShellTool) -> String {
  "Execute a shell command and return the output. Input must be a JSON object with a 'command' field containing the shell command to run. Use with caution — commands are executed in a sandboxed environment. Returns stdout on success, or stderr on failure."
}

///|
pub impl Tool for ShellTool with fn args_schema(_self : ShellTool) -> Json {
  let props : Map[String, Json] = Map([])
  props["command"] = param(
    "string", "The shell command to execute, e.g. ls -la or echo hello",
  )
  props["timeout"] = param(
    "number", "Optional timeout in seconds (default: 30)",
  )
  object_schema(props, ["command"])
}

///|
pub impl Tool for ShellTool with fn run(self : ShellTool, input : Json) -> String {
  match input {
    Json::Object(map) =>
      match map.get("command") {
        Some(Json::String(cmd)) => (self.exec)(cmd)
        _ => "Error: missing 'command' field"
      }
    _ => "Error: input is not a JSON object"
  }
}

///|
pub extend ShellTool with Tool::{name, description, args_schema, run}
