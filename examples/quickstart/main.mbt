///|
/// moon-agent quickstart: minimal LLMChain invocation.
///
/// This example demonstrates:
/// 1. Loading unified config from `config.json` or env vars
/// 2. Building a ChatPromptTemplate with system + user messages
/// 3. Constructing an LLMChain with an OpenAI-compatible provider
/// 4. Invoking the chain with template variables
///
/// Configuration:
///   Create `config.json` at project root (see `config.example.json`):
///   ```json
///   {
///     "api_key": "sk-...",
///     "base_url": "https://api.deepseek.com",
///     "model": "deepseek-chat"
///   }
///   ```
///   Or set env vars: OPENAI_API_KEY, OPENAI_BASE_URL (optional), OPENAI_MODEL (optional)
///
/// Run with:
///   moon run examples/quickstart --target js
fn main {
  // Load config from config.json or env vars (unified with cmd/chat)
  let config = match @config.load_config() {
    Some(c) => c
    None => {
      println("Please configure API access first.")
      println(
        "Create `config.json` at project root (see `config.example.json`)",
      )
      println(
        "or set env vars: OPENAI_API_KEY, OPENAI_BASE_URL (optional), OPENAI_MODEL (optional)",
      )
      return
    }
  }

  // Build the prompt template (system + user, {topic} is a placeholder)
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_system("You are a helpful assistant.")
    |> @prompts.ChatPromptTemplate::with_user(
      "What is {topic}? Answer in one sentence.",
    )

  // Render for demonstration
  let vars : Map[String, String] = Map([])
  vars["topic"] = "MoonBit"
  let messages = prompt.render(vars)
  for msg in messages {
    println("[" + @llm.Role::to_string(msg.role) + "] " + msg.get_text())
  }

  // Build provider from config (supports DeepSeek, OpenAI, any OpenAI-compatible endpoint)
  let model = @openai.OpenAIProvider::new_compat(
    config.base_url,
    config.model,
    api_key=config.api_key,
    max_tokens=config.max_tokens,
    system_prompt=config.system_prompt,
  )
  let chain = @chains.LLMChain::new(@llm.BoxedProvider::new(model), prompt)

  println("\nEndpoint: " + config.base_url + " | Model: " + config.model)
  println("\nAssistant:")
  let result = chain.invoke(vars)
  println(result)
}
