# moon-agent Usage Guide

> GitHub-friendly quick guide. For the full manual (Chinese), see [../文件/使用手册.md](../文件/使用手册.md).

---

## Quickstart (< 2 min)

### 1. Configure API access

Copy the template and fill in your API key:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
OPENAI_API_KEY=sk-your-key-here
OPENAI_BASE_URL=https://api.deepseek.com   # or https://api.openai.com
OPENAI_MODEL=deepseek-chat                  # or gpt-4o
```

Any OpenAI-compatible endpoint works (DeepSeek, OpenRouter, Ollama, vLLM).

### 2. Start chatting (REPL)

```bash
moon run cmd/chat --target js
```

```
=== moon-agent chat v0.10.0 ===
Endpoint: https://api.deepseek.com | Model: deepseek-chat
Type /help for commands, /exit to quit

You: What is 15 * 23 + 100?
Agent:
  [→ calling tool: calculator] input: {"expression":"15*23+100"}
  [← calculator result] 445
445
Tokens: in=128 out=24 total=152 | Est. cost: $0.000

You: What time is it?
Agent:
  [→ calling tool: get_current_time] input: {}
  [← get_current_time result] 2026-07-29T08:00:00Z
The current time is 2026-07-29 08:00:00 UTC.
Tokens: in=230 out=45 total=275 | Est. cost: $0.000
```

### 3. REPL Commands

| Command | Action |
|---|---|
| `/exit`, `/quit` | Exit |
| `/help` | Show commands |
| `/tools` | List built-in tools |
| `/clear` | Clear conversation memory |
| `/usage` | Show token usage & cost |

---

## As a Library

### Installation

```bash
moon add mihujiang/agent@0.10.0
```

### Minimal LLMChain

```moonbit
fn main {
  let config = match @config.load_config() {
    Some(c) => c
    None => { println("Configure API first."); return }
  }

  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_system("You are a helpful assistant.")
    |> @prompts.ChatPromptTemplate::with_user("What is {topic}?")

  let provider = @openai.OpenAIProvider::new_compat(
    config.base_url, config.model,
    api_key=config.api_key,
  )

  let chain = @chains.LLMChain::new(@llm.BoxedProvider::new(provider), prompt)

  let vars : Map[String, String] = Map([])
  vars["topic"] = "MoonBit"
  println(chain.invoke(vars))
}
```

### Multi-turn with memory

```moonbit
let chain = @chains.LLMChain::new(provider, prompt)
  |> @chains.LLMChain::with_memory(@memory.BufferMemory::new())

chain.invoke({ "input": "My name is Alice" })
let answer = chain.invoke({ "input": "What's my name?" })
// → "Your name is Alice"
```

### ReAct Agent with tools

```moonbit
let registry = @llm_tools.ToolRegistry::new()
@tools.register_into(registry, @tools.CalculatorTool::new())
@tools.register_into(registry, @tools.DateTimeTool::new())

let executor = @agents.AgentExecutor::new(provider, registry)
  |> @agents.AgentExecutor::with_max_steps(5)

let result = executor.invoke("What is 15 * 23 + 100?")
println(result)
```

### Streaming output

```moonbit
chain.invoke_stream(vars, fn(delta) { print(delta) })
```

### Token usage tracking

```moonbit
let usage = @observability.UsageTracker::new()
@llm.run_agent(provider, registry, messages, stop, fn(event) {
  usage.record(event)  // accumulates tokens from API responses
  // ... your event handling
})
println(usage.format())
// → "Tokens: in=128 out=24 total=152 | Est. cost: $0.000"
```

### RAG: Load and split documents

```moonbit
let loader = @rag.SimpleTextLoader::new("long document text...", "doc.txt")
let docs = loader.load()

let splitter = @rag.RecursiveCharacterTextSplitter::new(500, 100)
let chunks = @rag.split_documents(splitter, docs)
for chunk in chunks {
  println("Chunk: " + chunk.content[0:80] + "...")
}
```

---

## Package Reference

| Package | What it does |
|---|---|
| `prompts` | `PromptTemplate` / `ChatPromptTemplate` — template variables + multi-role messages |
| `chains` | `LLMChain` — prompt + provider + memory + parser in one call |
| `agents` | `AgentExecutor` — ReAct loop with tool calling |
| `memory` | `BufferMemory` / `BufferWindowMemory` / `SummaryMemory` |
| `tools` | `Tool` trait + 6 built-in tools (calculator, datetime, http, file r/w, shell) |
| `parsers` | `JsonOutputParser` — parse structured LLM output |
| `core` | `RunnableWrapper[I,O]` — LCEL-style composable pipelines |
| `config` | `ChatConfig` — unified config from `.env` / `config.json` / env vars |
| `observability` | `UsageTracker` (tokens) + `CallTrace` (decisions) + `TimingTracker` (latency) |
| `rag` | `Document` + `TextLoader` + `RecursiveCharacterTextSplitter` |
| `mcp` | `MCPClient` / `MCPServer` — bidirectional MCP protocol bridge |

---

## Built-in Tools

| Tool | Description |
|---|---|
| `CalculatorTool` | Integer arithmetic (+, -, *, /) |
| `DateTimeTool` | Current ISO-8601 timestamp |
| `HttpTool` | HTTP GET/POST (injectable fetch callback) |
| `FileReadTool` | Read local files (injectable read callback) |
| `FileWriteTool` | Write files (injectable write callback) |
| `ShellTool` | Execute commands (injectable exec callback, sandboxed) |
| `ToolGuard` | Allowlist/denylist filter |
| `ToolMiddleware` | Retry/timeout wrappers |

---

## Configuration Reference

`@config.load_config()` lookup order:

| Priority | Source | Format |
|---|---|---|
| 1 | `./.env` | `KEY=VALUE` |
| 2 | `./config.json` | JSON |
| 3 | `../.env` | parent dir |
| 4 | `../config.json` | parent dir |
| 5 | environment variables | `OPENAI_API_KEY` etc. |

All executables (`cmd/chat`, `examples/quickstart`, `examples/react_agent`, `local-test`) share the same config — configure once, run anywhere.

---

## CI / Testing

```bash
moon fmt --check          # format check
moon build --target js    # build
moon test --target js     # 65 unit tests
```

Three-target CI matrix: native / wasm-gc / js.

---

## Links

- Repository: <https://github.com/mihujiang/MoonBit>
- mooncakes: <https://mooncakes.io/docs/mihujiang/agent>
- Full Manual (Chinese): [../文件/使用手册.md](../文件/使用手册.md)
