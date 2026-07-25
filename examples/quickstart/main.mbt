///|
/// moon-agent quickstart: minimal LLMChain invocation.
///
/// This example demonstrates:
/// 1. Building a ChatPromptTemplate with system + user messages
/// 2. Constructing an LLMChain with an OpenAI provider
/// 3. Invoking the chain with template variables
///
/// Run with:
///   $env:OPENAI_API_KEY = "sk-..."
///   moon run examples/quickstart
fn main {
  // Read API key from environment
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  // Render the prompt for demonstration
  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_system("You are a helpful assistant.")
    |> @prompts.ChatPromptTemplate::with_user(
      "What is {topic}? Answer in one sentence.",
    )
  let vars : Map[String, String] = Map([])
  vars["topic"] = "MoonBit"
  let messages = prompt.render(vars)
  for msg in messages {
    println("[" + @llm.Role::to_string(msg.role) + "] " + msg.get_text())
  }
  // If API key is available, call the model
  match api_key {
    Some(key) => {
      let model = @openai.OpenAIProvider::new(key)
      let chain = @chains.LLMChain::new(@llm.BoxedProvider::new(model), prompt)
      let result = chain.invoke(vars)
      println("\nAssistant:")
      println(result)
    }
    None =>
      println(
        "Please set OPENAI_API_KEY environment variable to run the full demo.",
      )
  }
}
