---
name: clean-branches
description: "Clean Branches: audit branches in the current repo — both LOCAL and REMOTE — delete dead ones (purely behind main, no open MR/issue), rebase stale-but-alive ones onto main, and open MRs for orphaned work. Also prunes local-only stragglers: branches already merged into main, and tracking branches whose remote is gone. Checks for active sessions before touching anything. Use when asked to 'clean branches', 'cb', 'prune', 'prune branches', 'tidy up branches', or 'clear dead branches'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# Clean Branches (aka CB / prune)

Audit branches in the current repo — **both your local checkout and the
remote**. Delete dead ones, rebase stale ones, open MRs for orphaned work, and
sweep up local-only stragglers — all without disrupting active sessions.

## When this fires

- User says "clean branches", "cb", "prune", "prune branches", "tidy up branches"
- User says "clear dead branches", "clean up the repo"
- User says "what branches can we delete?"

## Scope: local AND remote

Prune in both places — they accumulate junk independently:

- **Remote** branches — dead/stale/orphaned remote refs (the bulk of this skill).
- **Local** branches — branches that linger in your checkout after their PR
  merged, or whose upstream remote was deleted (`[gone]`). The remote pass
  alone won't catch a local branch whose remote is already gone, so there's a
  dedicated local pass (step 8).

## Definitions

| Category | Criteria | Action |
|----------|----------|--------|
| **Dead** | Purely behind main (no unique commits ahead), no open MR, no linked issue, not created in the last 7 days | Delete |
| **Stale** | Has unique commits ahead of main but is behind main, no recent activity (>30 days), not actively being worked on | Rebase on main, open MR if none exists |
| **Active** | Has an open MR, linked issue, recent commits (<30 days), or a claim comment | Skip — don't touch |
| **New** | Created in the last 7 days | Skip — too fresh to judge |
| **Local merged** | *Local* branch fully merged into main, or whose PR merged (upstream `[gone]`) | Delete locally (`git branch -d`) — step 8 |
| **Local-only unpushed** | *Local* branch with unique commits, never pushed, no MR | Flag — ask before touching (step 8) |

The first four rows apply to **remote** branches (steps 1–7); the last two are
the **local** pass (step 8). A branch can need both — e.g. delete the remote ref
*and* the leftover local tracking branch.

## Procedure

### 1. Detect the forge

```bash
git remote get-url origin
```

Determine GitHub (`gh`) vs GitLab (`glab`).

### 2. Fetch and list remote branches

```bash
git fetch --prune origin
git branch -r --merged origin/main | grep -v 'origin/main\|origin/HEAD'
git branch -r --no-merged origin/main
```

### 3. Classify each branch

For each remote branch (excluding `main`, `HEAD`, protected branches):

#### a. Check if it's purely behind main (merged/dead)

```bash
# Commits on branch not on main (ahead count)
git rev-list --count origin/main..origin/<branch>

# If 0 → branch is purely behind main (already merged or never diverged)
```

#### b. Check recency

```bash
git log -1 --format='%ci' origin/<branch>
```

Skip if created/last-committed within the last 7 days (too new).

#### c. Check for open MR/PR

```bash
# GitLab
glab mr list --source-branch=<branch> 2>&1 | cat

# GitHub
gh pr list --head=<branch> --json number,title,state | cat
```

If an open MR exists → **Active**, skip.

#### d. Check for linked issues

Look for branch naming patterns that reference issues:
- `fix/123-*`, `feat/123-*`, `issue-123-*` → check if issue #123 is open
- If the linked issue is open → **Active**, skip

#### e. Check for active work claims

```bash
# Look for recent "working on this" / claim comments on any linked MR/issue
```

If a claim comment exists within the last 24 hours → **Active**, skip.

### 4. Present the plan (dry run)

Before taking any action, present a table to the user:

```
## Branch Cleanup Plan

| Branch | Last commit | Status | Action |
|--------|-------------|--------|--------|
| `old-feature` | 2025-03-15 | Dead (merged) | 🗑️ Delete |
| `wip-refactor` | 2025-11-20 | Stale (45 days, no MR) | 🔄 Rebase + open MR |
| `fix/42-typo` | 2026-06-15 | Active (open MR !80) | ⏭️ Skip |
| `experiment` | 2026-06-12 | New (<7 days) | ⏭️ Skip |

Proceed? (or pick specific branches to act on)
```

Wait for user confirmation before proceeding. If user says "just go" or
"do it", proceed with all proposed actions.

### 5. Delete dead branches

```bash
git push origin --delete <branch>
```

Also clean up local tracking branches:
```bash
git branch -d <local-tracking-branch>  # if it exists locally
```

### 6. Rebase stale branches

For each stale branch:

```bash
git checkout -B <branch> origin/<branch>   # -B (not -b) force-resets if the branch already exists locally
git rebase origin/main
```

If rebase has conflicts:
- Attempt to resolve automatically
- If conflicts are non-trivial, skip this branch and report it
- Don't force-push a broken rebase

If rebase succeeds:
```bash
git push --force-with-lease origin <branch>
```

### 7. Open MRs for orphaned stale branches

For stale branches that have no open MR after rebasing:

```bash
# GitLab — assign to the current glab user (override ASSIGNEE to assign someone else)
ASSIGNEE="$(glab api user 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['username'])")"
glab mr create --source-branch=<branch> --target-branch=main \
  --title "<inferred title from branch name>" \
  --description "Orphaned branch rebased onto main. Review or close if no longer needed." \
  ${ASSIGNEE:+--assignee "$ASSIGNEE"}

# GitHub
gh pr create --head=<branch> --base=main \
  --title "<inferred title>" \
  --body "Orphaned branch rebased onto main. Review or close if no longer needed."
```

### 8. Prune local branches

The remote pass doesn't touch branches that only exist in your checkout. Sweep
those too. First refresh remote-tracking state so "merged" and "gone" are
accurate:

```bash
git fetch --prune origin                       # marks deleted upstreams as [gone]
git branch --show-current                      # never delete the branch you're on
```

Classify each **local** branch (excluding `main`/`master`/protected and the
current branch):

#### a. Merged into main → delete

```bash
git branch --merged origin/main | grep -vE '^\s*\*|\bmain\b|\bmaster\b'
# Word-anchored so a branch like `maintain-docs` isn't silently filtered out.
# Compare against origin/main (just fetched), NOT local `main` — your local main
# may be behind, which would hide branches that are actually merged.
git branch -d <branch>          # -d refuses if NOT actually merged — a safety net
```

`-d` (never `-D`) is deliberate: if git refuses, the branch has unmerged
commits — treat it as **stale**, not dead (see b).

#### b. Upstream gone but the PR merged → delete

A branch whose remote was deleted shows `[gone]`:

```bash
git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads \
  | grep '\[gone\]'
```

For each, confirm the PR/MR actually merged before deleting (never assume):

```bash
# GitHub
gh pr list --head <branch> --state merged --json number,mergedAt | cat

# GitLab
glab mr list --source-branch=<branch> --state merged 2>&1 | cat
```

- PR merged → `git branch -D <branch>` is acceptable here (the work landed via
  squash/rebase merge, so `-d` may not see it as merged). Confirm the merge
  first.
- No merged PR and unique commits exist → **stale local work**: don't delete;
  offer to push it and open an MR (step 7 mechanics).

#### c. Never pushed, has unique commits → keep, but flag

```bash
git for-each-ref --format='%(refname:short) %(upstream)' refs/heads \
  | awk '$2=="" {print $1}'      # local branches with no upstream at all
```

Report these as "local-only, unpushed" and ask before doing anything — they may
be in-progress work that hasn't been pushed yet. Don't delete without
confirmation.

Apply the same dry-run discipline to local deletions as step 4 does for remote
branches — **no silent local deletions**. If you're doing a full local+remote
sweep, fold these local rows into the step-4 plan and present them together; if
you're running the local pass on its own, present a standalone local plan here
and wait for confirmation before deleting anything.

### 9. Report

Print a summary covering **both** local and remote:

```
## Branch Cleanup Complete — <timestamp>

### Deleted — remote (dead)
- `old-feature` (last commit 2025-03-15, merged into main)

### Deleted — local (merged / upstream gone)
- `add-wrap-up-skill` (PR #26 merged; local straggler)
- `ums-session-learnings` (merged into main)

### Rebased + MR opened (stale)
- `wip-refactor` → [!85](url) (rebased, 3 commits ahead)

### Skipped (active/new)
- `fix/42-typo` — open MR !80
- `experiment` — created 2 days ago

### Flagged — local-only, unpushed (left alone)
- `scratch-idea` — 4 unpushed commits, no MR; your call

### Failed (conflicts)
- `ancient-branch` — rebase conflicts, needs manual resolution
```

## Safety rules

- **Never delete `main`, `master`, `develop`, or any protected branch.**
- **Never force-push to a branch with an open MR** without rebasing cleanly.
- **Always present the plan first** — no silent deletions.
- **Check for active work** before touching any branch.
- **Preserve local branches** the user is currently on (`git branch --show-current`).
- **Don't delete branches newer than 7 days** — they might be in-progress work
  that just hasn't gotten an MR yet.
- **Prefer `git branch -d` over `-D`** for local deletions — `-d` refuses unless
  the branch is merged, which catches "I thought this landed but it didn't."
  Only use `-D` after confirming the PR merged (squash/rebase merges can leave a
  local branch that `-d` won't recognize as merged).
- **Never delete a local-only unpushed branch without confirmation** — if it has
  unique commits and no remote, that work exists nowhere else.

## Relationship to other skills

- **`sync-pr-branch`** — used internally when rebasing stale branches
- **`claim-pr`** — checked to avoid touching claimed branches
- **`ardi`** — user may want to ARDI the newly opened MRs afterward

## Anti-patterns

- ❌ Deleting branches without checking for open MRs/issues first
- ❌ Force-pushing a broken rebase
- ❌ Touching branches that someone is actively working on
- ❌ Deleting branches without user confirmation
- ❌ Rebasing branches that have open MRs (use merge instead, or skip)
