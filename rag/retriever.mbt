///|
/// Retriever — combines embedder + vector store for document retrieval.
///
/// Uses boxed trait wrappers (`BoxedEmbedder`, `BoxedVectorStore`) so any
/// embedder or store implementation can be plugged in at runtime.

///|
/// A retriever that uses an embedder to encode queries and a vector store
/// for similarity search. Uses boxed trait wrappers for runtime polymorphism.
pub struct Retriever {
  embedder : BoxedEmbedder
  store : BoxedVectorStore
}

///|
/// Create a retriever with the given embedder and vector store.
pub fn Retriever::new(
  embedder : BoxedEmbedder,
  store : BoxedVectorStore,
) -> Retriever {
  { embedder, store }
}

///|
/// Add documents to the vector store after embedding them.
pub fn Retriever::add_documents(
  self : Retriever,
  docs : Array[Document],
) -> Unit {
  let texts : Array[String] = []
  for i = 0; i < docs.length(); i = i + 1 {
    texts.push(docs[i].content)
  }
  let embeddings = self.embedder.embed_batch(texts)
  let embedded_docs : Array[EmbeddedDocument] = []
  for i = 0; i < docs.length(); i = i + 1 {
    if i < embeddings.length() {
      embedded_docs.push(EmbeddedDocument::new(docs[i].content, embeddings[i]))
    }
  }
  if embedded_docs.length() > 0 {
    self.store.add(embedded_docs)
  }
}

///|
/// Retrieve top-k relevant documents for a query.
pub fn Retriever::retrieve(
  self : Retriever,
  query : String,
  k : Int,
) -> Array[String] {
  let query_embedding = self.embedder.embed(query)
  if query_embedding.length() == 0 {
    return []
  }
  self.store.search(query_embedding, k)
}

///|
/// Retrieve with MMR diversity. Higher lambda = more relevance, lower = more diversity.
pub fn Retriever::retrieve_mmr(
  self : Retriever,
  query : String,
  k : Int,
  fetch_k : Int,
  lambda_mult : Double,
) -> Array[String] {
  let query_embedding = self.embedder.embed(query)
  if query_embedding.length() == 0 {
    return []
  }
  self.store.search_max_marginal_relevance(
    query_embedding, k, fetch_k, lambda_mult,
  )
}
