# Git Hooks / Git 钩子

---

## 中文说明

## Pre-commit 钩子

此 pre-commit 钩子会在最终提交前执行自动检查。

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

3. 执行 `git commit` 时钩子将自动运行

---

## English Guide

## Pre-commit Hook

This pre-commit hook performs automatic checks before finalizing your commit.

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

3. The hook will automatically run when you execute `git commit`
