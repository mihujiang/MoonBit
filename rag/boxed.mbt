///|
/// Boxed trait objects for rag traits.
/// Pattern: each trait gets a boxed wrapper that holds a `&Trait` reference,
/// delegating calls through the trait object.

///|
/// Boxed embedder: wraps any `Embedder` implementation so it can be stored
/// as a field in structs. Delegates `embed` and `embed_batch` calls.
pub struct BoxedEmbedder {
  inner : &Embedder
}

///|
pub fn BoxedEmbedder::new(inner : &Embedder) -> BoxedEmbedder {
  { inner, }
}

///|
pub fn BoxedEmbedder::embed(
  self : BoxedEmbedder,
  text : String,
) -> Array[Double] {
  self.inner.embed(text)
}

///|
pub fn BoxedEmbedder::embed_batch(
  self : BoxedEmbedder,
  texts : Array[String],
) -> Array[Array[Double]] {
  self.inner.embed_batch(texts)
}

///|
/// Boxed vector store: wraps any `VectorStore` implementation.
pub struct BoxedVectorStore {
  inner : &VectorStore
}

///|
pub fn BoxedVectorStore::new(inner : &VectorStore) -> BoxedVectorStore {
  { inner, }
}

///|
pub fn BoxedVectorStore::add(
  self : BoxedVectorStore,
  docs : Array[EmbeddedDocument],
) -> Unit {
  self.inner.add(docs)
}

///|
pub fn BoxedVectorStore::search(
  self : BoxedVectorStore,
  query_embedding : Array[Double],
  k : Int,
) -> Array[String] {
  self.inner.search(query_embedding, k)
}

///|
pub fn BoxedVectorStore::search_max_marginal_relevance(
  self : BoxedVectorStore,
  query_embedding : Array[Double],
  k : Int,
  fetch_k : Int,
  lambda_mult : Double,
) -> Array[String] {
  self.inner.search_max_marginal_relevance(
    query_embedding, k, fetch_k, lambda_mult,
  )
}
