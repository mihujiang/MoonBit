///|
test "BufferMemory saves and loads messages" {
  let m = BufferMemory::new()
  m.save_message(@llm.Message::user("hello"))
  m.save_message(@llm.Message::assistant("hi"))
  let msgs = m.load_messages()
  assert_eq(msgs.length(), 2)
}

///|
test "BufferMemory clear empties history" {
  let m = BufferMemory::new()
  m.save_message(@llm.Message::user("hello"))
  m.clear()
  assert_eq(m.load_messages().length(), 0)
}

///|
test "BufferWindowMemory returns last k messages" {
  let m = BufferWindowMemory::new(2)
  m.save_message(@llm.Message::user("msg1"))
  m.save_message(@llm.Message::user("msg2"))
  m.save_message(@llm.Message::user("msg3"))
  let msgs = m.load_messages()
  assert_eq(msgs.length(), 2)
  assert_eq(msgs[0].get_text(), "msg2")
  assert_eq(msgs[1].get_text(), "msg3")
}

///|
test "BufferWindowMemory returns all when n <= k" {
  let m = BufferWindowMemory::new(5)
  m.save_message(@llm.Message::user("msg1"))
  m.save_message(@llm.Message::user("msg2"))
  let msgs = m.load_messages()
  assert_eq(msgs.length(), 2)
}

///|
test "BufferWindowMemory returns copy not reference" {
  let m = BufferWindowMemory::new(5)
  m.save_message(@llm.Message::user("msg1"))
  let msgs1 = m.load_messages()
  m.save_message(@llm.Message::user("msg2"))
  // msgs1 should still have length 1 (not affected by later save)
  assert_eq(msgs1.length(), 1)
}
