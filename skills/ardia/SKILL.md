---
name: ardia
description: "ARD + Iterate-All: apply ARDI (ARD + iterate) to every open PR/MR in the repo. Drive each one to a clean review verdict in turn. Use when asked to 'ardia', 'iterate all PRs', 'drive all MRs to clean', or to run the ARD-iterate loop across the whole open-PR queue."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ARDIA — ARD + Iterate-All

Apply the ARDI loop (ARD + iterate) to every open PR/MR in the repo, driving
each to a clean review verdict in series.

## Procedure

1. **List open PRs/MRs.** Use `gh pr list` or `glab mr list` as appropriate.

2. **For each PR/MR, run ARDI:**
   - Read the latest review.
   - ARD every finding (Address / Rebut / Defer).
   - Push fixes (if any), post summary, re-request review.
   - If no code was pushed (all Rebut/Defer), still explicitly re-request
     review — the push won't auto-trigger it.
   - Repeat until clean.
   - Move to the next PR/MR.

3. **Report a summary table** at the end:

   | MR/PR | Rounds | Final status |
   |-------|--------|--------------|
   | [#25](url) | 3 | ✅ Clean |
   | [#26](url) | 1 | ✅ Clean |

## Rules

- Process PRs in series (don't interleave).
- Per-PR rules from ARDI apply (sync main, claim, ARD every item, etc.).
- Asymptotic-noise guard: if any single PR doesn't converge after 3–4 rounds,
  surface it to the user and move on to the next.

## On completion

Report the table with clickable links to each MR/PR. Don't merge unless asked.
