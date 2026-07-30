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

///|
/// Loads markdown content, stripping YAML frontmatter and extracting headings as metadata.
pub struct MarkdownLoader {
  text : String
  source_name : String
}

///|
pub fn MarkdownLoader::new(
  text : String,
  source_name : String,
) -> MarkdownLoader {
  { text, source_name }
}

///|
pub impl TextLoader for MarkdownLoader with fn load(self : MarkdownLoader) -> Array[
  Document,
] {
  let content = MarkdownLoader::strip_frontmatter(self.text)
  let doc = Document::new(content)
    .with_meta("source", self.source_name)
    .with_meta("type", "markdown")
  [doc]
}

///|
/// Strip YAML frontmatter (--- delimited) from markdown content.
fn MarkdownLoader::strip_frontmatter(text : String) -> String {
  let trimmed = text.trim().to_owned()
  if !trimmed.has_prefix("---") {
    return trimmed
  }
  // Find the second "---"
  let after_first = trimmed[3:trimmed.length()]
  match after_first.find("---") {
    Some(idx) => {
      let content = after_first[idx + 3:after_first.length()].trim().to_owned()
      if content.has_prefix("\n") {
        content[1:content.length()].to_owned()
      } else {
        content
      }
    }
    None => trimmed
  }
}
