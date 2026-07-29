///|
/// Text splitting primitives for RAG.
///
/// Provides `TextSplitter` trait and a `RecursiveCharacterTextSplitter`
/// that recursively splits by separators (paragraph, sentence, word)
/// to keep chunks within a target size.

///|
pub(open) trait TextSplitter {
  fn split_text(Self, text : String) -> Array[String]
}

///|
/// Splits text by a list of separators recursively, trying to keep
/// each chunk under `chunk_size` characters.
pub struct RecursiveCharacterTextSplitter {
  chunk_size : Int
  chunk_overlap : Int
  separators : Array[String]
}

///|
pub fn RecursiveCharacterTextSplitter::new(
  chunk_size : Int,
  chunk_overlap : Int,
) -> RecursiveCharacterTextSplitter {
  {
    chunk_size,
    chunk_overlap,
    separators: ["\n\n", "\n", ". ", "。", " ", ""],
  }
}

///|
pub fn RecursiveCharacterTextSplitter::with_separators(
  self : RecursiveCharacterTextSplitter,
  separators : Array[String],
) -> RecursiveCharacterTextSplitter {
  { ..self, separators, }
}

///|
pub impl TextSplitter for RecursiveCharacterTextSplitter with fn split_text(
  self : RecursiveCharacterTextSplitter,
  text : String,
) -> Array[String] {
  RecursiveCharacterTextSplitter::split_recursive(self, text, 0)
}

///|
fn RecursiveCharacterTextSplitter::split_recursive(
  self : RecursiveCharacterTextSplitter,
  text : String,
  sep_index : Int,
) -> Array[String] {
  if text.length() <= self.chunk_size {
    return [text]
  }
  if sep_index >= self.separators.length() {
    return RecursiveCharacterTextSplitter::split_by_chunk_size(self, text)
  }
  let sep = self.separators[sep_index]
  if sep == "" {
    return RecursiveCharacterTextSplitter::split_by_chunk_size(self, text)
  }
  let parts = RecursiveCharacterTextSplitter::split_string(text, sep)
  if parts.length() <= 1 {
    return RecursiveCharacterTextSplitter::split_recursive(
      self,
      text,
      sep_index + 1,
    )
  }
  RecursiveCharacterTextSplitter::merge_chunks(self, parts, sep_index)
}

///|
fn RecursiveCharacterTextSplitter::split_string(
  text : String,
  sep : String,
) -> Array[String] {
  let sep_len = sep.length()
  let text_len = text.length()
  if sep_len == 0 {
    let result : Array[String] = []
    for i = 0; i < text_len; i = i + 1 {
      result.push(text[i:i + 1].to_owned())
    }
    return result
  }
  let result : Array[String] = []
  let mut pos = 0
  while pos < text_len {
    let found = text[pos:text_len].find(sep)
    match found {
      Some(idx) => {
        result.push(text[pos:pos + idx].to_owned())
        pos = pos + idx + sep_len
      }
      None => {
        result.push(text[pos:text_len].to_owned())
        pos = text_len
      }
    }
  }
  result
}

///|
fn RecursiveCharacterTextSplitter::merge_chunks(
  self : RecursiveCharacterTextSplitter,
  parts : Array[String],
  sep_index : Int,
) -> Array[String] {
  let chunks : Array[String] = []
  let mut current = ""
  let sep = self.separators[sep_index]
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i].trim().to_owned()
    if part == "" {
      continue
    }
    let candidate = if current == "" { part } else { current + sep + part }
    if candidate.length() <= self.chunk_size {
      current = candidate
    } else {
      if current != "" {
        chunks.push(current)
      }
      if part.length() > self.chunk_size {
        let sub_chunks = RecursiveCharacterTextSplitter::split_recursive(
          self,
          part,
          sep_index + 1,
        )
        for j = 0; j < sub_chunks.length(); j = j + 1 {
          chunks.push(sub_chunks[j])
        }
        current = ""
      } else {
        current = part
      }
    }
  }
  if current != "" {
    chunks.push(current)
  }
  chunks
}

///|
fn RecursiveCharacterTextSplitter::split_by_chunk_size(
  self : RecursiveCharacterTextSplitter,
  text : String,
) -> Array[String] {
  let chunks : Array[String] = []
  let text_len = text.length()
  let mut pos = 0
  while pos < text_len {
    let end = if pos + self.chunk_size > text_len {
      text_len
    } else {
      pos + self.chunk_size
    }
    chunks.push(text[pos:end].to_owned())
    pos = end
  }
  chunks
}

///|
/// Convenience: split a document's content and return new documents.
pub fn[T : TextSplitter] split_documents(
  splitter : T,
  docs : Array[Document],
) -> Array[Document] {
  let result : Array[Document] = []
  for i = 0; i < docs.length(); i = i + 1 {
    let d = docs[i]
    let chunks = splitter.split_text(d.content)
    for j = 0; j < chunks.length(); j = j + 1 {
      result.push(Document::new(chunks[j]))
    }
  }
  result
}
