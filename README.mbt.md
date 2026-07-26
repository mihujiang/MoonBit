# moon-agent

> MoonBit 版 LangChain 核心库 —— 类型安全、可组合、可嵌入的 AI Agent 框架

[![CI](https://github.com/weopqrst/MoonBit/actions/workflows/ci.yml/badge.svg)](https://github.com/weopqrst/MoonBit/actions)
[![mooncakes](https://img.shields.io/badge/mooncakes-weopqrst%2Fagent-blue)](https://mooncakes.io/docs/weopqrst/agent)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-blue)](https://github.com/weopqrst/MoonBit/releases/tag/v0.1.0)

---

## 中文说明

### 简介

**moon-agent** 是 MoonBit 生态下的 AI Agent 工程化核心库，定位为 LangChain 核心抽象的 MoonBit 移植版本。在已有底层库（`mizchi/llm` 提供 LLM 客户端）之上，构建可组合的高层抽象。

### 特性

- **Prompt 模板**：`PromptTemplate`（`{variable}` 插值）+ `ChatPromptTemplate`（多角色有序消息）
- **输出解析**：`OutputParser` trait + `JsonOutputParser`（容忍 markdown 代码块，兼容 CRLF）
- **对话记忆**：`BufferMemory`（全量历史）+ `BufferWindowMemory`（滑动窗口）+ `BoxedMemory`（trait 对象装箱）
- **工具抽象**：`Tool` trait + 到 `mizchi/llm` 的 `ToolRegistry` 桥接
- **链式编排**：`LLMChain` —— prompt + provider + memory
- **ReAct Agent**：`AgentExecutor` —— 封装 `run_agent`，集成 memory 与 max_steps

### 安装

```bash
moon add weopqrst/agent@0.1.0
```

### 快速开始

```moonbit nocheck
let prompt = ChatPromptTemplate::new()
  |> ChatPromptTemplate::with_system("You are a helpful assistant.")
  |> ChatPromptTemplate::with_user("What is {topic}?")

let provider = BoxedProvider::new(OpenAIProvider::new(api_key))
let chain = LLMChain::new(provider, prompt)

let vars : Map[String, String] = Map([])
vars["topic"] = "MoonBit"
let answer = chain.invoke(vars)
```

### 示例

- `examples/quickstart`：最小 LLMChain 调用
- `examples/react_agent`：自定义 Tool + ReAct Agent 循环

### 子包

| 包 | 说明 |
|---|---|
| `core` | `RunnableWrapper[I,O]` 可组合单元抽象 |
| `prompts` | Prompt 模板（字符串插值 + 多角色消息） |
| `parsers` | 输出解析器（Json） |
| `memory` | 对话记忆（全量 / 滑动窗口 / 装箱） |
| `tools` | 工具 trait 与注册桥接 |
| `chains` | 链式编排（LLMChain） |
| `agents` | ReAct Agent 执行器 |

### 工具链

```bash
moon update          # 更新 registry 索引
moon fmt --check     # 格式检查
moon build --target js
moon test --target js
```

### 相关链接

- 仓库：<https://github.com/weopqrst/MoonBit>
- mooncakes：<https://mooncakes.io/docs/weopqrst/agent>
- LLM 依赖：<https://mooncakes.io/docs/mizchi/llm>

---

## English Guide

### Overview

**moon-agent** is an AI Agent engineering core library for the MoonBit ecosystem, positioned as a MoonBit port of LangChain's core abstractions. It builds composable high-level abstractions on top of existing low-level libraries (`mizchi/llm` provides LLM clients).

### Features

- **Prompt Templates**: `PromptTemplate` (`{variable}` interpolation) + `ChatPromptTemplate` (multi-role ordered messages)
- **Output Parsing**: `OutputParser` trait + `JsonOutputParser` (tolerates markdown code fences, CRLF-compatible)
- **Memory**: `BufferMemory` (full history) + `BufferWindowMemory` (sliding window) + `BoxedMemory` (trait object boxing)
- **Tool Abstraction**: `Tool` trait + bridge to `mizchi/llm`'s `ToolRegistry`
- **Chain Orchestration**: `LLMChain` — prompt + provider + memory
- **ReAct Agent**: `AgentExecutor` — wraps `run_agent`, integrates memory and max_steps

### Installation

```bash
moon add weopqrst/agent@0.1.0
```

### Quickstart

```moonbit nocheck
let prompt = ChatPromptTemplate::new()
  |> ChatPromptTemplate::with_system("You are a helpful assistant.")
  |> ChatPromptTemplate::with_user("What is {topic}?")

let provider = BoxedProvider::new(OpenAIProvider::new(api_key))
let chain = LLMChain::new(provider, prompt)

let vars : Map[String, String] = Map([])
vars["topic"] = "MoonBit"
let answer = chain.invoke(vars)
```

### Examples

- `examples/quickstart`: minimal LLMChain invocation
- `examples/react_agent`: custom Tool + ReAct Agent loop

### Sub-packages

| Package | Description |
|---|---|
| `core` | `RunnableWrapper[I,O]` composable unit abstraction |
| `prompts` | Prompt templates (string interpolation + multi-role messages) |
| `parsers` | Output parsers (Json) |
| `memory` | Conversation memory (full / sliding window / boxed) |
| `tools` | Tool trait and registry bridge |
| `chains` | Chain orchestration (LLMChain) |
| `agents` | ReAct Agent executor |

### Tooling

```bash
moon update          # update registry index
moon fmt --check     # format check
moon build --target js
moon test --target js
```

### Links

- Repository: <https://github.com/weopqrst/MoonBit>
- mooncakes: <https://mooncakes.io/docs/weopqrst/agent>
- LLM dependency: <https://mooncakes.io/docs/mizchi/llm>
