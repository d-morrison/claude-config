---
name: stack-prs
description: "Branch new work off an existing, unmerged PR instead of `main`, open the dependent PR with its `base` set to that PR's branch, and keep it in sync as the base branch moves (or re-point it to `main` once the base merges). Use when asked to 'stack this PR on #N', 'branch off that PR', 'stack-prs', or whenever new work genuinely depends on an open, unmerged PR's code."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# stack-prs

Create (or maintain) a PR that is **stacked** on another open, unmerged PR:
its branch starts from the base PR's tip instead of `main`, and its own PR's
`base` points at the base PR's branch instead of `main`. This is the
general-purpose entry point for stacking — other skills (`ardia`, `gii`/`gia`,
`stack-dont-pause`) each stack as a side effect of their own loop; this one
does it directly when you already know you want to branch off another PR.

## When this fires

- "stack this on #N", "stack-prs", "branch off that PR", "make this depend on
  PR #N".
- New work genuinely needs another open PR's code, or would conflict with it
  if branched from `main` in parallel.

It does **not** fire when the work is independent of every open PR — branch
from `main` as usual. Don't stack just because two PRs happen to be open at
the same time.

## When to stack vs. branch from `main`

Stack only when the new work **depends** on the base PR:

- It needs code the base PR adds that isn't on `main` yet.
- It would otherwise touch the same files as the base PR, guaranteeing a
  conflict if developed in parallel from `main`.

Branch from `main` when the two are merely concurrent but independent — that
is the default, and stacking should not be reached for out of caution. See
[`stack-dont-pause`](../../shared/workflow/stack-dont-pause.md) for the same
decision made inline inside a sweep loop.

## Procedure

### 1. Create the dependent branch off the base PR's tip

```bash
git fetch origin <base-branch>
git checkout -b <dependent-branch> "origin/<base-branch>"
```

Use the base PR's `headRefName` (`gh pr view <base-N> --json headRefName -q
.headRefName`, or `mcp__github__pull_request_read` method `get` in a remote
session) as `<base-branch>` — never guess the branch name from the PR title.

### 2. Open the dependent PR with `base` set to the base branch

```bash
gh pr create --base <base-branch> --title "<title>" --body "Stacked on #<base-N> --- merge that first.

<description>"
```

In a remote/web session without `gh`, use `mcp__github__create_pull_request`
with `base: "<base-branch>"`. Note the dependency explicitly in the body
(`Stacked on #<base-N>`) so anyone scanning the PR list — including `ardia`'s
stacked-PR detection — sees the relationship without cross-referencing
branches.

If the dependent work is being opened up front per
[`pr-on-claim`](../../shared/workflow/pr-on-claim.md), open it as a draft from
an empty commit exactly as that skill describes, just with `--base
<base-branch>` instead of `main`.

### 3. Keep the dependent branch in sync as the base branch moves

Whenever the base PR gets new commits (a review fix, a rebase, `main` merged
into it), merge that movement into the dependent branch before the next push
or review trigger — the same standing rule
[`sync-with-main`](../../shared/workflow/sync-with-main.md) applies to `main`,
here applied to the base branch instead:

```bash
git fetch origin <base-branch>
git merge "origin/<base-branch>"
```

Resolve any conflicts (see [`resolve-conflicts`](../resolve-conflicts/SKILL.md)),
run the repo's pre-commit checks, then push. Do this before every push and
before every fresh review request, exactly as `sync-pr-branch` does for `main`.

### 4. When the base PR merges, re-point the dependent PR at `main`

Once the base branch's commits land on `main` (the base PR merges), the
dependent PR no longer needs to target the base branch — retarget it so it
merges normally and the stacking note stops being misleading:

```bash
git fetch origin main
git merge origin/main          # picks up the now-merged base commits via main
gh pr edit <dependent-N> --base main
```

In a remote/web session, use `mcp__github__update_pull_request` with `base:
"main"`. After retargeting, GitHub recomputes the diff against `main` — it
should now show only the dependent PR's own changes, since the base PR's
commits are already on `main`. If it doesn't (the merge above was a no-op or
missed something), re-check before proceeding. Update the PR body to drop the
`Stacked on #<base-N>` note once this step is done.

### 5. If the base PR is abandoned or closed unmerged

Re-target the dependent branch onto `main` directly and rebase/merge to drop
the base PR's unmerged commits from the dependent branch's history — don't
leave a PR silently based on a branch that will never land. Surface this to
the user before rewriting history on a published branch.

## Relationship to other skills

- **`ardia`** — detects stacked PRs via `baseRefName` and sequences them (base
  before derived) as part of sweeping the whole open-PR queue. This skill is
  the direct, single-PR counterpart: use it when you already know you want to
  stack, rather than letting a sweep discover the relationship.
- **`stack-dont-pause`** (`shared/workflow/stack-dont-pause.md`) — the rule
  that a clean-but-unmerged PR is not a reason to pause a sweep; stack new,
  dependent work on it instead of waiting. This skill is the mechanics that
  rule points to.
- **`sync-pr-branch`** / **`merge-main`** — the analogous "keep in sync"
  procedure for a branch and `main`. Step 3 here is that same procedure
  applied to a moving base branch instead of `main`.
- **`resolve-conflicts`** (`rc`) — used in step 3 when the base branch's
  movement conflicts with the dependent branch.
- **`pr-on-claim`** — step 2's draft-PR-up-front pattern, adapted to target
  the base branch instead of `main`.
- **`gii`** / **`gia`** — stack issues' PRs on a prior unmerged issue's branch
  as part of their serial loop (issue #123); this skill is the reusable
  primitive they could each call instead of reimplementing the mechanics.

## Anti-patterns

- ❌ Guessing the base PR's branch name from its title instead of reading
  `headRefName` — a mismatch silently branches from the wrong ref.
- ❌ Stacking two PRs that are merely concurrent but not actually dependent —
  branch from `main` instead; stacking adds a real ordering constraint.
- ❌ Letting the dependent branch drift after the base branch gets new commits
  — sync it before every push, not just once at creation.
- ❌ Leaving the dependent PR targeting the base branch after the base PR
  merges — retarget to `main` (step 4) so the diff and merge behave normally.
- ❌ Force-pushing or rebasing a published dependent branch without telling
  the user, even when the base PR was abandoned (step 5).
