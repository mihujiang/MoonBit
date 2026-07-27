# Git Hooks / Git 钩子

---

## 中文说明

### Pre-commit 钩子

此 pre-commit 钩子会在每次 `git commit` 前执行 `moon check`，确保提交的代码能通过类型检查。如果类型检查失败，提交将被阻止，避免将编译失败的代码推送到远端。

### 使用说明

要使用此 pre-commit 钩子：

1. 如果脚本尚未可执行，先将其设为可执行：
   ```bash
   chmod +x .githooks/pre-commit
   ```

2. 配置 Git 使用 .githooks 目录中的钩子：
   ```bash
   git config core.hooksPath .githooks
   ```

3. 执行 `git commit` 时钩子将自动运行。

### 跳过钩子

如果需要在紧急情况下跳过检查（不推荐）：
```bash
git commit --no-verify -m "emergency fix"
```

### 常见问题

**Q：`moon check` 报 "no system C compiler found"？**

A：如果本地没有 C 编译器（Windows 常见），用 `moon check --target wasm-gc` 替代。可修改 `pre-commit` 脚本中的 `moon check` 为 `moon check --target wasm-gc`。

---

## English Guide

### Pre-commit Hook

This pre-commit hook runs `moon check` before each `git commit`, ensuring the committed code passes type checking. If type checking fails, the commit is blocked, preventing broken code from being pushed.

### Usage Instructions

To use this pre-commit hook:

1. Make the hook executable if it isn't already:
   ```bash
   chmod +x .githooks/pre-commit
   ```

2. Configure Git to use the hooks in the .githooks directory:
   ```bash
   git config core.hooksPath .githooks
   ```

3. The hook will automatically run when you execute `git commit`.

### Skipping the Hook

If you need to bypass the check in an emergency (not recommended):
```bash
git commit --no-verify -m "emergency fix"
```

### Troubleshooting

**Q: `moon check` reports "no system C compiler found"?**

A: If you don't have a C compiler installed (common on Windows), use `moon check --target wasm-gc` instead. You can modify the `pre-commit` script to use `moon check --target wasm-gc`.
