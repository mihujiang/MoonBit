///|
/// PromptTemplate renders a string with `{variable}` interpolation.
///
/// Example:
/// ```moonbit nocheck
/// let t = PromptTemplate::new("Hello, {name}!")
/// t.render(Map([("name", "World")]))  // "Hello, World!"
/// ```
///
/// Variables are identified by `{name}` syntax. Unknown variables are left
/// as-is (including the braces) so missing keys are visible during debugging.
pub struct PromptTemplate {
  template : String
}

///|
pub fn PromptTemplate::new(template : String) -> PromptTemplate {
  { template, }
}

///|
/// Render the template by replacing `{var}` with values from `vars`.
pub fn PromptTemplate::render(
  self : PromptTemplate,
  vars : Map[String, String],
) -> String {
  let buf = StringBuilder::new()
  let s = self.template
  // Convert to Char array for indexed character access.
  let chars = s.to_array()
  let mut i = 0
  let n = chars.length()
  while i < n {
    let c = chars[i]
    if c == '{' {
      let mut j = i + 1
      while j < n && chars[j] != '}' {
        j = j + 1
      }
      if j < n {
        // Build var_name from chars[i+1 .. j]
        let name_buf = StringBuilder::new()
        for k in (i + 1)..<j {
          name_buf.write_char(chars[k])
        }
        let var_name = name_buf.to_string()
        match vars.get(var_name) {
          Some(v) => buf.write_string(v)
          None => {
            buf.write_char('{')
            buf.write_string(var_name)
            buf.write_char('}')
          }
        }
        i = j + 1
      } else {
        buf.write_char(c)
        i = i + 1
      }
    } else {
      buf.write_char(c)
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// Convenience: render with a single variable.
pub fn PromptTemplate::render_one(
  self : PromptTemplate,
  name : String,
  value : String,
) -> String {
  let vars : Map[String, String] = Map([])
  vars[name] = value
  self.render(vars)
}

///|
/// List variable names found in the template.
pub fn PromptTemplate::variables(self : PromptTemplate) -> Array[String] {
  let result : Array[String] = []
  let s = self.template
  let chars = s.to_array()
  let mut i = 0
  let n = chars.length()
  while i < n {
    if chars[i] == '{' {
      let mut j = i + 1
      while j < n && chars[j] != '}' {
        j = j + 1
      }
      if j < n {
        let name_buf = StringBuilder::new()
        for k in (i + 1)..<j {
          name_buf.write_char(chars[k])
        }
        result.push(name_buf.to_string())
        i = j + 1
      } else {
        i = i + 1
      }
    } else {
      i = i + 1
    }
  }
  result
}
