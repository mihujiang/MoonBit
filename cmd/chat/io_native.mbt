///|
/// Native target: read a line from stdin using C fgets.
/// Returns empty string if EOF or error.
pub fn read_line() -> String {
  "" // TODO: implement C fgets FFI after MoonBit stabilizes FFI annotations
}

///|
/// Print a string without trailing newline.
pub fn print(s : String) -> Unit {
  println(s) // fallback on native target
}
