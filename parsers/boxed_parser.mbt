///|
/// BoxedOutputParser wraps any `OutputParser` implementation into a uniform
/// type, allowing `LLMChain` to accept any parser variant.
///
/// This follows the same boxing pattern as `@memory.BoxedMemory` and
/// `@llm.BoxedProvider`.
///
/// Example:
/// ```moonbit nocheck
/// let chain = LLMChain::new(provider, prompt)
///   |> LLMChain::with_output_parser(JsonOutputParser::new("schema..."))
/// ```
pub struct BoxedOutputParser {
  inner : &OutputParser
}

///|
pub fn BoxedOutputParser::new(inner : &OutputParser) -> BoxedOutputParser {
  { inner, }
}

///|
pub impl OutputParser for BoxedOutputParser with fn parse(
  _self : BoxedOutputParser,
  text : String,
) -> Result[Json, String] {
  _self.inner.parse(text)
}

///|
pub impl OutputParser for BoxedOutputParser with fn format_instructions(
  _self : BoxedOutputParser,
) -> String {
  _self.inner.format_instructions()
}

///|
pub extend BoxedOutputParser with OutputParser::{parse, format_instructions}
