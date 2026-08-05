///|
/// RetrievalTool — RAG-based document retrieval tool for Agent.
///
/// Wraps the RAG pipeline (Embedder + VectorStore + Retriever) behind
/// the Tool trait, so an Agent can search documents as a tool call.
///
/// Usage:
/// ```moonbit nocheck
/// let store = @rag.InMemoryVectorStore::new()
/// let embedder = @rag.OpenAIEmbedder::openai_default(api_key)
/// let retriever = @rag.Retriever::new(
///   @rag.BoxedEmbedder::new(embedder),
///   @rag.BoxedVectorStore::new(store),
/// )
/// // Split documents and add to retriever
/// let splitter = @rag.RecursiveCharacterTextSplitter::new(500, 100)
/// let docs = @rag.split_documents(splitter, raw_docs)
/// retriever.add_documents(docs)
///
/// // Register as a tool
/// let tool = RetrievalTool::new(retriever, ~top_k=3, ~name="knowledge_search")
/// @tools.register_into(registry, tool)
/// ```
pub struct RetrievalTool {
  retriever : @rag.Retriever
  top_k : Int
  tool_name : String
  description_text : String
}

///|
/// Create a RetrievalTool with a pre-populated retriever.
///
/// - `retriever`: A Retriever that has already been loaded with documents
///   via `add_documents`.
/// - `top_k`: Maximum number of documents to retrieve per query (default 3).
/// - `name`: Tool name exposed to the LLM (default `"document_search"`).
/// - `description`: Custom description text. If empty, a default is generated.
pub fn RetrievalTool::new(
  retriever : @rag.Retriever,
  top_k~ : Int,
  name~ : String,
  description~ : String,
) -> RetrievalTool {
  let n = if name == "" { "document_search" } else { name }
  let desc = if description == "" {
    "Search through documents to find relevant information. Input must be a JSON object with a 'query' field containing your search query. Returns up to " +
    top_k.to_string() +
    " matching document chunks with their content."
  } else {
    description
  }
  { retriever, top_k, tool_name: n, description_text: desc }
}

///|
/// Quick constructor with default name and description.
pub fn RetrievalTool::quick(
  retriever : @rag.Retriever,
  top_k~ : Int,
) -> RetrievalTool {
  RetrievalTool::new(retriever, top_k~, name="", description="")
}

///|
pub impl Tool for RetrievalTool with fn name(self : RetrievalTool) -> String {
  self.tool_name
}

///|
pub impl Tool for RetrievalTool with fn description(self : RetrievalTool) -> String {
  self.description_text
}

///|
pub impl Tool for RetrievalTool with fn args_schema(_self : RetrievalTool) -> Json {
  tool_schema("query", "string", "The search query to find relevant documents.")
}

///|
pub impl Tool for RetrievalTool with fn run(self : RetrievalTool, input : Json) -> String {
  let query = match input {
    Json::Object(map) =>
      match map.get("query") {
        Some(Json::String(q)) => q
        _ => return "Error: missing 'query' field in input"
      }
    _ => return "Error: input is not a JSON object"
  }
  if query == "" {
    return "Error: query is empty"
  }
  let results = self.retriever.retrieve(query, self.top_k)
  if results.length() == 0 {
    return "No relevant documents found for query: " + query
  }
  // Format results as numbered chunks
  let mut formatted = ""
  for i = 0; i < results.length(); i = i + 1 {
    if i > 0 {
      formatted = formatted + "\n---\n"
    }
    formatted = formatted +
      "[Document " +
      (i + 1).to_string() +
      "] " +
      results[i]
  }
  formatted
}
