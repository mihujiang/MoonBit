// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "weopqrst/agent"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/weopqrst/MoonBit"

license = "Apache-2.0"

keywords = [ "ai", "agent", "llm", "langchain", "mcp", "react", "tool-calling" ]

preferred_target = "native"

description = "MoonBit version of LangChain core library — type-safe, composable, embeddable AI Agent framework. Depends on mizchi/llm for LLM clients and colmugx/mcp for MCP tool calling."

import {
  "moonbitlang/async@0.20.3",
  "mizchi/llm@0.3.1",
  "colmugx/mcp@0.14.0",
}
