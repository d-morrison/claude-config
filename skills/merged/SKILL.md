---
name: merged
description: "Alias for `wrap-up`. End-of-session wrap-up: verify the true state of every PR/issue/branch/working tree (never assume), report a linked final summary that surfaces anything still open or dangling, then run a UMS review to persist what was learned. In a multi-PR session you can name the PR that just merged (e.g. `/merged #74`) to anchor the summary on it. Use when invoked as `/merged`, or on 'wrap up', 'finish up', 'are we done?', or to close out a multi-PR/issue session."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# merged (alias for `wrap-up`)

This is a **synonym for [`wrap-up`](../wrap-up/SKILL.md)** — invoking `/merged`
runs the wrap-up procedure unchanged. The one extra affordance is the optional
PR indication below.

**Do this:** read `~/.claude/skills/wrap-up/SKILL.md` and follow its
instructions exactly. Everything that skill says — verify the real state of
every PR/issue/branch/working tree, report a linked final summary that surfaces
anything still open, then run a UMS review to persist what was learned —
applies unchanged.

Keep the logic only in `wrap-up`; this file is just the `/merged` entry point
so the two names stay in sync.

## Optional: name the PR that just merged

In a multi-PR session, `/merged` can be given a specific PR — e.g. `/merged #74`,
"merged 74", or "merged the alias PR". Treat that PR as the **anchor** for the
wrap-up:

- Confirm its merge actually landed first —
  `gh pr view <N> --json state,mergedAt,mergeCommit` (never assume).
- Lead the summary with it, since that merge is what prompted the wrap-up.
- Then run the rest of `wrap-up` over the **whole** session: other open
  PRs/issues, uncommitted work, unmerged branches, leftover worktrees, then UMS.

The named PR anchors the report; it does **not** narrow the wrap-up to that one
PR. With no PR given, `/merged` is a plain session-level wrap-up.

> `/merged` routes to [`wrap-up`](../wrap-up/SKILL.md), not
> [`post-merge`](../post-merge/SKILL.md). `post-merge` wraps up a single
> just-merged PR; `wrap-up` closes the whole session.
