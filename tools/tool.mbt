///|
/// Tool is the structured tool abstraction for moon-agent.
///
/// Unlike mizchi/llm's closure-based `ToolRegistry.register`, the `Tool`
/// trait provides a declarative interface with `name`, `description`,
/// `args_schema`, and `run`. This enables:
/// - Declarative tool definition (no inline closures)
/// - Dry-run / inspection (list tools without executing)
/// - Dependency injection (tools can carry their own state)
/// - Future features: tool middleware, retry policies, async execution
///
/// To bridge with mizchi/llm's ToolRegistry, use `Tool::register_into`.
pub(open) trait Tool {
  /// Tool name as exposed to the LLM. Should be unique within a registry.
  fn name(Self) -> String

  /// Human-readable description that helps the LLM decide when to call.
  fn description(Self) -> String

  /// JSON Schema describing the tool's input parameters.
  fn args_schema(Self) -> Json

  /// Execute the tool with the given JSON input, returning a string result.
  fn run(Self, Json) -> String
}

///|
/// Build a `@llm_tools.ToolDef` from any `Tool` implementation.
///
/// This is the bridge from moon-agent's trait-based Tool to mizchi/llm's
/// ToolDef (which is what `ToolRegistry` consumes).
pub fn[T : Tool] to_tool_def(tool : T) -> @llm_tools.ToolDef {
  @llm_tools.ToolDef::new(tool.name(), tool.description(), tool.args_schema())
}

///|
/// Register a `Tool` implementation into a mizchi/llm `ToolRegistry`.
///
/// The tool's `run` method is wrapped in a closure that delegates to
/// `tool.run(input)`. Note: this moves `tool` into the closure.
pub fn[T : Tool] register_into(
  registry : @llm_tools.ToolRegistry,
  tool : T,
) -> Unit {
  let def = to_tool_def(tool)
  registry.register_def(def, fn(input : Json) -> String { tool.run(input) })
}
