---
name: ph
description: "Alias for `purge-hallucinations`. Audit a target (memory/instruction corpus, repo code & docs, or an explicit file / PR diff / pasted AI output) for fabricated references that don't resolve — missing files, undefined functions, non-existent action refs/versions, dead URLs, dangling `[[memory-links]]`, fake skill names/citations/flags — then interactively propose a fix for each. Use when asked to 'ph', 'purge hallucinations', 'check for hallucinations', or 'verify the references'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ph (alias for `purge-hallucinations`)

This is a short alias. Read and follow the canonical skill:

→ **`~/.claude/skills/purge-hallucinations/SKILL.md`**
