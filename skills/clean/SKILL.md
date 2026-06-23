---
name: clean
description: "Alias for `ardi` (\"drive to clean\"). ARD + Iterate on a single PR/MR until the review verdict is clean: read the latest review, Address/Rebut/Defer every finding, push, re-request review, repeat until zero findings. Use when asked to 'clean', 'clean this PR', 'drive to clean', or 'make this PR clean'. Not for git-branch, worktree, or code cleanup — see `clean-branches` (`cb`), `clean-worktrees` (`cw`), and `tidy` / `simplify`."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# clean — "drive to clean" (alias for `ardi`)

This is a mnemonic alias for the **ardi** skill — drive a PR/MR to a *clean*
review verdict. Read and follow the canonical skill:

→ **`~/.claude/skills/ardi/SKILL.md`**

Don't confuse this with the other "clean" skills: `clean-branches` (`cb`) prunes
git branches, `clean-worktrees` (`cw`) prunes git worktrees, and `tidy` /
`simplify` clean up code. This alias is only about driving a PR/MR review to a
clean verdict.
