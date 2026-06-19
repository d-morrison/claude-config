---
name: prune
description: "Alias for `clean-branches` (aka `cb`). Audit branches in the current repo — both LOCAL and REMOTE — deleting dead ones, rebasing stale-but-alive ones onto main, and opening MRs for orphaned work, without disrupting active sessions. Use when asked to 'prune', 'prune branches', 'clean branches', or 'tidy up branches'."
user-invocable: true
---

# prune (alias for `clean-branches`)

This is a mnemonic alias for the **clean-branches** skill — it prunes dead and
stale branches in **both your local checkout and the remote**. Read and follow
the canonical skill:

→ **`~/.claude/skills/clean-branches/SKILL.md`**
