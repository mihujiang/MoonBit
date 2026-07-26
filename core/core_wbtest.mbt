///|
/// Whitebox tests for RunnableWrapper composition (pipe, map).

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
