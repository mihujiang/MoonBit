///|
/// Wasm target: no stdin available, always returns empty string.
pub fn read_line() -> String {
  ""
}

///|
/// Wasm target: print without newline (falls back to println).
pub fn print(s : String) -> Unit {
  println(s)
}
