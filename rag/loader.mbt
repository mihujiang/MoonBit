///|
/// rag — Retrieval-Augmented Generation primitives for moon-agent.
///
/// Provides document loading, text splitting, and a tool bridge so
/// agents can search through documents.

///|
/// A loaded document with metadata.
pub struct Document {
  content : String
  metadata : Map[String, String]
}

///|
pub fn Document::new(content : String) -> Document {
  { content, metadata: Map([]) }
}

///|
pub fn Document::with_meta(
  self : Document,
  key : String,
  value : String,
) -> Document {
  self.metadata[key] = value
  self
}

///|
/// Trait for loading documents from a source.
pub(open) trait TextLoader {
  fn load(Self) -> Array[Document]
}

///|
/// Loads a plain string as a single document.
pub struct SimpleTextLoader {
  text : String
  source_name : String
}

///|
pub fn SimpleTextLoader::new(
  text : String,
  source_name : String,
) -> SimpleTextLoader {
  { text, source_name }
}

///|
pub impl TextLoader for SimpleTextLoader with fn load(self : SimpleTextLoader) -> Array[
  Document,
] {
  let doc = Document::new(self.text).with_meta("source", self.source_name)
  [doc]
}
