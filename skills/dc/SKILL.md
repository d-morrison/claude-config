---
name: dc
description: "Alias for `ardi` (\"drive to clean\"). ARD + Iterate on a single PR/MR until the review verdict is clean: read the latest review, Address/Rebut/Defer every finding, push, re-request review, repeat until zero findings. Use when asked to 'dc', 'drive to clean', or 'drive this PR to clean'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# dc — "drive to clean" (alias for `ardi`)

This is a mnemonic alias for the **ardi** skill — *drive to clean*. Read and
follow the canonical skill:

→ **`~/.claude/skills/ardi/SKILL.md`**
