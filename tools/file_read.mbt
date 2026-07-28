///|
/// FileReadTool reads the content of a local file.
///
/// The actual file I/O is injected via callbacks so the tool works
/// on all targets. On native, use `@fs.read_file`; on JS, use the
/// platform FileReader API.
struct FileReadTool {
  read : (String) -> String
}

///|
pub fn FileReadTool::new(read : (String) -> String) -> FileReadTool {
  { read, }
}

///|
pub impl Tool for FileReadTool with fn name(_self : FileReadTool) -> String {
  "read_file"
}

///|
pub impl Tool for FileReadTool with fn description(_self : FileReadTool) -> String {
  "Read the contents of a file. Input must be a JSON object with a 'path' field containing the file path. Returns the file contents as a string."
}

///|
pub impl Tool for FileReadTool with fn args_schema(_self : FileReadTool) -> Json {
  tool_schema("path", "string", "Path to the file to read, e.g. README.md")
}

///|
pub impl Tool for FileReadTool with fn run(self : FileReadTool, input : Json) -> String {
  match input {
    Json::Object(map) =>
      match map.get("path") {
        Some(Json::String(path)) => (self.read)(path)
        _ => "Error: missing 'path' field"
      }
    _ => "Error: input is not a JSON object"
  }
}

///|
pub extend FileReadTool with Tool::{name, description, args_schema, run}
