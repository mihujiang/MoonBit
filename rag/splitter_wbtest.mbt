///|
/// White-box tests for RAG text splitter.

///|
test "RecursiveCharacterTextSplitter splits by paragraph" {
  let splitter = RecursiveCharacterTextSplitter::new(25, 0)
  let text = "Hello world.\n\nThis is paragraph two."
  let chunks = splitter.split_text(text)
  inspect(chunks.length(), content="2")
}

///|
test "RecursiveCharacterTextSplitter small text returns one chunk" {
  let splitter = RecursiveCharacterTextSplitter::new(500, 0)
  let chunks = splitter.split_text("short text")
  inspect(chunks.length(), content="1")
}

///|
test "SimpleTextLoader creates document" {
  let loader = SimpleTextLoader::new("hello", "test.txt")
  let docs = loader.load()
  inspect(docs.length(), content="1")
  inspect(docs[0].content, content="hello")
}
