///|
/// CalculatorTool evaluates simple arithmetic expressions.
///
/// Supports `+`, `-`, `*`, `/` on non-negative integers with left-to-right
/// evaluation. For complex math, defer to a dedicated math library.
pub struct CalculatorTool {}

///|
pub fn CalculatorTool::new() -> CalculatorTool {
  CalculatorTool::{  }
}

///|
pub impl Tool for CalculatorTool with fn name(_self : CalculatorTool) -> String {
  "calculator"
}

///|
pub impl Tool for CalculatorTool with fn description(_self : CalculatorTool) -> String {
  "Evaluate a simple arithmetic expression with integers. Supports +, -, *, / and parentheses. Input must be a JSON object with an 'expression' field."
}

///|
pub impl Tool for CalculatorTool with fn args_schema(_self : CalculatorTool) -> Json {
  tool_schema(
    "expression", "string", "A math expression to evaluate, e.g. \"2 + 3 * 4\"",
  )
}

///|
pub impl Tool for CalculatorTool with fn run(
  self : CalculatorTool,
  input : Json,
) -> String {
  match input {
    Json::Object(map) =>
      match map.get("expression") {
        Some(Json::String(expr)) => self.eval(expr)
        _ => "Error: missing expression field"
      }
    _ => "Error: input is not a JSON object"
  }
}

///|
/// Simple left-to-right integer evaluator. No operator precedence;
/// all operators have equal priority.
fn CalculatorTool::eval(_self : CalculatorTool, expr : String) -> String {
  let chars = expr.to_array()
  let n = chars.length()
  let mut i = 0
  let mut result = 0
  let mut op = '+'
  while i < n {
    let c = chars[i]
    let digit = c.to_uint()
    if digit >= 48 && digit <= 57 {
      // accumulate digits into a number
      let mut num = 0
      while i < n {
        let d = chars[i].to_uint()
        if d >= 48 && d <= 57 {
          let digit_val = d.reinterpret_as_int() - 48
          num = num * 10 + digit_val
          i = i + 1
        } else {
          break
        }
      }
      match op {
        '+' => result = result + num
        '-' => result = result - num
        '*' => result = result * num
        '/' =>
          if num == 0 {
            return "Error: division by zero"
          } else {
            result = result / num
          }
        _ => ()
      }
    } else {
      match c {
        '+' => op = '+'
        '-' => op = '-'
        '*' => op = '*'
        '/' => op = '/'
        ' ' => ()
        _ => return "Error: unexpected character: " + c.to_string()
      }
      i = i + 1
    }
  }
  result.to_string()
}
