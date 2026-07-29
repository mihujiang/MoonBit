# 项目 Agents.md 指南 / Project Agents.md Guide

---

## 中文说明

这是一个 [MoonBit](https://docs.moonbitlang.com) AI Agent 框架项目（moon-agent），定位为 LangChain 核心抽象的 MoonBit 移植版。仓库：<https://github.com/mihujiang/MoonBit>。

你可以在这里浏览并安装额外的 skills：<https://github.com/moonbitlang/skills>

### 项目结构

```
MoonBit/
├── moon.mod                    # 模块元数据（name、version、dependencies）
├── moon.pkg                    # 根包声明
├── agent.mbt                   # 根模块（版本常量 + 文档）
├── README.mbt.md               # 项目 README
├── USAGE.md                    # GitHub 友好使用指南
├── AGENTS.md                   # 本文件
├── .env.example                # 配置模板（committed）
├── config.example.json         # JSON 配置模板（committed）
├── LICENSE                     # Apache-2.0
├── .gitignore
├── .githooks/                  # Git 钩子
│   ├── pre-commit              # 提交前检查（moon check）
│   └── README.md
├── .github/workflows/          # CI 配置
│   ├── ci.yml                  # 主 CI（native/wasm-gc/js 三目标矩阵）
│   └── copilot-setup-steps.yml
│
├── core/                       # 可组合单元（RunnableWrapper + SequentialChain + RouterChain）
│   ├── core.mbt
│   ├── core_wbtest.mbt         # 白盒测试: 11 tests
│   └── moon.pkg
├── prompts/                    # Prompt 模板
│   ├── template.mbt            # PromptTemplate（{var} 插值）
│   ├── chat_prompt.mbt         # ChatPromptTemplate（多角色有序消息）
│   ├── template_wbtest.mbt     # 白盒测试: 6 tests
│   └── moon.pkg
├── parsers/                    # 输出解析器
│   ├── parser.mbt              # OutputParser trait + JsonOutputParser
│   ├── boxed_parser.mbt        # BoxedOutputParser（trait 对象装箱）
│   ├── parser_wbtest.mbt       # 白盒测试: 7 tests
│   └── moon.pkg
├── memory/                     # 对话记忆
│   ├── memory.mbt              # Memory trait
│   ├── buffer_memory.mbt       # BufferMemory + BufferWindowMemory
│   ├── summary_memory.mbt      # SummaryMemory（周期性 LLM 摘要）
│   ├── boxed_memory.mbt        # BoxedMemory（trait 对象装箱）
│   ├── buffer_memory_wbtest.mbt  # 白盒测试: 5 tests
│   ├── summary_memory_wbtest.mbt # 白盒测试: 5 tests
│   └── moon.pkg
├── tools/                      # 工具抽象 + 6 个内置工具
│   ├── tool.mbt                # Tool trait + register_into 桥接
│   ├── calculator.mbt          # CalculatorTool
│   ├── datetime.mbt            # DateTimeTool
│   ├── http.mbt                # HttpTool
│   ├── file_read.mbt           # FileReadTool
│   ├── file_write.mbt          # FileWriteTool
│   ├── shell.mbt               # ShellTool
│   ├── schema.mbt              # JSON Schema 辅助
│   ├── tool_guard.mbt          # ToolGuard（白名单/黑名单）
│   ├── tool_middleware.mbt     # 重试/超时中间件
│   └── moon.pkg
├── chains/                     # 链式编排
│   ├── llm_chain.mbt           # LLMChain（prompt + provider + memory + parser + stream）
│   ├── llm_chain_wbtest.mbt    # 白盒测试: 7 tests
│   └── moon.pkg
├── agents/                     # ReAct Agent
│   ├── agent_executor.mbt      # AgentExecutor（run_agent + memory + parser + stream）
│   ├── agent_executor_wbtest.mbt  # 白盒测试: 4 tests
│   └── moon.pkg
├── config/                     # 统一配置（v0.9）
│   ├── config.mbt              # ChatConfig + load_config
│   ├── config_js.mbt           # JS 目标文件读取
│   ├── config_native.mbt       # Native 目标（回退到 env vars）
│   ├── config_wasm.mbt         # Wasm 目标（回退到 env vars）
│   ├── config_native_stub.c    # Native C stub（v0.10）
│   └── moon.pkg
├── observability/              # 可观测性（v0.9-5）
│   ├── observability.mbt       # UsageTracker + CallTrace + TimingTracker
│   ├── observability_wbtest.mbt # 白盒测试: 12 tests
│   └── moon.pkg
├── mcp/                        # MCP 协议桥接（v0.8）
│   ├── mcp_types.mbt           # JSON-RPC 2.0 类型
│   ├── mcp_client.mbt          # MCPClient
│   ├── mcp_server.mbt          # MCPServer
│   ├── mcp_bridge.mbt          # MCPToolBridge
│   └── moon.pkg
├── rag/                        # RAG 基础（v0.10）
│   ├── loader.mbt              # Document + TextLoader + SimpleTextLoader
│   ├── splitter.mbt            # TextSplitter + RecursiveCharacterTextSplitter
│   ├── splitter_wbtest.mbt     # 白盒测试: 3 tests
│   └── moon.pkg
├── cmd/
│   ├── main/                   # CLI 入口（打印版本信息）
│   │   ├── main.mbt
│   │   └── moon.pkg
│   └── chat/                   # 交互式 REPL（v0.8 引入，v0.10 升级）
│       ├── main.mbt
│       ├── io_js.mbt           # JS stdin FFI
│       ├── io_native.mbt       # Native stdin stub
│       ├── io_wasm.mbt         # Wasm stdin stub
│       └── moon.pkg
├── local-test/                 # 本地集成测试（gitignored）
│   ├── main.mbt
│   └── moon.pkg
└── examples/                   # 示例
    ├── quickstart/             # 最小 LLMChain 示例（v0.9 接入 config）
    │   ├── main.mbt
    │   └── moon.pkg
    └── react_agent/            # ReAct Agent + 内置工具示例（v0.9 接入 config）
        ├── main.mbt
        └── moon.pkg
```

**包依赖关系**：
- `chains` 依赖 `prompts`, `memory`, `parsers`, `core`
- `agents` 依赖 `memory`, `parsers`
- `memory` 依赖 `mizchi/llm`（SummaryMemory 需要 Provider 做摘要）
- `tools` 依赖 `moonbitlang/core/json`, `mizchi/llm/tools`
- `config` 依赖 `moonbitlang/core/json`, `moonbitlang/core/env`（多目标 FFI）
- `observability` 依赖 `mizchi/llm`, `moonbitlang/core/json`
- `mcp` 依赖 `mizchi/llm`, `mizchi/llm/tools`, `mihujiang/agent/tools`
- `rag` 无内部依赖
- `cmd/chat` 依赖 `config`, `observability`, `memory`, `tools`, `mizchi/llm`
- `core`, `prompts`, `parsers` 无内部依赖，只依赖标准库和 `mizchi/llm`

### 设计原则

1. **类型安全**：所有抽象用 trait + 泛型 struct，编译期保证接口契约
2. **可组合**：Chain / Agent / Memory / Tool 都是独立单元，可自由组合
3. **可嵌入**：作为库嵌入任何 MoonBit 应用，不强制运行时假设
4. **薄封装**：不在 `mizchi/llm` 之上过度抽象，能力不够时可直接降级用底层 API
5. **渐进式**：从最简 `LLMChain` 到复杂 `AgentExecutor`，按需取用

### 编码规范

- MoonBit 代码以块（block）风格组织，每个块由 `///|` 分隔，块的顺序无关紧要。

- 每个包的 public API 集中在该包的主文件。文件命名规则：
  - `<功能>.mbt`：公开 API 实现
  - `<功能>_wbtest.mbt`：白盒测试（可访问包内类型和函数）
  - `_test.mbt`：黑盒测试（仅访问 public API）

- **trait 实现必须加 `pub`**：`pub impl Trait for Type ...` 才能跨包可见。

- **Boxed trait 对象模式**：用 `BoxedMemory`、`BoxedOutputParser` 等 wrapper 将 `&Trait` 引用装箱。

- **测试用 mock**：每个测试文件定义自己的 `TestMockProvider`（参考 `chains/llm_chain_wbtest.mbt`）。

### 工具链

- `moon fmt`：格式化代码。CI 中通过 `moon fmt --check` 验证。
- `moon build --target <target>`：构建指定目标（native / wasm-gc / js）。
- `moon test --target <target>`：运行所有测试。
- `moon info --target <target>`：更新 `.mbti` 接口文件。
- `moon update`：更新 registry 索引。

### 添加新功能指南

1. **添加新包**：在 MoonBit/ 下创建目录，添加 `moon.pkg` 和源文件
2. **添加新 trait**：定义 trait，创建对应的 `Boxed*` wrapper
3. **接入 LLMChain/AgentExecutor**：在对应 `with_*` 方法中接受 `&Trait` 引用
4. **添加测试**：创建 `<name>_wbtest.mbt`，覆盖边界情况
5. **更新文档**：`USAGE.md`、`README.mbt.md`、`AGENTS.md`、本地 `文件/` 下的四个文档

### 版本发布流程

1. 确保 `moon fmt --check` + `moon build` + `moon test` 三目标全绿
2. 更新 `moon.mod` 中的 `version`
3. 更新 `agent.mbt` 中的 `version` 常量
4. 更新 `README.mbt.md` 中的版本 badge
5. 提交并推送，等待 CI 全绿
6. 打 tag：`git tag v0.x.0 && git push origin v0.x.0`
7. 发布到 mooncakes：`moon publish`

---

## English Guide

This is an [MoonBit](https://docs.moonbitlang.com) AI Agent framework project (moon-agent), positioned as a MoonBit port of LangChain's core abstractions. Repository: <https://github.com/mihujiang/MoonBit>.

You can browse and install extra skills here: <https://github.com/moonbitlang/skills>

### Design Principles

1. **Type safety**: All abstractions use traits + generic structs, compile-time interface contract guarantees
2. **Composability**: Chain / Agent / Memory / Tool are independent units, freely composable
3. **Embeddability**: Embed as a library into any MoonBit application, no runtime assumptions forced
4. **Thin wrapping**: No over-abstraction on top of `mizchi/llm`; fall back to the lower-level API when needed
5. **Progressive**: From minimal `LLMChain` to complex `AgentExecutor`, pick what you need

### Coding Conventions

- MoonBit code is organized in block style, each block separated by `///|`, order irrelevant.
- File naming: `<feature>.mbt` (public API), `<feature>_wbtest.mbt` (whitebox tests), `_test.mbt` (blackbox tests).
- **Trait implementations must use `pub`**: `pub impl Trait for Type ...` for cross-package visibility.
- **Boxed trait object pattern**: Use `BoxedMemory`, `BoxedOutputParser` etc. to box `&Trait` references.
- **Test mocks**: Each test file defines its own `TestMockProvider` (see `chains/llm_chain_wbtest.mbt`).

### Tooling

- `moon fmt`: Format code. CI uses `moon fmt --check`.
- `moon build --target <target>`: Build for specified target.
- `moon test --target <target>`: Run all tests.
- `moon info --target <target>`: Update `.mbti` interface files.
- `moon update`: Update registry index.

### Adding New Features

1. Create directory under MoonBit/, add `moon.pkg` and source files
2. Define trait, create `Boxed*` wrapper
3. Accept `&Trait` references in `with_*` methods
4. Create `<name>_wbtest.mbt`, cover edge cases
5. Update docs: `USAGE.md`, `README.mbt.md`, `AGENTS.md`, local `文件/` docs

### Release Process

1. Ensure `moon fmt --check` + `moon build` + `moon test` pass on all three targets
2. Update `version` in `moon.mod`
3. Update `version` constant in `agent.mbt`
4. Update version badge in `README.mbt.md`
5. Commit and push, wait for CI green
6. Tag: `git tag v0.x.0 && git push origin v0.x.0`
7. Publish to mooncakes: `moon publish`