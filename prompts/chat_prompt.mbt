///|
/// ChatPromptTemplate builds a sequence of `@llm.Message` from role-aware
/// templates. This is moon-agent's equivalent of LangChain's
/// `ChatPromptTemplate`.
///
/// Example:
/// ```moonbit nocheck
/// let p = ChatPromptTemplate::new()
///   |> ChatPromptTemplate::with_system("You are a helpful assistant.")
///   |> ChatPromptTemplate::with_user("Translate to {lang}: {text}")
///
/// let msgs = p.render({ "lang": "Chinese", "text": "hello" })
/// ```
pub struct ChatPromptTemplate {
  system_template : String?
  user_templates : Array[String]
  assistant_templates : Array[String]
}

///|
pub fn ChatPromptTemplate::new() -> ChatPromptTemplate {
  { system_template: None, user_templates: [], assistant_templates: [] }
}

///|
/// Set or replace the system message template.
pub fn ChatPromptTemplate::with_system(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  { ..self, system_template: Some(template) }
}

///|
/// Append a user message template.
pub fn ChatPromptTemplate::with_user(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  self.user_templates.push(template)
  self
}

///|
/// Append an assistant message template (useful for few-shot prompting).
pub fn ChatPromptTemplate::with_assistant(
  self : ChatPromptTemplate,
  template : String,
) -> ChatPromptTemplate {
  self.assistant_templates.push(template)
  self
}

///|
/// Render all templates into a list of `@llm.Message` using `vars`.
///
/// Templates are rendered in order: system (if any), then user/assistant
/// templates in their insertion order. For accurate alternation control,
/// use `with_message` instead.
pub fn ChatPromptTemplate::render(
  self : ChatPromptTemplate,
  vars : Map[String, String],
) -> Array[@llm.Message] {
  let messages : Array[@llm.Message] = []
  match self.system_template {
    Some(tpl) => {
      let pt = PromptTemplate::new(tpl)
      messages.push(@llm.Message::system(pt.render(vars)))
    }
    None => ()
  }
  for tpl in self.user_templates {
    let pt = PromptTemplate::new(tpl)
    messages.push(@llm.Message::user(pt.render(vars)))
  }
  for tpl in self.assistant_templates {
    let pt = PromptTemplate::new(tpl)
    messages.push(@llm.Message::assistant(pt.render(vars)))
  }
  messages
}
