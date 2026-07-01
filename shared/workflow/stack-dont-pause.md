The clear-all family --- `ardia`, `gia`, `gii`, `gip`, and the `clear-all`
alias --- clears a whole queue of PRs and issues in one run. Merging stays
human-gated (see `ardi.md`: the loop reports a PR ready, it never self-merges).
But that gate stops the *merge*, not the *sweep*.

**Not having self-merge freedom is never a reason to pause between items.**
Driving a PR to fully clean ends that PR's ARDI loop, not the whole run. Once a
PR is clean, move straight to the next item --- don't stall waiting for a human
to merge it first. Waiting for a merge you're not allowed to perform would halt
the queue indefinitely, which is exactly what these skills exist to avoid.

Keep the loop moving by **stacking**. When the next item isn't naturally
independent of a completed-but-unmerged PR --- it needs that PR's code, or it
touches the same files --- branch it off that PR's tip instead of `main`, so it
stacks on top. Note the dependency in the new PR's description
(`Stacked on #N --- merge that first`) and track the merge order for the final
report. Branch off `main` only when the next item is genuinely independent of
every open PR.

So the between-item decision is always *keep going*; the only open question is
the base branch:

- **Independent of every open PR** (or the PR it depended on has already
  merged) --- branch from `origin/main`.
- **Depends on a clean-but-unmerged PR** --- branch from that PR's tip, and
  stack.

The only real stops are the queue running dry, a genuinely blocked or ambiguous
item, or a skill's own checkpoint (e.g. GII's 5-issue pause) --- never merely
because a finished PR is still waiting on a human merge.
