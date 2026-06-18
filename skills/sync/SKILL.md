---
name: sync
description: Alias for `sync-pr-branch`. Sync the current branch with both `main` and its own remote — fetch origin, merge origin/main and origin/<current-branch> into local, resolve conflicts, run the repo's pre-commit checks, and push. Use when invoked as `/sync`, or on "sync", "sync the branch", "sync up", or before pushing when main or the remote branch may have moved.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# sync

This is a **synonym for [`sync-pr-branch`](../sync-pr-branch/SKILL.md)** — the
two are interchangeable. There is no separate behavior here.

**Do this:** read `~/.claude/skills/sync-pr-branch/SKILL.md` and follow its
instructions exactly, against the current branch (or the branch the user
named). Everything that skill says — fetch origin, merge `origin/main`, merge
`origin/<current-branch>`, resolve conflicts, run the repo's pre-commit checks
(render / lint / spell), then push — applies unchanged.

Keep the logic only in `sync-pr-branch`; this file is just the `/sync` entry
point so the names stay in sync.
