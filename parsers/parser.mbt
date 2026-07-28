///|
/// OutputParser converts raw LLM text output into a `Json` value.
///
/// Inspired by LangChain's OutputParser. Currently targets `Json` output
/// (MoonBit traits cannot have type parameters, so we specialize to Json;
/// use a generic struct wrapper if other target types are needed later).
pub(open) trait OutputParser {
  /// Parse the LLM output text into `Json`, or return an error message.
  fn parse(Self, String) -> Result[Json, String]

  /// Instructions to embed in the prompt so the model knows the expected
  /// output format.
  fn format_instructions(Self) -> String
}

///|
/// JsonOutputParser parses LLM output as a `Json` value.
///
/// It tolerates surrounding markdown code fences (```json ... ```) and
/// plain JSON. The schema_description is included in format_instructions
/// to guide the model.
pub struct JsonOutputParser {
  schema_description : String
}

///|
pub fn JsonOutputParser::new(schema_description : String) -> JsonOutputParser {
  { schema_description, }
}

///|
pub impl OutputParser for JsonOutputParser with fn parse(
  _self : JsonOutputParser,
  text : String,
) -> Result[Json, String] {
  let trimmed = text.trim().to_owned()
  // Strip markdown code fences if present
  let body = strip_code_fence(trimmed).trim().to_owned()
  // @json.parse raises ParseError; wrap into Result
  Ok(@json.parse(body)) catch {
    e => Err("JSON parse failed: " + e.to_string() + " | raw: \"" + body + "\"")
  }
}

///|
pub impl OutputParser for JsonOutputParser with fn format_instructions(
  self : JsonOutputParser,
) -> String {
  "Respond with a single JSON object matching this schema:\n" +
  self.schema_description +
  "\nDo not include any text outside the JSON object."
}

///|
/// Attach `OutputParser` trait methods to `JsonOutputParser` for dot-syntax calls.
pub extend JsonOutputParser with OutputParser::{parse, format_instructions}

///|
/// Strip surrounding ```...``` or ```json...``` code fences.
/// Returns the inner content. If no fence is present, returns the input as-is.
pub fn strip_code_fence(text : String) -> String {
  let s = text
  // Must start with ``` and have at least one more ``` somewhere after
  if s.has_prefix("```") {
    // Skip the opening ``` and find the end of the language tag line
    let after_open = s[3:].to_owned()
    match after_open.find_by(fn(c) { c == '\n' }) {
      Some(idx) => {
        let body_start = idx + 1
        let body = after_open[body_start:].to_owned()
        // Strip leading \r (from Windows \r\n line endings)
        let body = if body.has_prefix("\r") {
          body[1:].to_owned()
        } else {
          body
        }
        // Find the closing ``` in the body
        match body.find("```") {
          Some(end) => body[:end].trim().to_owned()
          None => body.trim().to_owned()
        }
      }
      None => s
    }
  } else {
    s
  }
}
