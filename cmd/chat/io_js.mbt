///|
/// JS target: read a line from stdin synchronously using Node.js fs.readSync.
/// Returns empty string if EOF or error.
pub fn read_line() -> String {
  js_read_line_sync()
}

///|
extern "js" fn js_read_line_sync() -> String =
  #|() => {
  #|  try {
  #|    const fs = require('fs');
  #|    const buf = Buffer.alloc(4096);
  #|    const n = fs.readSync(0, buf, 0, 4096, null);
  #|    if (n === 0) return '';
  #|    return buf.toString('utf-8', 0, n).replace(/\r?\n$/, '');
  #|  } catch (e) {
  #|    return '';
  #|  }
  #|}

///|
/// Print a string without trailing newline (for prompts and streaming).
pub fn print(s : String) -> Unit {
  js_print(s)
}

///|
extern "js" fn js_print(s : String) -> Unit =
  #|(s) => { process.stdout.write(s); }
