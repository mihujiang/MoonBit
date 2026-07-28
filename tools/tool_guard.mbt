///|
/// ToolGuard provides a tool filtering / whitelist mechanism.
///
/// When building an Agent, you may want to restrict which tools it can
/// call. ToolGuard wraps the tool registration process and only allows
/// tools whose names pass the filter.
///
/// Two modes:
/// - Allowlist (default): only tools in the list can be registered.
/// - Denylist: tools in the list are blocked; all others pass.
///
/// Example (allowlist — only calculator and datetime):
/// ```moonbit nocheck
/// let guard = ToolGuard::allowlist(["calculator", "datetime"])
/// guard.register(registry, CalculatorTool::new())
/// guard.register(registry, ShellTool::new(fn(cmd) { "ok" })) // blocked!
/// ```
///
/// Example (denylist — block dangerous tools):
/// ```moonbit nocheck
/// let guard = ToolGuard::denylist(["shell_exec"])
/// guard.register(registry, ShellTool::new(fn(cmd) { "ok" })) // blocked!
/// guard.register(registry, CalculatorTool::new()) // allowed
/// ```
struct ToolGuard {
  list : Array[String]
  mode : GuardMode
}

///|
priv enum GuardMode {
  Allowlist
  Denylist
}

///|
/// Create a ToolGuard in allowlist mode. Only tools whose name is in
/// the list can be registered.
pub fn ToolGuard::allowlist(names : Array[String]) -> ToolGuard {
  { list: names, mode: GuardMode::Allowlist }
}

///|
/// Create a ToolGuard in denylist mode. Tools in the list are blocked;
/// all others pass.
pub fn ToolGuard::denylist(names : Array[String]) -> ToolGuard {
  { list: names, mode: GuardMode::Denylist }
}

///|
/// Check whether the given tool name is allowed.
pub fn ToolGuard::is_allowed(self : ToolGuard, name : String) -> Bool {
  let found = self.list.any(fn(item) { item == name })
  match self.mode {
    GuardMode::Allowlist => found
    GuardMode::Denylist => found == false
  }
}

///|
/// Register a `Tool` into a registry only if the tool's name passes
/// the guard. Returns `true` if registered, `false` if blocked.
pub fn[T : Tool] ToolGuard::register(
  self : ToolGuard,
  registry : @llm_tools.ToolRegistry,
  tool : T,
) -> Bool {
  if self.is_allowed(tool.name()) {
    register_into(registry, tool)
    true
  } else {
    false
  }
}

///|
/// Number of names in the guard list.
pub fn ToolGuard::size(self : ToolGuard) -> Int {
  self.list.length()
}
