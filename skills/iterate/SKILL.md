---
name: iterate
description: "Alias for `ardi`. Drive a single pull request to a clean review verdict by looping request-review → address every finding → re-request-review until there are zero flagged items. Use when asked to 'iterate', 'iterate until clean', 'address the review comments', '@claude review again and fix what it finds', or after opening a PR you want carried all the way to mergeable. Handles the @claude bot reviewer; for human reviewers, follows the `ard` skill's step 1 (gh pr view --comments plus the inline-thread API)."
user-invocable: true
---

# iterate (alias for `ardi`)

This is a synonym alias for the **ardi** skill (ARD + Iterate) — the per-finding
disposition is framed as Address / Rebut / Defer, but the loop is the same one
you'd reach for under "iterate until clean". Read and follow the canonical skill:

→ **[ardi](../ardi/SKILL.md)**
