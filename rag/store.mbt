///|
/// Vector store interface and in-memory implementation for RAG.
///
/// Provides `VectorStore` trait and `InMemoryVectorStore` with
/// cosine similarity search.

///|
/// A document chunk with its embedding vector.
pub(all) struct EmbeddedDocument {
  content : String
  embedding : Array[Double]
}

///|
pub fn EmbeddedDocument::new(
  content : String,
  embedding : Array[Double],
) -> EmbeddedDocument {
  { content, embedding }
}

///|
/// Trait for vector stores. Supports adding documents with embeddings
/// and similarity search.
pub(open) trait VectorStore {
  fn add(Self, docs : Array[EmbeddedDocument]) -> Unit
  fn search_max_marginal_relevance(Self, query_embedding : Array[Double], k : Int, fetch_k : Int, lambda_mult : Double) -> Array[String]
  fn search(Self, query_embedding : Array[Double], k : Int) -> Array[String]
}

///|
/// Simple in-memory vector store with cosine similarity.
pub struct InMemoryVectorStore {
  store : Array[EmbeddedDocument]
}

///|
pub fn InMemoryVectorStore::new() -> InMemoryVectorStore {
  { store: [] }
}

///|
pub impl VectorStore for InMemoryVectorStore with fn add(
  self : InMemoryVectorStore,
  docs : Array[EmbeddedDocument],
) -> Unit {
  for i = 0; i < docs.length(); i = i + 1 {
    self.store.push(docs[i])
  }
}

///|
pub impl VectorStore for InMemoryVectorStore with fn search(
  self : InMemoryVectorStore,
  query_embedding : Array[Double],
  k : Int,
) -> Array[String] {
  InMemoryVectorStore::search_max_marginal_relevance(
    self,
    query_embedding,
    k,
    k * 4,
    1.0,
  )
}

///|
pub impl VectorStore for InMemoryVectorStore with fn search_max_marginal_relevance(
  self : InMemoryVectorStore,
  query_embedding : Array[Double],
  k : Int,
  fetch_k : Int,
  lambda_mult : Double,
) -> Array[String] {
  if self.store.length() == 0 {
    return []
  }
  let actual_fetch = if fetch_k > self.store.length() {
    self.store.length()
  } else {
    fetch_k
  }
  // Compute cosine similarity for all docs
  let scores : Array[(Int, Double)] = []
  for i = 0; i < self.store.length(); i = i + 1 {
    let sim = InMemoryVectorStore::cosine_similarity(
      query_embedding,
      self.store[i].embedding,
    )
    scores.push((i, sim))
  }
  // Sort by score descending
  InMemoryVectorStore::sort_scores(scores)
  // Get top fetch_k
  let top : Array[(Int, Double)] = []
  for i = 0; i < actual_fetch; i = i + 1 {
    top.push(scores[i])
  }
  // MMR selection
  InMemoryVectorStore::mmr_select(self, top, k, lambda_mult)
}

///|
fn InMemoryVectorStore::cosine_similarity(
  a : Array[Double],
  b : Array[Double],
) -> Double {
  let mut dot = 0.0
  let mut norm_a = 0.0
  let mut norm_b = 0.0
  let len = if a.length() < b.length() { a.length() } else { b.length() }
  for i = 0; i < len; i = i + 1 {
    dot = dot + a[i] * b[i]
    norm_a = norm_a + a[i] * a[i]
    norm_b = norm_b + b[i] * b[i]
  }
  if norm_a == 0.0 || norm_b == 0.0 {
    return 0.0
  }
  dot / (norm_a.sqrt() * norm_b.sqrt())
}

///|
/// Simple sort using bubble sort (fine for small stores).
fn InMemoryVectorStore::sort_scores(scores : Array[(Int, Double)]) -> Unit {
  let n = scores.length()
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n - i - 1; j = j + 1 {
      if scores[j].1 < scores[j + 1].1 {
        let temp = scores[j]
        scores[j] = scores[j + 1]
        scores[j + 1] = temp
      }
    }
  }
}

///|
/// MMR selection: greedily select documents that maximize relevance while minimizing redundancy.
fn InMemoryVectorStore::mmr_select(
  self : InMemoryVectorStore,
  candidates : Array[(Int, Double)],
  k : Int,
  lambda_mult : Double,
) -> Array[String] {
  let selected_idxs : Array[Int] = []
  let selected : Array[String] = []
  let n = candidates.length()
  for _step = 0; _step < k; _step = _step + 1 {
    if _step >= n {
      break
    }
    let mut best_idx = -1
    let mut best_score = -999999.0
    for i = 0; i < n; i = i + 1 {
      // Check if already selected
      let mut already_selected = false
      for j = 0; j < selected_idxs.length(); j = j + 1 {
        if selected_idxs[j] == candidates[i].0 {
          already_selected = true
          break
        }
      }
      if already_selected {
        continue
      }
      // Compute maximal similarity to already selected
      let query_sim = candidates[i].1
      let mut max_sim_to_selected = 0.0
      for j = 0; j < selected_idxs.length(); j = j + 1 {
        let sim = InMemoryVectorStore::cosine_similarity(
          self.store[candidates[i].0].embedding,
          self.store[selected_idxs[j]].embedding,
        )
        if sim > max_sim_to_selected {
          max_sim_to_selected = sim
        }
      }
      let mmr = lambda_mult * query_sim - (1.0 - lambda_mult) * max_sim_to_selected
      if mmr > best_score {
        best_score = mmr
        best_idx = candidates[i].0
      }
    }
    if best_idx < 0 {
      break
    }
    selected_idxs.push(best_idx)
    selected.push(self.store[best_idx].content)
  }
  selected
}
