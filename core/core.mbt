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
