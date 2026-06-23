---
name: prune-worktrees
description: "Alias for `clean-worktrees` (aka `cw`). Sweep dead git worktrees in the current repo — prune admin stubs for already-deleted dirs, then remove linked worktrees whose branch merged (or is gone) and whose tree is clean, never touching the main/current worktree, a dirty tree, or one with a live session. Use when asked to 'prune worktrees', 'prune-worktrees', 'clean worktrees', or 'clean dead worktrees'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# prune-worktrees (alias for `clean-worktrees`)

This is a spelled-out alias for the **clean-worktrees** skill. The name echoes
the familiar `git worktree prune`, but the skill does **more** than that
stub-only command: it removes whole dead worktrees and their branches (a `git
worktree prune` is just step 2 of the sweep). Read and follow the canonical
skill:

→ **`~/.claude/skills/clean-worktrees/SKILL.md`**
