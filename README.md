# moon-agent

> MoonBit 版 LangChain 核心库 —— 类型安全、可组合、可嵌入的 AI Agent 框架

[![CI](https://github.com/mihujiang/MoonBit/actions/workflows/ci.yml/badge.svg)](https://github.com/mihujiang/MoonBit/actions)
[![mooncakes](https://img.shields.io/badge/mooncakes-weopqrst%2Fagent-blue)](https://mooncakes.io/docs/weopqrst/agent)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.1-blue)](https://github.com/mihujiang/MoonBit/releases/tag/v0.3.1)

---

## 中文说明

### 简介

**moon-agent** 是 MoonBit 生态下的 AI Agent 工程化核心库，定位为 LangChain 核心抽象的 MoonBit 移植版本。在已有底层库（`mizchi/llm` 提供 LLM 客户端）之上，构建可组合的高层抽象，让 MoonBit 开发者用极少的代码实现 LLM 调用、工具编排、多轮对话、结构化输出解析等 AI Agent 能力。

### 特性

#### 核心抽象

- **Prompt 模板**：`PromptTemplate`（`{variable}` 字符串插值）+ `ChatPromptTemplate`（多角色有序消息，保留插入顺序，支持 few-shot）
- **输出解析**：`OutputParser` trait + `JsonOutputParser`（容忍 markdown 代码围栏，兼容 CRLF 换行）
- **对话记忆**：`BufferMemory`（全量历史）、`BufferWindowMemory`（滑动窗口）、`SummaryMemory`（周期性 LLM 摘要长对话）、`BoxedMemory`（trait 对象装箱，支持任意 Memory 实现）
- **工具抽象**：`Tool` trait（声明式 name/description/args_schema/run）+ `register_into` 桥接到 `mizchi/llm` 的 `ToolRegistry`
- **链式编排**：`LLMChain` —— prompt + provider + memory + output_parser，支持流式输出
- **ReAct Agent**：`AgentExecutor` —— 封装 `run_agent`，集成 memory、output_parser、max_steps、流式输出
- **可组合单元**：`RunnableWrapper[I,O]` —— LCEL 式管道组合（`pipe`）/ 输出变换（`map`）
- **多链编排**：`SequentialChain[T]` —— 同质多步骤链，顺序执行并传递输出
- **可观测性**：`UsageTracker`（Token 统计 + 成本估算）、`CallTrace`（Agent 决策链路追踪）、`TimingTracker`（工具耗时统计）
- **RAG 检索**：`Document` + `MarkdownLoader` + `RecursiveCharacterTextSplitter` + `VectorStore` + `Embedder` + `Retriever` + MMR 多样性检索 + `RetrievalTool`（Agent 工具版 RAG）
- **交互式 CLI**：`cmd/chat` REPL —— 多轮对话、工具调用可视化、斜杠命令（`/help` `/usage` `/clear`）
- **统一配置**：`.env` / `config.json` / 环境变量，一处配置全局生效
- **MCP 协议**：`MCPClient` / `MCPServer` 双向桥接

#### V0.2 / V0.3 新增

| 版本 | 功能 |
|---|---|
| V0.2-1 | `LLMChain::with_output_parser` + `invoke_and_parse` —— 输出解析接入 |
| V0.2-2 | `LLMChain::invoke_stream` —— 流式输出回调 |
| V0.2-3 | `RunnableWrapper::pipe` / `map` + `LLMChain::as_runnable` —— LCEL 式组合 |
| V0.2-4 | `SummaryMemory` —— 周期性 LLM 摘要长对话 |
| V0.2-5 | `AgentExecutor::invoke_stream` —— Agent 流式输出 |
| V0.3-1 | `AgentExecutor::with_output_parser` + `invoke_and_parse` —— Agent 输出解析 |
| V0.3-2 | `SequentialChain[T]` —— 多链编排 |

### 架构

```
                    你的 MoonBit 应用
                          │
                    ┌─────┴─────┐
                    │  moon-agent │  ← 本库（11 个子包，99 个测试）
                    └─────┬─────┘
                          │
        ┌─────┬─────┬─────┼─────┬─────┬─────┬─────┐
        │     │     │     │     │     │     │     │
      core  prompts parsers memory tools chains agents
        │     │     │     │     │     │     │
        └─────┴─────┴─────┴──┬──┴─────┴─────┘
                             │
                    config / observability / mcp / rag
                          │
                    mizchi/llm  ← LLM 客户端底层（Provider、流式、tool_call）
                          │
              OpenAI / Anthropic / ...
```

### 安装

```bash
moon add weopqrst/agent@0.3.1
```

这会在 `moon.mod` 中添加：
```toml
import {
  "mizchi/llm@0.3.1",
  "weopqrst/agent@0.3.1",
}
```

### 配置（v0.9 新增，v0.10 扩展）

推荐使用 `.env` 文件（参考 `.env.example`）：

```bash
OPENAI_API_KEY=sk-...
OPENAI_BASE_URL=https://api.deepseek.com
OPENAI_MODEL=deepseek-chat
```

或使用 `config.json`：

```json
{
  "api_key": "sk-...",
  "base_url": "https://api.deepseek.com",
  "model": "deepseek-chat",
  "max_tokens": 4096,
  "system_prompt": ""
}
```

或设置环境变量：`OPENAI_API_KEY`、`OPENAI_BASE_URL`（可选）、`OPENAI_MODEL`（可选）。

`@config.load_config()` 按以下顺序查找：
1. `./.env`（推荐）
2. `./config.json`
3. `../.env`（子目录如 `cmd/chat` 运行时）
4. `../config.json`
5. 环境变量回退

### 交互式 REPL（cmd/chat）

配置好 API 后，直接启动多轮对话 REPL：

```bash
moon run cmd/chat --target js
```

```
=== moon-agent chat v0.3.1 ===
Endpoint: https://api.deepseek.com | Model: deepseek-chat
Type /help for commands, /exit to quit

You: 15 * 23 + 100 等于多少？
Agent:
  [→ calling tool: calculator] input: {"expression":"15*23+100"}
  [← calculator result] 445
445
Tokens: in=128 out=24 total=152 | Est. cost: $0.000
```

REPL 斜杠命令：

| 命令 | 功能 |
|---|---|
| `/exit`, `/quit` | 退出 |
| `/help` | 查看命令 |
| `/tools` | 列出内置工具 |
| `/clear` | 清除对话记忆 |
| `/usage` | 查看 Token 用量和费用 |
| `/errors` | 查看错误日志 |

### 快速开始（5 分钟）

**最简 LLMChain**：

```moonbit nocheck
///|
fn main {
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  match api_key {
    Some(key) => {
      let prompt = @prompts.ChatPromptTemplate::new()
        |> @prompts.ChatPromptTemplate::with_system(
          "You are a helpful assistant.",
        )
        |> @prompts.ChatPromptTemplate::with_user(
          "What is {topic}? Answer in one sentence.",
        )

      let model = @openai.OpenAIProvider::new(key)
      let provider = @llm.BoxedProvider::new(model)
      let chain = @chains.LLMChain::new(provider, prompt)

      let vars : Map[String, String] = Map([])
      vars["topic"] = "MoonBit"
      let answer = chain.invoke(vars)
      println(answer)
    }
    None => println("Please set OPENAI_API_KEY environment variable.")
  }
}
```

**带记忆的多轮对话**：

```moonbit nocheck
let chain = @chains.LLMChain::new(provider, prompt)
  |> @chains.LLMChain::with_memory(@memory.BufferMemory::new())

chain.invoke({ "input": "我叫张三" })
let answer = chain.invoke({ "input": "我叫什么名字？" })  // → "你叫张三"
```

**LCEL 式组合**：

```moonbit nocheck
///|
let chain = @chains.LLMChain::new(provider, prompt).as_runnable()

///|
let post = @core.RunnableWrapper::new(fn(s : String) -> String {
  "Answer length: " + s.length().to_string()
})

///|
let composed = chain.pipe(post)
// 调用 LLM → 取结果长度，一步完成
```

**ReAct Agent + 工具**：

```moonbit nocheck
let registry = @llm_tools.ToolRegistry::new()
@tools.register_into(registry, MyWeatherTool::new(api_key))

let executor = @agents.AgentExecutor::new(provider, registry)
  |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
  |> @agents.AgentExecutor::with_max_steps(5)

let result = executor.invoke("帮我查一下北京的天气")
```

**流式输出**：

```moonbit nocheck
let chain = @chains.LLMChain::new(provider, prompt)
chain.invoke_stream(vars, fn(delta) {
  print(delta)  // 实时逐字输出
})
```

### 子包

| 包 | 文件 | 说明 |
|---|---|---|
| `core` | `core.mbt` | `RunnableWrapper[I,O]` 可组合单元 + `pipe`/`map` + `SequentialChain[T]` + `RouterChain` |
| `prompts` | `template.mbt`, `chat_prompt.mbt` | `PromptTemplate`（`{var}` 插值）+ `ChatPromptTemplate`（多角色有序消息） |
| `parsers` | `parser.mbt`, `boxed_parser.mbt` | `OutputParser` trait + `JsonOutputParser` + `BoxedOutputParser` |
| `memory` | `memory.mbt`, `buffer_memory.mbt`, `summary_memory.mbt`, `boxed_memory.mbt` | `Memory` trait + `BufferMemory` + `BufferWindowMemory` + `SummaryMemory` + `BoxedMemory` |
| `tools` | `tool.mbt`, `calculator.mbt`, `datetime.mbt`, `http.mbt`, `file_read.mbt`, `file_write.mbt`, `shell.mbt`, `schema.mbt`, `tool_guard.mbt`, `tool_middleware.mbt`, `retrieval_tool.mbt` | `Tool` trait + 6 个内置工具 + 中间件 + RetrievalTool |
| `chains` | `llm_chain.mbt` | `LLMChain` —— prompt + provider + memory + output_parser + 流式 |
| `agents` | `agent_executor.mbt` | `AgentExecutor` —— ReAct Agent 循环 + memory + output_parser + 流式 |
| `config` | `config.mbt` | `ChatConfig` —— `.env` / `config.json` / env vars 统一加载 |
| `observability` | `observability.mbt` | `UsageTracker` + `CallTrace` + `TimingTracker` + `ErrorLogger` |
| `mcp` | `mcp_types.mbt`, `mcp_client.mbt`, `mcp_server.mbt`, `mcp_bridge.mbt` | MCP 协议双向桥接 |
| `rag` | `loader.mbt`, `splitter.mbt`, `store.mbt`, `embedder.mbt`, `retriever.mbt`, `boxed.mbt` | `Document` + `MarkdownLoader` + `RecursiveCharacterTextSplitter` + `VectorStore` + `Embedder` + `Retriever` |
| `cmd/chat` | `main.mbt` | 交互式 REPL（多轮对话、工具调用可视化） |
| `examples/quickstart` | `main.mbt` | 最小 LLMChain 示例 |
| `examples/react_agent` | `main.mbt` | 自定义 Tool + ReAct Agent 示例 |

### 测试覆盖

99 个单元测试，三目标（native / wasm-gc / js）全绿：

| 测试文件 | 测试数 | 覆盖内容 |
|---|---|---|
| `prompts/template_wbtest.mbt` | 6 | render / render_one / variables / ChatPromptTemplate 顺序 |
| `memory/buffer_memory_wbtest.mbt` | 5 | BufferMemory 存取/clear / BufferWindowMemory 窗口/副本 |
| `memory/summary_memory_wbtest.mbt` | 5 | 摘要触发条件/load_messages/clear/保留最近消息 |
| `parsers/parser_wbtest.mbt` | 7 | strip_code_fence / JsonOutputParser 含/不含围栏 / CRLF |
| `tools/tool_wbtest.mbt` | 19 | CalculatorTool/DateTimeTool/ToolGuard/ToolMiddleware |
| `chains/llm_chain_wbtest.mbt` | 7 | invoke/parse/stream/无parser/无效JSON/向后兼容 |
| `agents/agent_executor_wbtest.mbt` | 7 | invoke/stream/parse/无parser/invoke_tracked（3个） |
| `core/core_wbtest.mbt` | 11 | pipe/map/SequentialChain/与wrapper组合 |
| `observability/observability_wbtest.mbt` | 16 | UsageTracker/CallTrace/TimingTracker/ErrorLogger |
| `rag/splitter_wbtest.mbt` | 10 | RecursiveCharacterTextSplitter/MarkdownLoader/VectorStore/MMR |

### 工具链

```bash
moon update               # 更新 registry 索引
moon fmt --check          # 格式检查
moon build --target js    # 构建 JS 目标
moon build --target wasm-gc  # 构建 wasm-gc 目标
moon test --target js     # 运行测试
moon info                 # 更新生成接口文件
```

### 相关链接

- 仓库：<https://github.com/mihujiang/MoonBit>
- mooncakes：<https://mooncakes.io/docs/weopqrst/agent>
- LLM 依赖：<https://mooncakes.io/docs/mizchi/llm>
- 使用指南：[USAGE.md](USAGE.md)（GitHub 友好版本）
- 项目进度：参见仓库 `MoonBit/` 目录下的 commit 历史

---

## English Guide

### Overview

**moon-agent** is an AI Agent engineering core library for the MoonBit ecosystem, positioned as a MoonBit port of LangChain's core abstractions. It builds composable high-level abstractions on top of the `mizchi/llm` LLM client library, enabling MoonBit developers to implement LLM calls, tool orchestration, multi-turn conversations, and structured output parsing with minimal code.

### Features

#### Core Abstractions

- **Prompt Templates**: `PromptTemplate` (`{variable}` string interpolation) + `ChatPromptTemplate` (multi-role ordered messages with insertion-order preservation, supports few-shot)
- **Output Parsing**: `OutputParser` trait + `JsonOutputParser` (tolerates markdown code fences, CRLF-compatible)
- **Conversation Memory**: `BufferMemory` (full history), `BufferWindowMemory` (sliding window), `SummaryMemory` (periodic LLM summarization for long conversations), `BoxedMemory` (trait object boxing for any Memory implementation)
- **Tool Abstraction**: `Tool` trait (declarative name/description/args_schema/run) + `register_into` bridge to `mizchi/llm`'s `ToolRegistry`
- **Chain Orchestration**: `LLMChain` — prompt + provider + memory + output_parser, supports streaming
- **ReAct Agent**: `AgentExecutor` — wraps `run_agent`, integrates memory, output_parser, max_steps, streaming
- **Composable Units**: `RunnableWrapper[I,O]` — LCEL-style pipeline composition (`pipe`) / output transformation (`map`)
- **Multi-chain Orchestration**: `SequentialChain[T]` — homogeneous multi-step chains, sequential execution with output passing
- **Observability**: `UsageTracker` (token stats + cost), `CallTrace` (agent decision trail), `TimingTracker` (tool latency), `ErrorLogger` (structured error logging)
- **RAG Retrieval**: `Document` + `MarkdownLoader` + `RecursiveCharacterTextSplitter` + `VectorStore` + `Embedder` + `Retriever` + MMR diversity search
- **Interactive CLI**: `cmd/chat` REPL — multi-turn conversations, tool call visualization, slash commands
- **Unified Config**: `.env` / `config.json` / env vars — configure once, run anywhere
- **MCP Protocol**: `MCPClient` / `MCPServer` bidirectional bridge

#### V0.2 / V0.3 Additions

| Version | Feature |
|---|---|
| V0.2-1 | `LLMChain::with_output_parser` + `invoke_and_parse` — output parsing integration |
| V0.2-2 | `LLMChain::invoke_stream` — streaming output callback |
| V0.2-3 | `RunnableWrapper::pipe` / `map` + `LLMChain::as_runnable` — LCEL composition |
| V0.2-4 | `SummaryMemory` — periodic LLM summarization |
| V0.2-5 | `AgentExecutor::invoke_stream` — Agent streaming output |
| V0.3-1 | `AgentExecutor::with_output_parser` + `invoke_and_parse` — Agent output parsing |
| V0.3-2 | `SequentialChain[T]` — multi-chain orchestration |

### Architecture

```
                   Your MoonBit Application
                          │
                    ┌─────┴─────┐
                    │  moon-agent │  ← This library (11 sub-packages, 99 tests)
                    └─────┬─────┘
                          │
        ┌─────┬─────┬─────┼─────┬─────┬─────┬─────┐
        │     │     │     │     │     │     │     │
      core  prompts parsers memory tools chains agents
        │     │     │     │     │     │     │
        └─────┴─────┴─────┴──┬──┴─────┴─────┘
                             │
                    config / observability / mcp / rag
                          │
                    mizchi/llm  ← LLM client (Provider, streaming, tool_call)
                          │
              OpenAI / Anthropic / ...
```

### Installation

```bash
moon add weopqrst/agent@0.3.1
```

This adds to your `moon.mod`:
```toml
import {
  "mizchi/llm@0.3.1",
  "weopqrst/agent@0.3.1",
}
```

### Interactive REPL (cmd/chat)

After configuring the API, start the multi-turn chat REPL directly:

```bash
moon run cmd/chat --target js
```

```
=== moon-agent chat v0.3.1 ===
Endpoint: https://api.deepseek.com | Model: deepseek-chat
Type /help for commands, /exit to quit

You: What is 15 * 23 + 100?
Agent:
  [→ calling tool: calculator] input: {"expression":"15*23+100"}
  [← calculator result] 445
445
Tokens: in=128 out=24 total=152 | Est. cost: $0.000
```

REPL slash commands:

| Command | Action |
|---|---|
| `/exit`, `/quit` | Exit |
| `/help` | Show commands |
| `/tools` | List built-in tools |
| `/clear` | Clear conversation memory |
| `/usage` | Show token usage & cost |
| `/errors` | Show error log |

### Quickstart (5 minutes)

**Minimal LLMChain**:

```moonbit nocheck
///|
fn main {
  let api_key = @env.get_env_var("OPENAI_API_KEY")
  match api_key {
    Some(key) => {
      let prompt = @prompts.ChatPromptTemplate::new()
        |> @prompts.ChatPromptTemplate::with_system(
          "You are a helpful assistant.",
        )
        |> @prompts.ChatPromptTemplate::with_user(
          "What is {topic}? Answer in one sentence.",
        )

      let model = @openai.OpenAIProvider::new(key)
      let provider = @llm.BoxedProvider::new(model)
      let chain = @chains.LLMChain::new(provider, prompt)

      let vars : Map[String, String] = Map([])
      vars["topic"] = "MoonBit"
      let answer = chain.invoke(vars)
      println(answer)
    }
    None => println("Please set OPENAI_API_KEY environment variable.")
  }
}
```

**Multi-turn with memory**:

```moonbit nocheck
let chain = @chains.LLMChain::new(provider, prompt)
  |> @chains.LLMChain::with_memory(@memory.BufferMemory::new())

chain.invoke({ "input": "My name is John" })
let answer = chain.invoke({ "input": "What's my name?" })  // → "Your name is John"
```

**LCEL Composition**:

```moonbit nocheck
///|
let chain = @chains.LLMChain::new(provider, prompt).as_runnable()

///|
let post = @core.RunnableWrapper::new(fn(s : String) -> String {
  "Answer length: " + s.length().to_string()
})

///|
let composed = chain.pipe(post)
// Calls LLM → gets result length, in one step
```

**ReAct Agent + Tool**:

```moonbit nocheck
let registry = @llm_tools.ToolRegistry::new()
@tools.register_into(registry, MyWeatherTool::new(api_key))

let executor = @agents.AgentExecutor::new(provider, registry)
  |> @agents.AgentExecutor::with_memory(@memory.BufferMemory::new())
  |> @agents.AgentExecutor::with_max_steps(5)

let result = executor.invoke("What's the weather in Beijing?")
```

**Streaming output**:

```moonbit nocheck
let chain = @chains.LLMChain::new(provider, prompt)
chain.invoke_stream(vars, fn(delta) {
  print(delta)  // real-time character-by-character output
})
```

### Sub-packages

| Package | Files | Description |
|---|---|---|
| `core` | `core.mbt` | `RunnableWrapper[I,O]` composable unit + `pipe`/`map` + `SequentialChain[T]` |
| `prompts` | `template.mbt`, `chat_prompt.mbt` | `PromptTemplate` (`{var}` interpolation) + `ChatPromptTemplate` (multi-role ordered messages) |
| `parsers` | `parser.mbt`, `boxed_parser.mbt` | `OutputParser` trait + `JsonOutputParser` + `BoxedOutputParser` |
| `memory` | `memory.mbt`, `buffer_memory.mbt`, `summary_memory.mbt`, `boxed_memory.mbt` | `Memory` trait + `BufferMemory` + `BufferWindowMemory` + `SummaryMemory` + `BoxedMemory` |
| `tools` | `tool.mbt` + 10 built-in tool files | `Tool` trait + 6 built-in tools + middleware + RetrievalTool |
| `chains` | `llm_chain.mbt` | `LLMChain` — prompt + provider + memory + output_parser + streaming |
| `agents` | `agent_executor.mbt` | `AgentExecutor` — ReAct Agent loop + memory + output_parser + streaming |
| `config` | `config.mbt` | `ChatConfig` — `.env` / `config.json` / env vars unified loading |
| `observability` | `observability.mbt` | `UsageTracker` + `CallTrace` + `TimingTracker` + `ErrorLogger` |
| `mcp` | 4 files | MCP protocol bidirectional bridge |
| `rag` | `loader.mbt`, `splitter.mbt`, `store.mbt`, `embedder.mbt`, `retriever.mbt`, `boxed.mbt` | `Document` + `MarkdownLoader` + `RecursiveCharacterTextSplitter` + `VectorStore` + `Embedder` + `Retriever` |
| `cmd/chat` | `main.mbt` | Interactive REPL (multi-turn, tool visualization) |
| `examples/quickstart` | `main.mbt` | Minimal LLMChain example |
| `examples/react_agent` | `main.mbt` | Custom Tool + ReAct Agent example |

### Test Coverage

99 unit tests, all green across three targets (native / wasm-gc / js):

| Test File | Tests | Coverage |
|---|---|---|
| `prompts/template_wbtest.mbt` | 6 | render / render_one / variables / ChatPromptTemplate ordering |
| `memory/buffer_memory_wbtest.mbt` | 5 | BufferMemory save/load/clear / BufferWindowMemory window/copy |
| `memory/summary_memory_wbtest.mbt` | 5 | Summary trigger conditions / load_messages / clear / recent message preservation |
| `parsers/parser_wbtest.mbt` | 7 | strip_code_fence / JsonOutputParser with/without fence / CRLF |
| `tools/tool_wbtest.mbt` | 19 | CalculatorTool / DateTimeTool / ToolGuard / ToolMiddleware |
| `chains/llm_chain_wbtest.mbt` | 7 | invoke / parse / stream / no parser / invalid JSON / backward compat |
| `agents/agent_executor_wbtest.mbt` | 7 | invoke / stream / parse / no parser / invoke_tracked (3) |
| `core/core_wbtest.mbt` | 11 | pipe / map / SequentialChain / wrapper composition |
| `observability/observability_wbtest.mbt` | 16 | UsageTracker / CallTrace / TimingTracker / ErrorLogger |
| `rag/splitter_wbtest.mbt` | 10 | RecursiveCharacterTextSplitter / MarkdownLoader / VectorStore / MMR |

### Links

- Repository: <https://github.com/mihujiang/MoonBit>
- mooncakes: <https://mooncakes.io/docs/weopqrst/agent>
- LLM dependency: <https://mooncakes.io/docs/mizchi/llm>
- Usage Guide: [USAGE.md](USAGE.md)
- Project Progress: See commit history under `MoonBit/`

---

## 致谢与许可证兼容性

本项目（moon-agent）在架构设计上参考了 [LangChain](https://github.com/langchain-ai/langchain) 的核心抽象理念。
LangChain 采用 MIT 许可证，版权归 LangChain AI, Inc. 所有。
本项目的实现代码采用 Apache-2.0 许可证。
