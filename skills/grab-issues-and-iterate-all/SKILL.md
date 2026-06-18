---
name: grab-issues-and-iterate-all
description: "Alias for `gia` (Grab Issues + iterate-All). Clear the repo's entire work queue in two phases — first ARDIA every open PR/MR to clean, then GII every open issue. Use when asked to 'grab issues and iterate all', 'clear the whole queue', 'clean all PRs then do all the issues', or 'burn down everything'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# grab-issues-and-iterate-all

This is the spelled-out **alias for [`gia`](../gia/SKILL.md)** — the two are
interchangeable. There is no separate behavior here.

**Do this:** read `~/.claude/skills/gia/SKILL.md` and follow its procedure
exactly — Phase 1 drives every open PR/MR to clean (`ardia`), Phase 2 works the
whole issue backlog (`gii`), then print one combined report.

Keep the logic only in `gia`; this file is just the spelled-out entry point so
the two names stay in sync.
