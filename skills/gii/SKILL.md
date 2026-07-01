---
name: gii
description: "Grab Issues Iteratively: loop over the repo's open issues — grab the top one, implement it, open an MR/PR, ARDI it to clean, then recurse to the next issue. Stacks MRs when later issues depend on earlier (unmerged) branches. Use when asked to 'gii', 'gis', 'grab issues', 'work through the backlog', 'keep going', or 'do all the issues'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# GII — Grab Issues Iteratively (aka GIS)

Loop: grab the highest-priority open issue → implement → open MR/PR → ARDI to
clean → repeat with the next issue. Stack MRs when needed.

## When this fires

- User says "gii", "gis", "grab issues", "work through the backlog"
- User says "keep going" / "do all the issues" / "next issue"
- User says "grab issues iteratively" / "stack them up"

## Procedure

### 0. Establish context

Detect the forge (GitHub / GitLab) from `git remote get-url origin`.
Note the default branch (`main` / `master`).

### 1. Enter the loop

For each iteration:

#### a. Invoke `gi` (Grab Issue)

Run the full GI procedure:
1. List open issues, triage/prioritize
2. Present top candidates — let user pick, or auto-proceed if they said
   "just go" / "do all" / "keep going"
3. Check history
4. Claim the issue
5. Create a branch
6. Implement
7. Push and open MR/PR
8. ARDI to clean

#### b. Record the result

Track each completed issue in a running table:

| # | Issue | MR/PR | Rounds | Status |
|---|-------|-------|--------|--------|
| 1 | [#12](url) | [#30](url) | 2 | ✅ Clean |

(Examples use GitHub `#N` notation; on GitLab the MR IID is `!N`.)

#### c. Decide the next base branch (stacking)

A clean-but-unmerged MR is **not** a stopping point. Merging is human-gated
(you don't self-merge), but that gates only the merge, not the loop — keep
going to the next issue instead of pausing to wait for a human to merge first.
Stacking is what lets the loop keep moving without merges. See
[`stack-dont-pause`](../../shared/workflow/stack-dont-pause.md).

After ARDI completes clean on the current MR/PR:

- **If the MR was merged** (user said "merge" or auto-merge is on):
  base the next branch on `origin/main` (which now includes the fix).
- **If the MR is open but clean** (not yet merged):
  base the next branch on the **current MR's branch** — this creates a
  stacked MR. Note the dependency in the new MR's description:

  > ⚠️ Stacked on [#30](url) — merge that first.

  Track the stack so the final report shows the merge order.

#### d. Check stopping conditions

Stop the loop when:
- No more open issues (backlog empty)
- User interrupts or says "stop" / "that's enough"
- A configurable max is reached (default: 5 issues per session, to avoid
  unbounded runs — ask the user to continue if hit)
- An issue is blocked and no other unblocked issues remain

If stopping due to max-issues, ask:
> "Completed 5 issues — want me to keep going, or stop here?"

#### e. Recurse

Go back to step (a) with the next issue.

## Stacking rules

When stacking MRs (basing a new branch on an unmerged MR branch):

1. **Branch from the tip of the previous MR branch**, not from main:
   ```bash
   git checkout -b feat/<next-slug> <previous-mr-branch>
   ```

2. **Note the dependency** in the new MR description (use `#<N>` on GitHub,
   `!<N>` on GitLab):
   ```
   ⚠️ Stacked on #<N> (GitHub) / !<N> (GitLab) — merge that first.

   Depends on: #<N>
   ```

3. **If the base MR gets changes** (from ARDI on a later review round),
   rebase/merge the stacked MR on top of the updated base before its own
   ARDI round.

4. **Merge order** matters — report it clearly at the end.

## Final report

When the loop ends, print a summary:

```
## GII Session Summary — <timestamp>

| # | Issue | MR/PR | Rounds | Status |
|---|-------|-------|--------|--------|
| 1 | [#12](url) | [#30](url) | 2 | ✅ Clean |
| 2 | [#8](url)  | [#31](url) | 1 | ✅ Clean |
| 3 | [#15](url) | [#32](url) | 3 | ✅ Clean |

### Merge order
1. [#30](url) — fix: auth timeout
2. [#31](url) — feat: retry logic (stacked on #30)
3. [#32](url) — docs: v3 migration guide
```

## Relationship to other skills

- **`gip`** — the **parallel** counterpart: when a batch of issues is provably
  independent (no stacking dependency, no file overlap), `gip` lifts that subset
  out and works it concurrently in worktree-isolated subagents instead of
  serially. This loop stays serial for everything `gip` can't prove independent.
- **`gi`** — the inner loop; each iteration is a full GI invocation
- **`ardi`** — drives each MR/PR to clean review within GI
- **`check-history`** — invoked per-issue to avoid undoing past work
- **`split-concerns`** — if an issue's implementation grows too large, split
- **`defer-issue`** — if sub-tasks emerge, defer them (they'll be picked up
  in a later iteration of this very loop)
- **`sync-pr-branch`** — used when stacking to keep branches current

## Auto-proceed mode

If the user says "just go", "do all", "work through everything", or similar:
- Skip the per-issue confirmation ("I'd grab #12 — proceed?")
- Still pause at the max-issues checkpoint
- Still pause if an issue looks ambiguous or blocked

## Anti-patterns

- ❌ Stacking more than 3–4 MRs deep without asking (merge conflicts compound)
- ❌ Grabbing issues assigned to someone else
- ❌ Continuing after a blocked issue without telling the user
- ❌ Forgetting to note stack dependencies in MR descriptions
- ❌ Basing on main when the previous MR hasn't merged yet and the next issue
  touches the same files (creates guaranteed conflicts)
- ❌ Pausing after a clean-but-unmerged MR to wait for a human merge — you don't
  self-merge, but that's no reason to stop; keep going and stack the next issue
- ❌ Running unbounded without a checkpoint — always pause at 5
