///|
/// White-box tests for tools module.
/// Covers CalculatorTool, DateTimeTool, ToolGuard, and ToolMiddleware.

///| CalculatorTool tests

///|
test "CalculatorTool basic addition" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("2+3")
  let result = tool.run(Json::object(input))
  inspect(result, content="5")
}

///|
test "CalculatorTool subtraction" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("10-4")
  let result = tool.run(Json::object(input))
  inspect(result, content="6")
}

///|
test "CalculatorTool multiplication" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("6*7")
  let result = tool.run(Json::object(input))
  inspect(result, content="42")
}

///|
test "CalculatorTool division" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("15/3")
  let result = tool.run(Json::object(input))
  inspect(result, content="5")
}

///|
test "CalculatorTool division by zero returns error" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("5/0")
  let result = tool.run(Json::object(input))
  assert_true(result.has_prefix("Error"))
}

///|
test "CalculatorTool multi-digit arithmetic" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("100+200")
  let result = tool.run(Json::object(input))
  inspect(result, content="300")
}

///|
test "CalculatorTool missing expression field returns error" {
  let tool = CalculatorTool::new()
  let input : Map[String, Json] = Map([])
  let result = tool.run(Json::object(input))
  assert_true(result.has_prefix("Error"))
}

///|
test "CalculatorTool non-object input returns error" {
  let tool = CalculatorTool::new()
  let result = tool.run(Json::string("2+3"))
  assert_true(result.has_prefix("Error"))
}

///| DateTimeTool tests

///|
test "DateTimeTool returns ISO timestamp" {
  let tool = DateTimeTool::new()
  let result = tool.run(Json::object(Map([])))
  assert_true(result.length() > 0)
  assert_true(result.contains("T"))
}

///|
test "DateTimeTool name is correct" {
  let tool = DateTimeTool::new()
  inspect(tool.name(), content="get_current_time")
}

///| ToolGuard tests

///|
test "ToolGuard allowlist blocks unlisted tools" {
  let tool_guard = ToolGuard::allowlist(["calculator", "datetime"])
  inspect(tool_guard.is_allowed("calculator"), content="true")
  inspect(tool_guard.is_allowed("datetime"), content="true")
  inspect(tool_guard.is_allowed("shell_exec"), content="false")
}

///|
test "ToolGuard denylist blocks listed tools" {
  let tool_guard = ToolGuard::denylist(["shell_exec", "write_file"])
  inspect(tool_guard.is_allowed("calculator"), content="true")
  inspect(tool_guard.is_allowed("shell_exec"), content="false")
  inspect(tool_guard.is_allowed("write_file"), content="false")
}

///|
test "ToolGuard size returns list length" {
  let tool_guard = ToolGuard::allowlist(["a", "b", "c"])
  inspect(tool_guard.size(), content="3")
}

///|
test "ToolGuard register allows approved tool in allowlist" {
  let tool_guard = ToolGuard::allowlist(["calculator"])
  let registry = @llm_tools.ToolRegistry::new()
  let ok = tool_guard.register(registry, CalculatorTool::new())
  inspect(ok, content="true")
}

///|
test "ToolGuard register blocks unapproved tool in allowlist" {
  let tool_guard = ToolGuard::allowlist(["something_else"])
  let registry = @llm_tools.ToolRegistry::new()
  let ok = tool_guard.register(registry, CalculatorTool::new())
  inspect(ok, content="false")
}

///|
test "ToolGuard register passes in denylist when not blocked" {
  let tool_guard = ToolGuard::denylist(["shell_exec"])
  let registry = @llm_tools.ToolRegistry::new()
  let ok = tool_guard.register(registry, CalculatorTool::new())
  inspect(ok, content="true")
}

///| ToolMiddleware tests

///|
test "with_retry returns first success" {
  let call_count : Array[Int] = [0]
  let f = fn(_input : Json) -> String {
    call_count[0] = call_count[0] + 1
    "ok"
  }
  let wrapped = with_retry(3, f)
  let result = wrapped(Json::string("test"))
  inspect(result, content="ok")
  inspect(call_count[0], content="1")
}

///|
test "with_retry retries on error" {
  let call_count : Array[Int] = [0]
  let f = fn(_input : Json) -> String {
    call_count[0] = call_count[0] + 1
    if call_count[0] < 3 {
      return "Error: retry"
    }
    "success"
  }
  let wrapped = with_retry(3, f)
  let result = wrapped(Json::string("test"))
  inspect(result, content="success")
  inspect(call_count[0], content="3")
}

///|
test "with_retry gives up after max retries" {
  let call_count : Array[Int] = [0]
  let f = fn(_input : Json) -> String {
    call_count[0] = call_count[0] + 1
    "Error: always fail"
  }
  let wrapped = with_retry(2, f)
  let result = wrapped(Json::string("test"))
  assert_true(result.has_prefix("Error"))
  inspect(call_count[0], content="3")
}

///|
test "retry_tool wrapper passes on success" {
  let tool = retry_tool(fn() { CalculatorTool::new() }, 2)
  let input : Map[String, Json] = Map([])
  input["expression"] = Json::string("10+5")
  let result = tool.run(Json::object(input))
  inspect(result, content="15")
}
