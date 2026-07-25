///|
/// ChatPromptTemplate builds a sequence of `@llm.Message` from role-aware
/// templates. This is moon-agent's equivalent of LangChain's
/// `ChatPromptTemplate`.
///
/// Templates are stored in a single ordered array, preserving insertion
/// order at render time. This fixes two issues from the previous design:
/// 1. Aliasing bug: `with_system` used structural update but `with_user`/
///    `with_assistant` mutated in place, sharing array references.
/// 2. Message ordering: all system → all user → all assistant was wrong
///    for few-shot prompts that need user/assistant alternation.
///
/// Example:
/// ```moonbit nocheck
/// let p = ChatPromptTemplate::new()
///   |> ChatPromptTemplate::with_system("You are a helpful assistant.")
///   |> ChatPromptTemplate::with_user("Translate to {lang}: {text}")
///
/// let msgs = p.render(Map([("lang", "Chinese"), ("text", "hello")]))
/// ```
pub struct ChatPromptTemplate {
  templates : Array[(@llm.Role, String)]
}

///|
pub fn ChatPromptTemplate::new() -> ChatPromptTemplate {
  { templates: [] }
}

///|
/// Append a system message template.
pub fn ChatPromptTemplate::with_system(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  self.templates.push((@llm.Role::System, template))
  self
}

///|
/// Append a user message template.
pub fn ChatPromptTemplate::with_user(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  self.templates.push((@llm.Role::User, template))
  self
}

///|
/// Append an assistant message template (useful for few-shot prompting).
pub fn ChatPromptTemplate::with_assistant(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  self.templates.push((@llm.Role::Assistant, template))
  self
}

///|
/// Render all templates into a list of `@llm.Message` using `vars`.
///
/// Templates are rendered in insertion order, so few-shot patterns like
/// system → user → assistant → user → assistant work correctly.
pub fn ChatPromptTemplate::render(
  self : ChatPromptTemplate,
  vars : Map[String, String],
) -> Array[@llm.Message] {
  let messages : Array[@llm.Message] = []
  for entry in self.templates {
    let role = entry.0
    let tpl = entry.1
    let pt = PromptTemplate::new(tpl)
    let text = pt.render(vars)
    match role {
      @llm.Role::System => messages.push(@llm.Message::system(text))
      @llm.Role::User => messages.push(@llm.Message::user(text))
      @llm.Role::Assistant => messages.push(@llm.Message::assistant(text))
      _ => messages.push(@llm.Message::user(text))
    }
  }
  messages
}
