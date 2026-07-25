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
