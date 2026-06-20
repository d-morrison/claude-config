---
name: merged
description: "Alias for `wrap-up`. End-of-session wrap-up: verify the true state of every PR/issue/branch/working tree (never assume), report a linked final summary that surfaces anything still open or dangling, then run a UMS review to persist what was learned. Use when invoked as `/merged`, or on 'wrap up', 'finish up', 'are we done?', or to close out a multi-PR/issue session."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# merged (alias for `wrap-up`)

This is a **synonym for [`wrap-up`](../wrap-up/SKILL.md)** — the two are
interchangeable. There is no separate behavior here.

**Do this:** read `~/.claude/skills/wrap-up/SKILL.md` and follow its
instructions exactly. Everything that skill says — verify the real state of
every PR/issue/branch/working tree, report a linked final summary that surfaces
anything still open, then run a UMS review to persist what was learned —
applies unchanged.

Keep the logic only in `wrap-up`; this file is just the `/merged` entry point
so the two names stay in sync.

> Not to be confused with [`post-merge`](../post-merge/SKILL.md), which wraps up
> a single just-merged PR. `/merged` routes to the session-level `wrap-up`.
