---
name: deconflict-sessions
description: "Alias for `session-lock`. Deconflict multiple AI agent sessions working the same local repo checkout — a machine-local registry (under .git/) so parallel sessions see each other, avoid clobbering the same working tree/branch, isolate into a git worktree, and recover after a crash. Use when asked to 'deconflict sessions', 'deconflict multiple ai sessions', 'avoid stepping on another local session', or 'lock the worktree'. The LOCAL counterpart to claim-pr."
user-invocable: true
---

# deconflict-sessions (alias for `session-lock`)

This is a descriptive alias for the **session-lock** skill — deconflicting
multiple AI sessions operating locally on the same repo. Read and follow the
canonical skill:

→ **`~/.claude/skills/session-lock/SKILL.md`**
