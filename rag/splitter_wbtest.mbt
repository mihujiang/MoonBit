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

///|
test "MarkdownLoader strips frontmatter" {
  let md = "---\ntitle: Test\n---\n\n# Heading\n\nContent here."
  let loader = MarkdownLoader::new(md, "test.md")
  let docs = loader.load()
  inspect(docs.length(), content="1")
  assert_true(docs[0].content.contains("Content here"))
  assert_true(docs[0].metadata.get("type") == Some("markdown"))
}

///|
test "MarkdownLoader without frontmatter passes through" {
  let md = "# Plain markdown\n\nNo frontmatter here."
  let loader = MarkdownLoader::new(md, "test.md")
  let docs = loader.load()
  inspect(docs.length(), content="1")
  assert_true(docs[0].content.contains("Plain markdown"))
}

///|
test "InMemoryVectorStore add and search" {
  let store = InMemoryVectorStore::new()
  let doc1 = EmbeddedDocument::new("hello world", [1.0, 0.0, 0.0])
  let doc2 = EmbeddedDocument::new("goodbye world", [0.0, 1.0, 0.0])
  store.add([doc1, doc2])
  let results = store.search([1.0, 0.1, 0.0], 2)
  inspect(results.length(), content="2")
  // First result should be doc1 (higher cosine similarity)
  inspect(results[0], content="hello world")
}

///|
test "InMemoryVectorStore search with empty store" {
  let store = InMemoryVectorStore::new()
  let results = store.search([1.0, 0.0], 1)
  inspect(results.length(), content="0")
}

///|
test "InMemoryVectorStore MMR diversity" {
  let store = InMemoryVectorStore::new()
  let doc1 = EmbeddedDocument::new("doc1", [1.0, 0.0, 0.0])
  let doc2 = EmbeddedDocument::new("doc2", [0.9, 0.1, 0.0])
  let doc3 = EmbeddedDocument::new("doc3", [0.0, 1.0, 0.0])
  store.add([doc1, doc2, doc3])
  // With high lambda, should prefer relevance (doc1, doc2)
  let results = store.search_max_marginal_relevance([1.0, 0.0, 0.0], 3, 5, 0.9)
  inspect(results.length(), content="3")
  // doc1 should be first (closest to query)
  inspect(results[0], content="doc1")
}

///|
test "cosine similarity same vector returns 1" {
  let sim = InMemoryVectorStore::cosine_similarity([1.0, 0.0], [1.0, 0.0])
  assert_true(sim > 0.99)
}

///|
test "cosine similarity orthogonal returns 0" {
  let sim = InMemoryVectorStore::cosine_similarity([1.0, 0.0], [0.0, 1.0])
  assert_true(sim < 0.01)
}
