///|
/// Wasm target: no file system access. Returns empty string so caller
/// falls back to env vars (which also return empty on wasm).
fn read_file_to_string(_path : String) -> String {
  ""
}
