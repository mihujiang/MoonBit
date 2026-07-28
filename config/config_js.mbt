///|
/// JS target: read file synchronously via Node.js `fs.readFileSync`.
/// Returns empty string on any error (file not found, permission, etc.).
fn read_file_to_string(path : String) -> String {
  js_read_file_sync(path)
}

///|
extern "js" fn js_read_file_sync(path : String) -> String =
  #|(path) => {
  #|  try {
  #|    const fs = require('fs');
  #|    return fs.readFileSync(path, 'utf-8');
  #|  } catch (e) {
  #|    return '';
  #|  }
  #|}
