///|
test "strip_code_fence removes json fence" {
  let input = "```json\n{\"key\": \"value\"}\n```"
  let result = strip_code_fence(input)
  assert_eq(result, "{\"key\": \"value\"}")
}

///|
test "strip_code_fence removes plain fence" {
  let input = "```\n{\"key\": \"value\"}\n```"
  let result = strip_code_fence(input)
  assert_eq(result, "{\"key\": \"value\"}")
}

///|
test "strip_code_fence returns as-is when no fence" {
  let input = "{\"key\": \"value\"}"
  let result = strip_code_fence(input)
  assert_eq(result, "{\"key\": \"value\"}")
}

///|
test "strip_code_fence handles crlf line endings" {
  let input = "```json\r\n{\"key\": \"value\"}\r\n```"
  let result = strip_code_fence(input)
  assert_eq(result, "{\"key\": \"value\"}")
}

///|
test "JsonOutputParser parses valid json" {
  let parser = JsonOutputParser::new("test schema")
  match parser.parse("{\"key\": \"value\"}") {
    Ok(json) =>
      match json {
        Json::Object(map) =>
          match map.get("key") {
            Some(Json::String(s)) => assert_eq(s, "value")
            _ => assert_true(false)
          }
        _ => assert_true(false)
      }
    Err(_) => assert_true(false)
  }
}

///|
test "JsonOutputParser parses json with code fence" {
  let parser = JsonOutputParser::new("test schema")
  let input = "```json\n{\"key\": \"value\"}\n```"
  match parser.parse(input) {
    Ok(_) => ()
    Err(_) => assert_true(false)
  }
}

///|
test "JsonOutputParser format_instructions includes schema" {
  let parser = JsonOutputParser::new("MySchema")
  let instructions = parser.format_instructions()
  assert_true(instructions.contains("MySchema"))
}
