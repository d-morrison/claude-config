Whenever you are working a PR/MR, run the full **ARDI** loop by default, without
being asked: **A**ddress every flagged item, **R**ebut findings that are wrong,
**D**efer out-of-scope items to tracked issues, then **I**terate with a fresh
review --- repeating until the latest review is **fully clean**. Don't stop at
"review-clean, just needs approval" and hand triage back; keep the cycle going
until it's genuinely clean.

The loop's terminal action is to **report the PR ready, not to merge it**.
Merging is human-gated --- it happens only on an explicit human "merge it" (the
`merge-it` skill), never as a step ARDI takes on its own. So when you carry a PR
across a `ScheduleWakeup` or `/loop` wait, **never** bake a self-merge directive
like "if clean and CI green, merge it" into the wakeup/loop prompt: a scheduled
prompt fires back as a user-role turn, so a self-authored "merge it" only *looks*
like human approval (and Claude Code's auto-mode classifier will rightly deny it
as a self-authored merge). Drive to fully clean, report ready, and leave the
merge --- and any other destructive one-off, e.g. a `gh workflow run` that
force-pushes --- for explicit human authorization.

In the **clear-all family** (`ardia`, `gia`, `gii`, `gip`), "report ready, don't
merge" gates only the merge --- it does **not** pause the sweep. A
clean-but-unmerged PR is not a stop; move to the next item, and stack it when it
isn't naturally independent of that PR. See
[`stack-dont-pause`](stack-dont-pause.md).
