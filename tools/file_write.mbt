///|
/// FileWriteTool writes string content to a local file.
///
/// The actual file I/O is injected via callbacks so the tool works
/// on all targets.
struct FileWriteTool {
  write : (String, String) -> String
}

///|
pub fn FileWriteTool::new(write : (String, String) -> String) -> FileWriteTool {
  { write, }
}

///|
pub impl Tool for FileWriteTool with fn name(_self : FileWriteTool) -> String {
  "write_file"
}

///|
pub impl Tool for FileWriteTool with fn description(_self : FileWriteTool) -> String {
  "Write content to a file. Input must be a JSON object with fields: path (file path) and content (string to write). Returns a success message or error."
}

///|
pub impl Tool for FileWriteTool with fn args_schema(_self : FileWriteTool) -> Json {
  let props : Map[String, Json] = Map([])
  props["path"] = param("string", "Path to the file to write, e.g. output.txt")
  props["content"] = param("string", "Content to write to the file")
  object_schema(props, ["path", "content"])
}

///|
pub impl Tool for FileWriteTool with fn run(self : FileWriteTool, input : Json) -> String {
  match input {
    Json::Object(map) => {
      let path = match map.get("path") {
        Some(Json::String(s)) => s
        _ => return "Error: missing 'path' field"
      }
      let content = match map.get("content") {
        Some(Json::String(s)) => s
        _ => return "Error: missing 'content' field"
      }
      (self.write)(path, content)
    }
    _ => "Error: input is not a JSON object"
  }
}

///|
pub extend FileWriteTool with Tool::{name, description, args_schema, run}
