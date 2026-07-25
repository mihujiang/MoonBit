///|
test "PromptTemplate::render replaces single variable" {
  let t = PromptTemplate::new("Hello, {name}!")
  let vars : Map[String, String] = Map([])
  vars["name"] = "World"
  assert_eq(t.render(vars), "Hello, World!")
}

///|
test "PromptTemplate::render keeps unknown variables" {
  let t = PromptTemplate::new("Hello, {name}!")
  let vars : Map[String, String] = Map([])
  assert_eq(t.render(vars), "Hello, {name}!")
}

///|
test "PromptTemplate::render_one" {
  let t = PromptTemplate::new("Hello, {name}!")
  assert_eq(t.render_one("name", "MoonBit"), "Hello, MoonBit!")
}

///|
test "PromptTemplate::variables extracts all names" {
  let t = PromptTemplate::new("{a} and {b}")
  let vars = t.variables()
  assert_eq(vars.length(), 2)
  assert_eq(vars[0], "a")
  assert_eq(vars[1], "b")
}

///|
test "PromptTemplate::render handles multiple variables" {
  let t = PromptTemplate::new("{greeting}, {name}! You are {age}.")
  let vars : Map[String, String] = Map([])
  vars["greeting"] = "Hi"
  vars["name"] = "Alice"
  vars["age"] = "30"
  assert_eq(t.render(vars), "Hi, Alice! You are 30.")
}

///|
test "ChatPromptTemplate preserves insertion order" {
  let p = ChatPromptTemplate::new()
    |> ChatPromptTemplate::with_system("system msg")
    |> ChatPromptTemplate::with_user("user msg 1")
    |> ChatPromptTemplate::with_assistant("assistant msg")
    |> ChatPromptTemplate::with_user("user msg 2")
  let vars : Map[String, String] = Map([])
  let msgs = p.render(vars)
  assert_eq(msgs.length(), 4)
  assert_eq(@llm.Role::to_string(msgs[0].role), "system")
  assert_eq(@llm.Role::to_string(msgs[1].role), "user")
  assert_eq(@llm.Role::to_string(msgs[2].role), "assistant")
  assert_eq(@llm.Role::to_string(msgs[3].role), "user")
}
