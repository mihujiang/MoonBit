///|
/// Whitebox tests for LLMChain.
///
/// We define a local `TestMockProvider` because mizchi/llm's `MockProvider`
/// has a non-`pub` `impl Provider`, making it invisible across packages.

///|
struct TestMockProvider {
  responses : Array[Array[@llm.StreamEvent]]
  mut call_count : Int
}

///|
fn TestMockProvider::new(
  responses : Array[Array[@llm.StreamEvent]],
) -> TestMockProvider {
  { responses, call_count: 0 }
}

///|
impl @llm.Provider for TestMockProvider with fn stream(
  self,
  _messages,
  _tools,
  handler,
) {
  if self.call_count < self.responses.length() {
    let events = self.responses[self.call_count]
    self.call_count = self.call_count + 1
    for event in events {
      (handler.on_event)(event)
    }
  }
}

///|
impl @llm.Provider for TestMockProvider with fn name(_self) -> String {
  "test-mock"
}

///|
test "LLMChain::invoke returns raw text (backward compat)" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("hello world")],
  ])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("Say {word}")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
  let vars : Map[String, String] = Map([])
  vars["word"] = "hi"
  let result = chain.invoke(vars)
  assert_eq(result, "hello world")
}

///|
test "LLMChain::invoke_and_parse returns parsed Json with parser" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("{\"key\": \"value\"}")],
  ])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("Return JSON")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
    |> LLMChain::with_output_parser(
      @parsers.JsonOutputParser::new("test schema"),
    )
  let vars : Map[String, String] = Map([])
  let result = chain.invoke_and_parse(vars)
  let ok = match result {
    Ok(json) =>
      match json {
        Json::Object(map) =>
          match map.get("key") {
            Some(Json::String(s)) => s == "value"
            _ => false
          }
        _ => false
      }
    Err(_) => false
  }
  assert_true(ok)
}

///|
test "LLMChain::invoke_and_parse tolerates code fences" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("```json\n{\"x\": 42}\n```")],
  ])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("Return JSON")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
    |> LLMChain::with_output_parser(@parsers.JsonOutputParser::new("schema"))
  let vars : Map[String, String] = Map([])
  let result = chain.invoke_and_parse(vars)
  let ok = match result {
    Ok(json) =>
      match json {
        Json::Object(map) =>
          match map.get("x") {
            Some(Json::Number(n, ..)) => n == 42.0
            _ => false
          }
        _ => false
      }
    Err(_) => false
  }
  assert_true(ok)
}

///|
test "LLMChain::invoke_and_parse returns Err without parser" {
  let mock = TestMockProvider::new([[@llm.StreamEvent::TextDelta("some text")]])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("test")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
  let vars : Map[String, String] = Map([])
  let result = chain.invoke_and_parse(vars)
  let is_err = match result {
    Ok(_) => false
    Err(msg) => msg.contains("No output parser")
  }
  assert_true(is_err)
}

///|
test "LLMChain::invoke_and_parse returns Err on invalid JSON" {
  let mock = TestMockProvider::new([
    [@llm.StreamEvent::TextDelta("not valid json")],
  ])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("Return JSON")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
    |> LLMChain::with_output_parser(@parsers.JsonOutputParser::new("schema"))
  let vars : Map[String, String] = Map([])
  let result = chain.invoke_and_parse(vars)
  let is_err = match result {
    Ok(_) => false
    Err(msg) => msg.contains("Failed to parse JSON")
  }
  assert_true(is_err)
}

///|
test "LLMChain::invoke_stream calls on_delta for each chunk" {
  let mock = TestMockProvider::new([
    [
      @llm.StreamEvent::TextDelta("Hello"),
      @llm.StreamEvent::TextDelta(", "),
      @llm.StreamEvent::TextDelta("world!"),
    ],
  ])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("Say {word}")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
  let vars : Map[String, String] = Map([])
  vars["word"] = "hi"
  let chunks : Array[String] = []
  let result = chain.invoke_stream(vars, fn(delta) { chunks.push(delta) })
  assert_eq(result, "Hello, world!")
  assert_eq(chunks.length(), 3)
  assert_eq(chunks[0], "Hello")
  assert_eq(chunks[1], ", ")
  assert_eq(chunks[2], "world!")
}

///|
test "LLMChain::invoke_stream returns full text with no deltas" {
  let mock = TestMockProvider::new([[]])
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_user("test")
  let chain = LLMChain::new(@llm.BoxedProvider::new(mock), prompt)
  let vars : Map[String, String] = Map([])
  let count : Ref[Int] = { val: 0 }
  let result = chain.invoke_stream(vars, fn(_delta) {
    count.val = count.val + 1
  })
  assert_eq(result, "")
  assert_eq(count.val, 0)
}
