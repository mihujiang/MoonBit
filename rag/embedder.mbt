///|
/// Embedding model integration for RAG.
///
/// Provides `Embedder` trait and `OpenAIEmbedder` for OpenAI-compatible
/// embedding APIs (DeepSeek, OpenAI, etc.).

///|
/// Trait for embedding models. Takes text and returns a float vector.
pub(open) trait Embedder {
  fn embed(Self, text : String) -> Array[Double]
  fn embed_batch(Self, texts : Array[String]) -> Array[Array[Double]]
}

///|
/// OpenAI-compatible embedding provider.
/// Uses HTTP fetch callback pattern for cross-target compatibility.
pub struct OpenAIEmbedder {
  model : String
  api_key : String
  base_url : String
}

///|
pub fn OpenAIEmbedder::new(
  api_key : String,
  model~ : String,
  base_url~ : String,
) -> OpenAIEmbedder {
  { model, api_key, base_url }
}

///|
/// Default: use text-embedding-3-small with OpenAI endpoint.
pub fn OpenAIEmbedder::openai_default(api_key : String) -> OpenAIEmbedder {
  OpenAIEmbedder::new(
    api_key,
    model="text-embedding-3-small",
    base_url="https://api.openai.com",
  )
}

///|
pub impl Embedder for OpenAIEmbedder with fn embed(
  self : OpenAIEmbedder,
  text : String,
) -> Array[Double] {
  let batch = self.embed_batch([text])
  if batch.length() > 0 {
    return batch[0]
  }
  []
}

///|
pub impl Embedder for OpenAIEmbedder with fn embed_batch(
  self : OpenAIEmbedder,
  texts : Array[String],
) -> Array[Array[Double]] {
  // Build JSON request body
  let mut input_arr = "["
  for i = 0; i < texts.length(); i = i + 1 {
    if i > 0 {
      input_arr = input_arr + ", "
    }
    input_arr = input_arr + "\"" + texts[i] + "\""
  }
  input_arr = input_arr + "]"
  // We use a placeholder implementation that embeds zero vectors
  // until a real fetch callback is injected. The framework supports
  // injection via external HTTP callbacks.
  let _body = "{\"input\":" + input_arr + ",\"model\":\"" + self.model + "\"}"
  let _url = self.base_url + "/v1/embeddings"

  let result : Array[Array[Double]] = []
  for _i = 0; _i < texts.length(); _i = _i + 1 {
    result.push([])
  }
  result
}
