When a heavy skill runs, decide whether to fan the work out to a **Workflow**
(multi-agent orchestration) instead of handling it inline. This is the shared
decision rule the parallelizable skills consult.

## The opt-in gate comes first

The `Workflow` tool is opt-in-gated and a skill cannot override that for a bare
prompt. But *an invoked skill whose instructions say to use a workflow* is itself
a sanctioned opt-in. So this rule never forces a workflow --- it only decides
whether to **launch** one or **propose** one:

- **Launch directly** when an opt-in signal is already present: the user wrote
  `ultracode`, set a `+Nk` token budget, said "use a workflow" / "fan out", or
  ultracode is on for the session.
- **Otherwise propose with a one-line cost estimate** and wait --- e.g. "This is
  workflow-shaped: ~N agents, ~Xk tokens. Run it as a workflow, or inline?" Never
  auto-spend on a large fan-out without a signal.

## When the task is workflow-shaped

Orchestrate only when **all three** hold:

1. **Decomposable** --- the work splits into at least ~4 independent targets
   (files, sources, review dimensions, gradable items) whose handling does not
   depend on each other's results.
2. **Verification-bearing** --- the targets benefit from adversarial
   double-checking (review, audit, research, grading), not just a mechanical edit
   applied uniformly.
3. **Scale earns it** --- serial handling would be slow or lossy: a broad sweep,
   a whole-corpus pass, or an ask that says "thorough", "comprehensive", "audit",
   or "every".

## The shared-runner exception

Fanning out work that **pushes commits and triggers CI / a review bot per target**
(driving several open PRs, opening several issue PRs at once) does **not** clear
this bar, even at ~4+ targets: the targets are decomposable but they collide on
shared review runners and make per-PR status illegible. That is why `ardia`
drives PRs one at a time and `gip` caps concurrency. For those, orchestrate only
the **read-only** part (survey every PR's latest review in parallel) and keep the
push --- re-review --- merge actions serial or capped.

## Stay inline when

- There is a single target, or fewer than ~4.
- The change is trivial and mechanical (a rename, a one-line fix, a known edit).
- The answer is one lookup, or the user asked a conversational question.
- Flattening the work into a workflow would be more convoluted than just doing
  it.

## What "propose" looks like in practice

Estimate the fan-out from the target count: roughly one agent per target for a
single-pass sweep, two to three per target when each target also gets an
adversarial verify pass. State the agent count and a rough token figure, name the
inline alternative, and let the user choose. If they decline, do the work inline
--- the proposal is a recommendation, not a gate.

Scale the harness to the ask: a quick "find any bugs" wants a few finders and a
single verify; "thoroughly audit this" wants a larger finder pool, a 3--5 vote
adversarial pass, and a synthesis stage.
