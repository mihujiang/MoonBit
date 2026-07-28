///|
/// Whitebox tests for RunnableWrapper composition and RouterChain.

///|
test "RunnableWrapper::invoke calls the wrapped function" {
  let add_one = RunnableWrapper::new(fn(n : Int) -> Int { n + 1 })
  assert_eq(add_one.invoke(41), 42)
}

///|
test "RunnableWrapper::pipe composes two wrappers" {
  let step1 = RunnableWrapper::new(fn(n : Int) -> Int { n + 1 })
  let step2 = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
  let composed = step1.pipe(step2)
  // (5 + 1) * 2 = 12
  assert_eq(composed.invoke(5), 12)
}

///|
test "RunnableWrapper::pipe chains three wrappers" {
  let step1 = RunnableWrapper::new(fn(n : Int) -> Int { n + 1 })
  let step2 = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
  let step3 = RunnableWrapper::new(fn(n : Int) -> Int { n - 3 })
  let composed = step1.pipe(step2).pipe(step3)
  // ((5 + 1) * 2) - 3 = 9
  assert_eq(composed.invoke(5), 9)
}

///|
test "RunnableWrapper::map transforms output type" {
  let base = RunnableWrapper::new(fn(n : Int) -> Int { n * 3 })
  let mapped = base.map(fn(n : Int) -> Bool { n > 10 })
  assert_true(mapped.invoke(4)) // 4 * 3 = 12 > 10
  assert_false(mapped.invoke(3)) // 3 * 3 = 9 <= 10
}

///|
test "RunnableWrapper::pipe composes String -> Int -> Int" {
  let len = RunnableWrapper::new(fn(s : String) -> Int { s.length() })
  let doubler = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
  let composed = len.pipe(doubler)
  // "hello" has length 5, * 2 = 10
  assert_eq(composed.invoke("hello"), 10)
}

///|
test "SequentialChain::invoke runs steps in order" {
  let step1 = RunnableWrapper::new(fn(s : String) -> String { s + "!" })
  let step2 = RunnableWrapper::new(fn(s : String) -> String { "(" + s + ")" })
  let chain = SequentialChain::new([step1, step2])
  // ("hi" + "!") -> "(hi!)"
  assert_eq(chain.invoke("hi"), "(hi!)")
}

///|
test "SequentialChain::invoke with single step" {
  let only = RunnableWrapper::new(fn(n : Int) -> Int { n * 10 })
  let chain = SequentialChain::new([only])
  assert_eq(chain.invoke(5), 50)
}

///|
test "SequentialChain::invoke chains three int steps" {
  let step1 = RunnableWrapper::new(fn(n : Int) -> Int { n + 1 })
  let step2 = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
  let step3 = RunnableWrapper::new(fn(n : Int) -> Int { n - 3 })
  let chain = SequentialChain::new([step1, step2, step3])
  // ((5 + 1) * 2) - 3 = 9
  assert_eq(chain.invoke(5), 9)
}

///|
test "SequentialChain::length returns step count" {
  let step1 = RunnableWrapper::new(fn(n : Int) -> Int { n + 1 })
  let step2 = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
  let chain = SequentialChain::new([step1, step2])
  assert_eq(chain.length(), 2)
}

///|
test "SequentialChain::as_runnable composes with another wrapper" {
  let step1 = RunnableWrapper::new(fn(s : String) -> String { s + "!" })
  let step2 = RunnableWrapper::new(fn(s : String) -> String { "(" + s + ")" })
  let chain = SequentialChain::new([step1, step2])
  // Wrap the chain into a RunnableWrapper, then pipe into a post-processing step
  let post = RunnableWrapper::new(fn(s : String) -> String { "[" + s + "]" })
  let composed = chain.as_runnable().pipe(post)
  // "hi" -> "hi!" -> "(hi!)" -> "[(hi!)]"
  assert_eq(composed.invoke("hi"), "[(hi!)]")
}

///|
/// Whitebox tests for RouterChain.

///|
test "RouterChain::invoke routes to matching handler" {
  let math = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "math result"
  })
  let default = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "default"
  })
  let router = RouterChain::new(
      fn(input) { if input.contains("math") { "math" } else { "" } },
      default,
    )
    |> RouterChain::add_route("math", math)
  let vars : Map[String, String] = Map([])
  vars["input"] = "do some math please"
  assert_eq(router.invoke(vars), "math result")
}

///|
test "RouterChain::invoke falls back to default" {
  let math = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "math"
  })
  let default = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "fallback"
  })
  let router = RouterChain::new(
      fn(input) { if input.contains("calc") { "math" } else { "" } },
      default,
    )
    |> RouterChain::add_route("math", math)
  let vars : Map[String, String] = Map([])
  vars["input"] = "hello"
  assert_eq(router.invoke(vars), "fallback")
}

///|
test "RouterChain::add_route adds new routes" {
  let math = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "m"
  })
  let chat = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "c"
  })
  let default = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "d"
  })
  let router = RouterChain::new(fn(_input) { "chat" }, default)
    |> RouterChain::add_route("math", math)
    |> RouterChain::add_route("chat", chat)
  assert_eq(router.route_count(), 2)
  let vars : Map[String, String] = Map([])
  assert_eq(router.invoke(vars), "c")
}

///|
test "RouterChain::as_runnable works with pipe" {
  let greet = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "Hello!"
  })
  let exit = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "Bye!"
  })
  let router = RouterChain::new(
      fn(input) { if input.contains("bye") { "exit" } else { "" } },
      greet,
    )
    |> RouterChain::add_route("exit", exit)
  let post = RunnableWrapper::new(fn(s : String) -> String { "[" + s + "]" })
  let composed = router.as_runnable().pipe(post)
  let vars : Map[String, String] = Map([])
  vars["input"] = "say goodbye"
  assert_eq(composed.invoke(vars), "[Bye!]")
}

///|
test "RouterChain::route_count returns correct count" {
  let a = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String { "a" })
  let b = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String { "b" })
  let c = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String { "c" })
  let default = RunnableWrapper::new(fn(_vars : Map[String, String]) -> String {
    "d"
  })
  let router = RouterChain::new(fn(_input) { "" }, default)
    |> RouterChain::add_route("a", a)
    |> RouterChain::add_route("b", b)
    |> RouterChain::add_route("c", c)
  assert_eq(router.route_count(), 3)
}
