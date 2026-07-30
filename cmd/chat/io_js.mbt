///|
/// JS target: read a line from stdin synchronously using Node.js fs.readSync.
/// Returns empty string if EOF or error.
/// Handles encoding: tries UTF-8 first, falls back to GBK on Windows.
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
  #|    // Try UTF-8 first
  #|    let text = buf.toString('utf-8', 0, n);
  #|    // If replacement characters found, input was likely GBK (Windows codepage 936)
  #|    if (text.includes('\ufffd')) {
  #|      try {
  #|        // Use TextDecoder for GBK fallback
  #|        text = new TextDecoder('gbk', { fatal: false }).decode(buf.subarray(0, n));
  #|      } catch (_) {
  #|        // If gbk decoder unavailable, return the raw latin1 bytes as-is
  #|        text = buf.toString('latin1', 0, n);
  #|      }
  #|    }
  #|    return text.replace(/\r?\n$/, '');
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
