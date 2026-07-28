///|
/// RunnableWrapper wraps a closure as a composable unit.
///
/// Inspired by LangChain's Runnable / LCEL (LangChain Expression Language).
/// Since MoonBit traits cannot have type parameters, we use a generic struct
/// to achieve similar composability.
pub struct RunnableWrapper[I, O] {
  run : (I) -> O
}

///|
pub fn[I, O] RunnableWrapper::new(run : (I) -> O) -> RunnableWrapper[I, O] {
  { run, }
}

///|
pub fn[I, O] RunnableWrapper::invoke(
  self : RunnableWrapper[I, O],
  input : I,
) -> O {
  (self.run)(input)
}

///|
/// Pipe the output of this wrapper into another wrapper.
///
/// Produces a new `RunnableWrapper[I, O2]` that runs `self` first,
/// then feeds the result into `next`. This is the LCEL-style `|>`
/// composition.
///
/// Example:
/// ```moonbit nocheck
/// let parse = RunnableWrapper::new(fn(s : String) -> Int { s.to_int() })
/// let doubler = RunnableWrapper::new(fn(n : Int) -> Int { n * 2 })
/// let composed = parse.pipe(doubler)
/// composed.invoke("21") // -> 42
/// ```
pub fn[I, O, O2] RunnableWrapper::pipe(
  self : RunnableWrapper[I, O],
  next : RunnableWrapper[O, O2],
) -> RunnableWrapper[I, O2] {
  let first = self
  RunnableWrapper::new(fn(input : I) -> O2 {
    let mid = first.invoke(input)
    next.invoke(mid)
  })
}

///|
/// Transform the output of this wrapper with `f`.
///
/// Produces a new `RunnableWrapper[I, O2]` that runs `self`, then
/// applies `f` to the result.
pub fn[I, O, O2] RunnableWrapper::map(
  self : RunnableWrapper[I, O],
  f : (O) -> O2,
) -> RunnableWrapper[I, O2] {
  let prev = self
  RunnableWrapper::new(fn(input : I) -> O2 { f(prev.invoke(input)) })
}

///|
/// SequentialChain runs a list of `RunnableWrapper[T, T]` in sequence,
/// feeding the output of each step as input to the next.
///
/// This is moon-agent's equivalent of LangChain's `SequentialChain`. It
/// requires every step to share the same input/output type `T` so the
/// chain is type-homogeneous end-to-end. For heterogeneous chains, use
/// `RunnableWrapper::pipe` directly to compose step by step with full
/// type information at each boundary.
///
/// Construction uses `SequentialChain::new` with a non-empty array. An
/// empty array is a programmer error and aborts at construction time
/// (consistent with how MoonBit's `Array::first` etc. treat empty).
///
/// Example:
/// ```moonbit nocheck
/// let step1 = RunnableWrapper::new(fn(s : String) -> String { s + "!" })
/// let step2 = RunnableWrapper::new(fn(s : String) -> String { "(" + s + ")" })
/// let chain = SequentialChain::new([step1, step2])
/// chain.invoke("hi") // -> "(hi!)"
/// ```
pub struct SequentialChain[T] {
  steps : Array[RunnableWrapper[T, T]]
}

///|
/// Build a SequentialChain from a non-empty list of homogeneous steps.
/// Each step must have matching input and output type `T`.
///
/// Aborts if `steps` is empty — a chain with zero steps has no defined
/// output and is almost certainly a bug at the call site.
pub fn[T] SequentialChain::new(
  steps : Array[RunnableWrapper[T, T]],
) -> SequentialChain[T] {
  if steps.is_empty() {
    abort("SequentialChain::new requires a non-empty array of steps")
  }
  { steps, }
}

///|
/// Run the chain: feed `input` to the first step, then pipe the output
/// of each step into the next. Returns the final step's output.
pub fn[T] SequentialChain::invoke(self : SequentialChain[T], input : T) -> T {
  let mut current = input
  for step in self.steps {
    current = step.invoke(current)
  }
  current
}

///|
/// Convert this SequentialChain into a single `RunnableWrapper[T, T]`,
/// enabling further composition (e.g. piping into another chain or
/// wrapper).
pub fn[T] SequentialChain::as_runnable(
  self : SequentialChain[T],
) -> RunnableWrapper[T, T] {
  let chain = self
  RunnableWrapper::new(fn(input : T) -> T { chain.invoke(input) })
}

///|
/// Number of steps in the chain.
pub fn[T] SequentialChain::length(self : SequentialChain[T]) -> Int {
  self.steps.length()
}

///|
/// RouterChain dispatches input to one of several `RunnableWrapper` handlers
/// based on a decide function.
///
/// This is moon-agent's equivalent of LangChain's `RouterChain`. It is
/// simpler than the LangChain version because the routing decision is
/// made by a user-provided function (which may itself call an LLM or
/// use simple keyword matching). This design keeps the routing logic
/// explicit and testable, while still enabling LLM-based routing when
/// desired.
///
/// Routes are `RunnableWrapper[Map[String, String], String]` — the same
/// signature as `LLMChain::as_runnable()`, making it straightforward to
/// route to different LLMChains.
///
/// Construction requires a decide function and at least a default route.
/// Additional routes are added via `add_route`.
///
/// Example:
/// ```moonbit nocheck
/// let math_chain = math_llm_chain.as_runnable()
///
/// let chat_chain = chat_llm_chain.as_runnable()
///
/// let fallback = default_chain.as_runnable()
///
/// let router = RouterChain::new(
///     fn(input) {
///       if input.contains("+") || input.contains("*") {
///         "math"
///       } else {
///         ""
///       }
///     },
///     fallback,
///   )
///   |> RouterChain::add_route("math", math_chain)
///   |> RouterChain::add_route("chat", chat_chain)
///
/// let result = router.invoke({ "input": "What is 2 + 3?" })
/// // → routed to math_chain
/// ```
pub struct RouterChain {
  decide : (String) -> String
  routes : Map[String, RunnableWrapper[Map[String, String], String]]
  default : RunnableWrapper[Map[String, String], String]
}

///|
/// Create a RouterChain with a decide function and a default handler.
///
/// The decide function receives the raw user input (typically from
/// `vars["input"]`) and returns a route key. If the key is not found
/// in the routes table, the default handler is used.
pub fn RouterChain::new(
  decide : (String) -> String,
  default : RunnableWrapper[Map[String, String], String],
) -> RouterChain {
  { decide, routes: Map([]), default }
}

///|
/// Add a route handler for the given key. Returns self for chaining.
pub fn RouterChain::add_route(
  self : RouterChain,
  key : String,
  handler : RunnableWrapper[Map[String, String], String],
) -> RouterChain {
  self.routes[key] = handler
  self
}

///|
/// Decide which route to take based on user input, then run the
/// selected handler. Falls back to the default handler if no route
/// matches.
pub fn RouterChain::invoke(
  self : RouterChain,
  vars : Map[String, String],
) -> String {
  let input = match vars.get("input") {
    Some(s) => s
    None => ""
  }
  let key = (self.decide)(input)
  let handler = match self.routes.get(key) {
    Some(h) => h
    None => self.default
  }
  handler.invoke(vars)
}

///|
/// Convert this RouterChain into a single `RunnableWrapper[Map[String, String], String]`,
/// enabling further composition (e.g. piping into another wrapper).
pub fn RouterChain::as_runnable(
  self : RouterChain,
) -> RunnableWrapper[Map[String, String], String] {
  let chain = self
  RunnableWrapper::new(fn(vars : Map[String, String]) -> String {
    chain.invoke(vars)
  })
}

///|
/// Number of routes (excluding the default handler).
pub fn RouterChain::route_count(self : RouterChain) -> Int {
  self.routes.length()
}
