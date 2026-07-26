///|
/// moon-agent: MoonBit version of LangChain core library.
///
/// A type-safe, composable, embeddable AI Agent framework built on top of
/// `mizchi/llm` (LLM clients) and `colmugx/mcp` (MCP tool calling).
///
/// This root package provides only metadata. Actual functionality lives in
/// sub-packages:
///
/// - `weopqrst/agent/core` — `RunnableWrapper[I, O]` struct, the unified composable unit
/// - `weopqrst/agent/prompts` — `PromptTemplate`, `ChatPromptTemplate`
/// - `weopqrst/agent/parsers` — `OutputParser`, `JsonOutputParser`
/// - `weopqrst/agent/memory` — `Memory`, `BufferMemory`, `BufferWindowMemory`
/// - `weopqrst/agent/tools` — `Tool` trait, bridge to mizchi/llm's ToolRegistry
/// - `weopqrst/agent/chains` — `LLMChain`
/// - `weopqrst/agent/agents` — `AgentExecutor`
///
/// ## Quick start
///
/// ```moonbit nocheck
/// let prompt = @prompts.ChatPromptTemplate::new()
///   |> @prompts.ChatPromptTemplate::with_system("You are a helpful assistant.")
///   |> @prompts.ChatPromptTemplate::with_user("What is {topic}?")
///
/// let chain = @chains.LLMChain::new(model.boxed(), prompt)
///
/// let result = chain.invoke({ "topic": "MoonBit" })
/// ```
///
/// ## License
///
/// Apache-2.0
pub let version : String = "0.2.0"
