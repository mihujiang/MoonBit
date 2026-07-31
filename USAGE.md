# moon-agent Usage Guide / 使用指南

> GitHub-friendly quick guide. For the complete project documentation, see the `/文件` directory in the repository.

---

## 中文说明

### 快速开始（2 分钟）

#### 1. 配置 API

复制模板并填入 API key：

```bash
cp .env.example .env
```

编辑 `.env`：

```bash
OPENAI_API_KEY=sk-你的密钥
OPENAI_BASE_URL=https://api.deepseek.com   # 或 https://api.openai.com
OPENAI_MODEL=deepseek-chat                  # 或 gpt-4o
```

支持任意 OpenAI 兼容端点（DeepSeek / OpenAI / OpenRouter / Ollama / vLLM）。

#### 2. 启动聊天（REPL）

```bash
moon run cmd/chat --target js
```

```
=== moon-agent chat v0.3.0 ===
Endpoint: https://api.deepseek.com | Model: deepseek-chat
Type /help for commands, /exit to quit

You: 15 * 23 + 100 等于多少？
Agent:
  [→ calling tool: calculator] input: {"expression":"15*23+100"}
  [← calculator result] 445
445
Tokens: in=128 out=24 total=152 | Est. cost: $0.000
```

#### 3. REPL 命令

| 命令 | 功能 |
|---|---|
| `/exit`, `/quit` | 退出 |
| `/help` | 查看命令 |
| `/tools` | 列出内置工具 |
| `/clear` | 清除对话记忆 |
| `/usage` | 查看 Token 用量和费用 |

---

### 作为库使用

#### 安装

```bash
moon add weopqrst/agent@0.3.0
```

#### 最简 LLMChain

```moonbit
fn main {
  let config = match @config.load_config() {
    Some(c) => c
    None => { println("请先配置 API。"); return }
  }

  let prompt = @prompts.ChatPromptTemplate::new()
    |> @prompts.ChatPromptTemplate::with_system("你是一个乐于助人的助手。")
    |> @prompts.ChatPromptTemplate::with_user("{topic} 是什么？")

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

#### 带记忆的多轮对话

```moonbit
let chain = @chains.LLMChain::new(provider, prompt)
  |> @chains.LLMChain::with_memory(@memory.BufferMemory::new())

chain.invoke({ "input": "我叫张三" })
let answer = chain.invoke({ "input": "我叫什么名字？" })
// → "你叫张三"
```

#### ReAct Agent + 工具

```moonbit
let registry = @llm_tools.ToolRegistry::new()
@tools.register_into(registry, @tools.CalculatorTool::new())
@tools.register_into(registry, @tools.DateTimeTool::new())

let executor = @agents.AgentExecutor::new(provider, registry)
  |> @agents.AgentExecutor::with_max_steps(5)

let result = executor.invoke("15 * 23 + 100 等于多少？")
println(result)
```

#### 流式输出

```moonbit
chain.invoke_stream(vars, fn(delta) { print(delta) })
```

#### Token 用量追踪

```moonbit
let usage = @observability.UsageTracker::new()
@llm.run_agent(provider, registry, messages, stop, fn(event) {
  usage.record(event)  // 自动累积 token
  // ... 你的事件处理
})
println(usage.format())
// → "Tokens: in=128 out=24 total=152 | Est. cost: $0.000"
```

#### RAG：加载和分割文档

```moonbit
let loader = @rag.SimpleTextLoader::new("很长的文档内容...", "doc.txt")
let docs = loader.load()

let splitter = @rag.RecursiveCharacterTextSplitter::new(500, 100)
let chunks = @rag.split_documents(splitter, docs)
for chunk in chunks {
  println("片段: " + chunk.content[0:80] + "...")
}
```

---

### 包速查表

| 包 | 功能 |
|---|---|
| `prompts` | `PromptTemplate` / `ChatPromptTemplate` — 模板变量 + 多角色消息 |
| `chains` | `LLMChain` — prompt + provider + memory + parser 一条龙 |
| `agents` | `AgentExecutor` — ReAct 循环 + 工具调用 |
| `memory` | `BufferMemory` / `BufferWindowMemory` / `SummaryMemory` |
| `tools` | `Tool` trait + 6 个内置工具（计算器、时间、HTTP、文件读写、命令执行） |
| `parsers` | `JsonOutputParser` — 解析结构化 LLM 输出 |
| `core` | `RunnableWrapper[I,O]` — LCEL 式可组合管道 |
| `config` | `ChatConfig` — 统一配置（`.env` / `config.json` / 环境变量） |
| `observability` | `UsageTracker`（Token）+ `CallTrace`（决策）+ `TimingTracker`（耗时） |
| `rag` | `Document` + `TextLoader` + `RecursiveCharacterTextSplitter` |
| `mcp` | `MCPClient` / `MCPServer` — MCP 协议双向桥接 |

### 内置工具

| 工具 | 描述 |
|---|---|
| `CalculatorTool` | 整数四则运算（+ - * /） |
| `DateTimeTool` | 当前 ISO-8601 时间戳 |
| `HttpTool` | HTTP GET/POST（可注入 fetch 回调） |
| `FileReadTool` | 读本地文件（可注入 read 回调） |
| `FileWriteTool` | 写文件（可注入 write 回调） |
| `ShellTool` | 执行命令（可注入 exec 回调，沙箱模式） |
| `ToolGuard` | 白名单/黑名单过滤器 |
| `ToolMiddleware` | 重试/超时包装器 |

### 配置参考

`@config.load_config()` 查找顺序：`.env` → `config.json` → `../.env` → `../config.json` → 环境变量。

所有可执行文件共享配置，一处配置，全局生效。

### CI / 测试

```bash
moon fmt --check          # 格式检查
moon build --target js    # 构建
moon test --target js     # 76 个单元测试
```

三目标 CI：native / wasm-gc / js。

---

## English Guide

### Quickstart (< 2 min)

#### 1. Configure API

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

#### 2. Start chatting (REPL)

```bash
moon run cmd/chat --target js
```

```
=== moon-agent chat v0.3.0 ===
Endpoint: https://api.deepseek.com | Model: deepseek-chat
Type /help for commands, /exit to quit

You: What is 15 * 23 + 100?
Agent:
  [→ calling tool: calculator] input: {"expression":"15*23+100"}
  [← calculator result] 445
445
Tokens: in=128 out=24 total=152 | Est. cost: $0.000
```

#### 3. REPL Commands

| Command | Action |
|---|---|
| `/exit`, `/quit` | Exit |
| `/help` | Show commands |
| `/tools` | List built-in tools |
| `/clear` | Clear conversation memory |
| `/usage` | Show token usage & cost |

---

### As a Library

#### Installation

```bash
moon add weopqrst/agent@0.3.0
```

#### Minimal LLMChain

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

#### Multi-turn with memory

```moonbit
let chain = @chains.LLMChain::new(provider, prompt)
  |> @chains.LLMChain::with_memory(@memory.BufferMemory::new())

chain.invoke({ "input": "My name is Alice" })
let answer = chain.invoke({ "input": "What's my name?" })
// → "Your name is Alice"
```

#### ReAct Agent with tools

```moonbit
let registry = @llm_tools.ToolRegistry::new()
@tools.register_into(registry, @tools.CalculatorTool::new())
@tools.register_into(registry, @tools.DateTimeTool::new())

let executor = @agents.AgentExecutor::new(provider, registry)
  |> @agents.AgentExecutor::with_max_steps(5)

let result = executor.invoke("What is 15 * 23 + 100?")
println(result)
```

#### Streaming output

```moonbit
chain.invoke_stream(vars, fn(delta) { print(delta) })
```

#### Token usage tracking

```moonbit
let usage = @observability.UsageTracker::new()
@llm.run_agent(provider, registry, messages, stop, fn(event) {
  usage.record(event)
  // ... your event handling
})
println(usage.format())
// → "Tokens: in=128 out=24 total=152 | Est. cost: $0.000"
```

#### RAG: Load and split documents

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

### Package Reference

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

### Built-in Tools

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

### Configuration Reference

`@config.load_config()` lookup order: `.env` → `config.json` → `../.env` → `../config.json` → env vars.

All executables share the same config — configure once, run anywhere.

### CI / Testing

```bash
moon fmt --check          # format check
moon build --target js    # build
moon test --target js     # 76 unit tests
```

Three-target CI matrix: native / wasm-gc / js.

---

## Links / 链接

- Repository / 仓库：<https://github.com/mihujiang/MoonBit>
- mooncakes：<https://mooncakes.io/docs/weopqrst/agent>
- LLM dependency / 依赖：<https://mooncakes.io/docs/mizchi/llm>
