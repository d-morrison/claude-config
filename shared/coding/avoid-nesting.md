When writing code, **avoid nested function calls and nested function
definitions where feasible**:

- Prefer named intermediate variables (or a pipe, e.g. `|>` / `%>%` in R) over
  deeply nested calls like `f(g(h(x)))`. Naming each step makes the data flow
  read top-to-bottom and leaves intermediate values inspectable in a debugger.
- Prefer standalone, top-level function definitions over functions defined
  inside other functions. Nested definitions hide reusable logic, complicate
  unit testing, and obscure scope.

This is a readability/maintainability default, not an absolute rule --- keep the
nesting when flattening it would be more convoluted (a trivial one-argument
wrapper, or a closure that genuinely needs the enclosing scope).
