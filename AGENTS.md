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
├── AGENTS.md                   # 本文件
├── LICENSE                     # Apache-2.0
├── .gitignore
├── .githooks/                  # Git 钩子
│   ├── pre-commit              # 提交前检查（moon check）
│   └── README.md
├── .github/workflows/          # CI 配置
│   ├── ci.yml                  # 主 CI（native/wasm-gc/js 三目标矩阵）
│   └── copilot-setup-steps.yml
│
├── core/                       # 可组合单元（RunnableWrapper + SequentialChain）
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
├── tools/                      # 工具抽象
│   ├── tool.mbt                # Tool trait + register_into 桥接
│   └── moon.pkg
├── chains/                     # 链式编排
│   ├── llm_chain.mbt           # LLMChain（prompt + provider + memory + parser + stream）
│   ├── llm_chain_wbtest.mbt    # 白盒测试: 7 tests
│   └── moon.pkg
├── agents/                     # ReAct Agent
│   ├── agent_executor.mbt      # AgentExecutor（run_agent + memory + parser + stream）
│   ├── agent_executor_wbtest.mbt  # 白盒测试: 4 tests
│   └── moon.pkg
├── cmd/main/                   # CLI 入口
│   ├── main.mbt                # 打印版本信息
│   └── moon.pkg
└── examples/                   # 示例
    ├── quickstart/             # 最小 LLMChain 示例
    │   ├── main.mbt
    │   └── moon.pkg
    └── react_agent/            # 自定义 Tool + ReAct Agent 示例
        ├── main.mbt
        └── moon.pkg
```

**包依赖关系**：
- `chains` 依赖 `prompts`, `memory`, `parsers`, `core`
- `agents` 依赖 `memory`, `parsers`
- `memory` 依赖 `mizchi/llm`（SummaryMemory 需要 Provider 做摘要）
- `tools` 依赖 `moonbitlang/core/json`, `mizchi/llm/tools`
- `core`, `prompts`, `parsers` 无内部依赖，只依赖标准库和 `mizchi/llm`

### 设计原则

1. **类型安全**：所有抽象用 trait + 泛型 struct，编译期保证接口契约
2. **可组合**：Chain / Agent / Memory / Tool 都是独立单元，可自由组合
3. **可嵌入**：作为库嵌入任何 MoonBit 应用，不强制运行时假设
4. **薄封装**：不在 `mizchi/llm` 之上过度抽象，能力不够时可直接降级用底层 API
5. **渐进式**：从最简 `LLMChain` 到复杂 `AgentExecutor`，按需取用

### 编码规范

- MoonBit 代码以块（block）风格组织，每个块由 `///|` 分隔，块的顺序无关紧要。在某些重构中，可以逐块独立处理。

- 每个包的 public API 集中在该包的主文件（如 `core.mbt`、`llm_chain.mbt`）。文件命名规则：
  - `<功能>.mbt`：公开 API 实现
  - `<功能>_wbtest.mbt`：白盒测试（可访问包内类型和函数）
  - `_test.mbt`：黑盒测试（仅访问 public API）

- 尽量将废弃的块保留在每个目录下名为 `deprecated.mbt` 的文件中。

- **trait 实现必须加 `pub`**：MoonBit 要求 `pub impl Trait for Type ...` 才能让 trait 实现跨包可见。忘记加 `pub` 会导致调用方找不到实现。

- **Boxed trait 对象模式**：因 MoonBit trait 不能直接作类型，框架中用 `BoxedMemory`、`BoxedOutputParser` 等 wrapper 将 `&Trait` 引用装箱。添加新的 trait + 装箱对时，参考 `boxed_memory.mbt` 和 `boxed_parser.mbt`。

- **测试用 mock**：`mizchi/llm` 的 `MockProvider` 有非 pub impl，不能跨包使用。每个测试文件定义自己的 `TestMockProvider`（参考 `chains/llm_chain_wbtest.mbt`）。

### 工具链

- `moon fmt`：格式化代码。CI 中通过 `moon fmt --check` 验证格式一致性。

- `moon check --target <target>`：类型检查（比 build 轻量，不生成产物）。

- `moon build --target <target>`：构建指定目标（native / wasm-gc / js）。注意 native 需要 C 编译器（gcc/clang）。

- `moon test --target <target>`：运行所有测试。MoonBit 支持快照测试；当改动影响输出时，运行 `moon test --update` 刷新快照。

- `moon info --target <target>`：更新包的生成接口文件 `.mbti`。如果 `.mbti` 没有变化，说明改动对外部包用户不可见，通常是安全的重构。

- `moon clean`：清理 build 产物。建议在 CI 构建前执行以确保完全重新编译。

- `moon update`：更新 registry 索引和依赖的 mooncakes。

- 在最后一步，运行 `moon info && moon fmt` 更新接口并格式化代码。检查 `.mbti` 文件的 diff 以确认改动符合预期。

- 对于稳定或极不可能改变的结果，优先使用 `assert_eq` 或 `assert_true(pattern is Pattern(...))`。对于记录结构化调试输出的快照测试，应派生 `Debug` 并使用 `debug_inspect`，而不是为调试派生 `Show`。对于明确定义的稳固结果（如科学计算），优先使用断言测试。可以使用 `moon coverage analyze > uncovered.log` 查看代码中未被测试覆盖的部分。

### 添加新功能指南

1. **添加新包**：在 MoonBit/ 下创建目录，添加 `moon.pkg`（声明依赖）和源文件
2. **添加新 trait**：定义 trait，创建对应的 `Boxed*` wrapper（参考 `BoxedMemory`）
3. **接入 LLMChain/AgentExecutor**：在对应 `with_*` 方法中接受 `&Trait` 引用，内部装箱
4. **添加测试**：创建 `<name>_wbtest.mbt`，定义 `TestMockProvider`，覆盖边界情况
5. **更新 .mbti**：`moon info --target native` 重新生成接口文件
6. **更新文档**：`使用手册.md`、`进度.md`、`README.mbt.md`、本文件

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

### Project Structure

```
MoonBit/
├── moon.mod                    # Module metadata (name, version, dependencies)
├── moon.pkg                    # Root package declaration
├── agent.mbt                   # Root module (version constant + docs)
├── README.mbt.md               # Project README
├── AGENTS.md                   # This file
├── LICENSE                     # Apache-2.0
├── .gitignore
├── .githooks/                  # Git hooks
│   ├── pre-commit              # Pre-commit check (moon check)
│   └── README.md
├── .github/workflows/          # CI configuration
│   ├── ci.yml                  # Main CI (native/wasm-gc/js matrix)
│   └── copilot-setup-steps.yml
│
├── core/                       # Composable units (RunnableWrapper + SequentialChain)
│   ├── core.mbt
│   ├── core_wbtest.mbt         # Whitebox tests: 11 tests
│   └── moon.pkg
├── prompts/                    # Prompt templates
│   ├── template.mbt            # PromptTemplate ({var} interpolation)
│   ├── chat_prompt.mbt         # ChatPromptTemplate (multi-role ordered messages)
│   ├── template_wbtest.mbt     # Whitebox tests: 6 tests
│   └── moon.pkg
├── parsers/                    # Output parsers
│   ├── parser.mbt              # OutputParser trait + JsonOutputParser
│   ├── boxed_parser.mbt        # BoxedOutputParser (trait object boxing)
│   ├── parser_wbtest.mbt       # Whitebox tests: 7 tests
│   └── moon.pkg
├── memory/                     # Conversation memory
│   ├── memory.mbt              # Memory trait
│   ├── buffer_memory.mbt       # BufferMemory + BufferWindowMemory
│   ├── summary_memory.mbt      # SummaryMemory (periodic LLM summarization)
│   ├── boxed_memory.mbt        # BoxedMemory (trait object boxing)
│   ├── buffer_memory_wbtest.mbt  # Whitebox tests: 5 tests
│   ├── summary_memory_wbtest.mbt # Whitebox tests: 5 tests
│   └── moon.pkg
├── tools/                      # Tool abstraction
│   ├── tool.mbt                # Tool trait + register_into bridge
│   └── moon.pkg
├── chains/                     # Chain orchestration
│   ├── llm_chain.mbt           # LLMChain (prompt + provider + memory + parser + stream)
│   ├── llm_chain_wbtest.mbt    # Whitebox tests: 7 tests
│   └── moon.pkg
├── agents/                     # ReAct Agent
│   ├── agent_executor.mbt      # AgentExecutor (run_agent + memory + parser + stream)
│   ├── agent_executor_wbtest.mbt  # Whitebox tests: 4 tests
│   └── moon.pkg
├── cmd/main/                   # CLI entry point
│   ├── main.mbt                # Prints version info
│   └── moon.pkg
└── examples/                   # Examples
    ├── quickstart/             # Minimal LLMChain example
    │   ├── main.mbt
    │   └── moon.pkg
    └── react_agent/            # Custom Tool + ReAct Agent example
        ├── main.mbt
        └── moon.pkg
```

**Package dependency graph**:
- `chains` depends on `prompts`, `memory`, `parsers`, `core`
- `agents` depends on `memory`, `parsers`
- `memory` depends on `mizchi/llm` (SummaryMemory needs Provider for summarization)
- `tools` depends on `moonbitlang/core/json`, `mizchi/llm/tools`
- `core`, `prompts`, `parsers` have no internal deps, only stdlib and `mizchi/llm`

### Design Principles

1. **Type safety**: All abstractions use traits + generic structs, compile-time interface contract guarantees
2. **Composability**: Chain / Agent / Memory / Tool are independent units, freely composable
3. **Embeddability**: Embed as a library into any MoonBit application, no runtime assumptions forced
4. **Thin wrapping**: No over-abstraction on top of `mizchi/llm`; fall back to the lower-level API when needed
5. **Progressive**: From minimal `LLMChain` to complex `AgentExecutor`, pick what you need

### Coding Conventions

- MoonBit code is organized in block style, each block is separated by `///|`, the order of each block is irrelevant. In some refactorings, you can process block by block independently.

- Each package's public API is concentrated in its main file (e.g., `core.mbt`, `llm_chain.mbt`). File naming rules:
  - `<feature>.mbt`: public API implementation
  - `<feature>_wbtest.mbt`: whitebox tests (can access package-internal types and functions)
  - `_test.mbt`: blackbox tests (only access public API)

- Try to keep deprecated blocks in file called `deprecated.mbt` in each directory.

- **Trait implementations must use `pub`**: MoonBit requires `pub impl Trait for Type ...` for trait implementations to be visible across packages. Forgetting `pub` will result in callers not finding the implementation.

- **Boxed trait object pattern**: Since MoonBit traits cannot be used directly as types, the framework uses `BoxedMemory`, `BoxedOutputParser`, etc. to box `&Trait` references. When adding a new trait + boxed pair, refer to `boxed_memory.mbt` and `boxed_parser.mbt`.

- **Test mocks**: `mizchi/llm`'s `MockProvider` has a non-pub impl and cannot be used across packages. Each test file defines its own `TestMockProvider` (refer to `chains/llm_chain_wbtest.mbt`).

### Tooling

- `moon fmt`: Format code. In CI, use `moon fmt --check` to verify format consistency.

- `moon check --target <target>`: Type check (lighter than build, no artifacts produced).

- `moon build --target <target>`: Build for specified target (native / wasm-gc / js). Note: native requires a C compiler (gcc/clang).

- `moon test --target <target>`: Run all tests. MoonBit supports snapshot testing; when changes affect outputs, run `moon test --update` to refresh snapshots.

- `moon info --target <target>`: Update the package's generated interface file `.mbti`. If nothing in `.mbti` changes, it means your change is not visible to external package users — typically a safe refactoring.

- `moon clean`: Clean build artifacts. Recommended to execute before CI builds to ensure full recompilation.

- `moon update`: Update registry index and dependency mooncakes.

- In the last step, run `moon info && moon fmt` to update the interface and format the code. Check the diffs of `.mbti` files to see if the changes are expected.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that are stable or very unlikely to change. For snapshot tests that record structured debugging output, derive `Debug` and use `debug_inspect`, rather than deriving `Show` for debugging. For solid, well-defined results (e.g. scientific computations), prefer assertion tests. You can use `moon coverage analyze > uncovered.log` to see which parts of your code are not covered by tests.

### Adding New Features

1. **Add a new package**: Create a directory under MoonBit/, add `moon.pkg` (declare dependencies) and source files
2. **Add a new trait**: Define the trait, create the corresponding `Boxed*` wrapper (refer to `BoxedMemory`)
3. **Wire into LLMChain/AgentExecutor**: Accept `&Trait` references in the corresponding `with_*` method, box internally
4. **Add tests**: Create `<name>_wbtest.mbt`, define `TestMockProvider`, cover edge cases
5. **Update .mbti**: `moon info --target native` to regenerate interface files
6. **Update docs**: `使用手册.md`, `进度.md`, `README.mbt.md`, this file

### Release Process

1. Ensure `moon fmt --check` + `moon build` + `moon test` pass on all three targets
2. Update `version` in `moon.mod`
3. Update the `version` constant in `agent.mbt`
4. Update the version badge in `README.mbt.md`
5. Commit and push, wait for CI to go green
6. Tag: `git tag v0.x.0 && git push origin v0.x.0`
7. Publish to mooncakes: `moon publish`
