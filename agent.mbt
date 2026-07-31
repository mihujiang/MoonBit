///|
/// moon-agent: MoonBit version of LangChain core library.
///
/// A type-safe, composable, embeddable AI Agent framework built on top of
/// `mizchi/llm` (LLM clients).
///
/// This root package provides only metadata. Actual functionality lives in
/// sub-packages:
///
/// - `weopqrst/agent/core` — `RunnableWrapper[I, O]` struct, the unified composable unit
/// - `weopqrst/agent/prompts` — `PromptTemplate`, `ChatPromptTemplate`
/// - `weopqrst/agent/parsers` — `OutputParser`, `JsonOutputParser`
/// - `weopqrst/agent/memory` — `Memory`, `BufferMemory`, `BufferWindowMemory`, `SummaryMemory`
/// - `weopqrst/agent/tools` — `Tool` trait, bridge to mizchi/llm's ToolRegistry
/// - `weopqrst/agent/chains` — `LLMChain`
/// - `weopqrst/agent/agents` — `AgentExecutor`
/// - `weopqrst/agent/config` — `ChatConfig`, unified config loader (config.json or env vars)
/// - `weopqrst/agent/mcp` — MCP Client/Server for ecosystem interop
///
/// ## Quick start
///
/// ```moonbit nocheck
/// let prompt = @prompts.ChatPromptTemplate::new()
///   |> @prompts.ChatPromptTemplate::with_system("You are a helpful assistant.")
///   |> @prompts.ChatPromptTemplate::with_user("What is {topic}?")
///
/// let chain = @chains.LLMChain::new(provider, prompt)
///
/// let vars : Map[String, String] = Map([])
/// vars["topic"] = "MoonBit"
/// let result = chain.invoke(vars)
/// ```
///
/// ## Configuration
///
/// Executables can load API settings via `config.json` at project root
/// or environment variables. See `@config.load_config()`.
///
/// ## License
///
/// Apache-2.0
pub let version : String = "0.3.1"
