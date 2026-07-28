///|
/// Native target: file reading not supported in this minimal config package.
/// Returns empty string so caller falls back to env vars.
///
/// To enable native file reading, add a C stub similar to mizchi/llm's
/// `native_stub.c`. For now, native users must use env vars.
fn read_file_to_string(_path : String) -> String {
  ""
}
