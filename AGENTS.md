# 项目 Agents.md 指南 / Project Agents.md Guide

---

## 中文说明

这是一个 [MoonBit](https://docs.moonbitlang.com) 项目。

你可以在这里浏览并安装额外的 skills：
<https://github.com/moonbitlang/skills>

### 项目结构

- MoonBit 包按目录组织；每个目录包含一个 `moon.pkg` 文件，列出其依赖。每个包有自己的源文件、黑盒测试文件（以 `_test.mbt` 结尾）和白盒测试文件（以 `_wbtest.mbt` 结尾）。

- 在顶层目录中，有一个 `moon.mod` 文件列出模块元数据。

### 编码规范

- MoonBit 代码以块（block）风格组织，每个块由 `///|` 分隔，块的顺序无关紧要。在某些重构中，可以逐块独立处理。

- 尽量将废弃的块保留在每个目录下名为 `deprecated.mbt` 的文件中。

### 工具链

- `moon fmt` 用于格式化代码。

- `moon ide` 提供项目导航辅助功能，如 `peek-def`、`outline`、`find-references`。详见 $moonbit-agent-guide。

- `moon info` 用于更新包的生成接口，每个包有一个生成接口文件 `.mbti`，它是包的简要形式化描述。如果 `.mbti` 没有变化，说明你的改动对外部包用户不可见，通常是安全的重构。

- 在最后一步，运行 `moon info && moon fmt` 更新接口并格式化代码。检查 `.mbti` 文件的 diff 以确认改动符合预期。

- 运行 `moon test` 检查测试是否通过。MoonBit 支持快照测试；当改动影响输出时，运行 `moon test --update` 刷新快照。

- 对于稳定或极不可能改变的结果，优先使用 `assert_eq` 或 `assert_true(pattern is Pattern(...))`。对于记录结构化调试输出的快照测试，应派生 `Debug` 并使用 `debug_inspect`，而不是为调试派生 `Show`。对于明确定义的稳固结果（如科学计算），优先使用断言测试。可以使用 `moon coverage analyze > uncovered.log` 查看代码中未被测试覆盖的部分。

---

## English Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

### Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

### Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

### Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. For snapshot tests that record
  structured debugging output, derive `Debug` and use `debug_inspect`, rather
  than deriving `Show` for debugging. For solid, well-defined results (e.g.
  scientific computations), prefer assertion tests. You can use
  `moon coverage analyze > uncovered.log` to see which parts of your code are
  not covered by tests.
