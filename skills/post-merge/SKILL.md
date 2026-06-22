---
name: post-merge
description: "Wrap up a just-merged PR/MR: verify the merge actually landed (never assume), tidy the local branch (switch to main, pull, delete the merged branch), confirm any deferred follow-up issues are tracked, then run UMS to capture what the PR's review lifecycle taught — mistakes corrected and guidance given along the way. Use right after a PR merges, or when asked to 'post-merge', 'wrap up the merged PR', or 'clean up after the merge'. For the directive to actually perform the merge ('merge it' / 'merge this'), use the merge-it skill, which merges then chains into this one."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# post-merge — wrap up a merged PR (verify, tidy, then UMS)

The per-PR bookend to a piece of work. Once a PR/MR merges: confirm it landed,
clean up the local branch, make sure nothing was left dangling, and — the
point of the skill — **run UMS to learn from how the PR went** while the
review lifecycle is still fresh in context.

## When this fires

- A PR/MR you were working on just merged.
- "post-merge", "wrap up the merged PR", "clean up after the merge", "the PR
  merged — now what?"
- **"merge it" / "merge this" route to `merge-it`, not here** — that skill
  performs the merge first, then chains into this one. Only handle those phrases
  here when the PR is already merged (no merge left to do).
- Distinct from **`wrap-up`** (session-level, may span several PRs/issues) —
  `post-merge` is the single-PR version, run each time a PR lands.

## Procedure

### 1. Verify the merge — never assume

```bash
gh pr view <N> --json number,title,state,mergedAt,mergeCommit,headRefName
# GitLab
glab mr view <N>
```

Confirm `state == MERGED` and `mergedAt` is set. If it isn't actually merged,
**stop and report** — don't tidy a branch whose work hasn't landed. (The
standing **never assume; always verify** rule applied to closing out a PR.)

### 2. Tidy the local branch

```bash
git checkout main
git pull --ff-only origin main
git branch -d <merged-branch>     # -d, NOT -D
```

Use `git branch -d` (not `-D`): `-d` refuses to delete a branch with commits
that aren't merged. If it refuses, the branch has unmerged work — investigate
before forcing anything.

If the PR was built in a **git worktree** (agent isolation or `session-lock`),
remove the worktree as part of the tidy — a worktree pins its branch, so
`git branch -d` *refuses* while the worktree still holds it ("branch is checked
out at <path>"). Remove it first, then delete the branch:

```bash
git worktree list                 # find the merged branch's worktree path
git worktree remove <path>        # refuses on a dirty tree — don't blindly --force
git branch -d <merged-branch>     # now succeeds
```

For a repo-wide sweep of *all* dead worktrees (not just this PR's), run
`clean-worktrees` (`cw`).

If other local branches were **stacked** on this one, offer to rebase them onto
the new `main` rather than deleting silently (see `cb` / `clean-branches`).

### 3. Confirm deferred items are tracked

If the PR's review loop deferred or acknowledged anything, make sure each has a
follow-up issue (preferences: *never leave deferred items untracked*). List
them, linked. File any that slipped through.

### 4. Run UMS — learn from the PR's lifecycle

Run the full `ums` procedure (invoke the `ums` skill by name), focused on what
**this PR** taught:

- **Recurring review findings** — anything the reviewer flagged across rounds
  → encode the fix so the next PR avoids it from the start.
- **Corrections / guidance the user gave mid-PR** → preference + skill update
  (per "update BOTH skills AND preferences").
- **Tool / CI quirks** hit during the loop → `tools.md` / `debugging.md`.
- **A multi-step pattern that emerged** → consider a new skill.

This is the "learn from mistakes and guidance along the way" step — a merge is
the natural checkpoint to bank those lessons before the context is gone. If
nothing durable emerged, say so explicitly rather than manufacturing edits.
(UMS commits its own changes via a branch + PR.)

**Guard against recursion: skip this step when the merged PR was itself a
UMS/learnings PR — one whose diff is entirely memory/skill edits capturing a
previous PR's lessons — and no new lessons emerged from its own review loop.**
Re-running UMS there is redundant — the lessons are already encoded in the PR
that just merged — and spawns an endless UMS-on-UMS chain (each UMS PR merges →
triggers post-merge → triggers another UMS PR). Still do steps 1–3 and 5; just don't
manufacture a fresh UMS PR. (If the UMS PR's *own* review surfaced a genuinely
new, separate lesson, capture that — but not a restatement of what the PR
already banked. Concretely: a reviewer approving with no comments means nothing
new, so skip; a reviewer flagging a missing anti-pattern that isn't already in
the UMS diff is a new lesson worth a follow-up.)

### 5. Report

A linked summary: the merged PR, the auto-closed issue, any deferred follow-up
issues, what UMS updated, and a Pacific-time timestamp
(`TZ=America/Los_Angeles date "+%Y-%m-%d %H:%M %Z"`; the explicit `TZ` enforces
PT on a machine set to any other zone).

## Relationship to other skills

- **`wrap-up`** — session-level bookend; also embeds UMS. `post-merge` is the
  per-PR version: run it each time a PR lands; run `wrap-up` once at session
  end. They share the verify-then-UMS shape.
- **`ums`** — step 4 invokes it.
- **`cb` / `clean-branches`** — for stacked or stale sibling branches.
- **`clean-worktrees` / `cw`** — if the PR was built in a git worktree, remove
  it during the tidy (step 2); a leftover worktree pins its branch and blocks
  `git branch -d`.
- **`st` / `gi`** — the front of the lifecycle that `post-merge` closes.

## Anti-patterns

- ❌ Deleting the branch before confirming the merge actually landed.
- ❌ Reaching for `git branch -D` (force) without checking why `-d` refused.
- ❌ Skipping UMS on a normal PR — the just-merged PR is exactly when the
  lessons are freshest.
- ❌ Recursing UMS on a UMS PR — running UMS again when the just-merged PR was
  itself the learnings PR, restating lessons it already banked (see step 4's
  guard). The chain has to terminate somewhere.
- ❌ Leaving deferred/acknowledged items without follow-up issues.
- ❌ Reporting "all cleaned up" while a stacked sibling branch dangles unmentioned.
