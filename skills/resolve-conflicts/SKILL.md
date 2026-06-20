---
name: resolve-conflicts
description: "Resolve git merge/rebase/cherry-pick conflicts by consolidating the best of BOTH branches — understand why each side changed the hunk, then reconstruct a resolution that preserves both intents instead of blindly picking `--ours`/`--theirs`. Remove the markers, run the repo's pre-commit checks, stage, and finish the operation. Use when a merge / rebase / cherry-pick / stash pop / pull reports conflicts, or when asked to 'resolve conflicts', 'resolve the merge conflicts', 'fix the conflicts', 'I have a merge conflict', 'consolidate the best of both branches', or 'help me merge these branches'. Delegated to from `sync-pr-branch` step 5, `clean-branches`, and `gii`. (For multiple AI *sessions* clobbering one local checkout, that's `deconflict-sessions` / `session-lock`, not this.)"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# resolve-conflicts — consolidate the best of both branches

A merge conflict means **both** branches edited the same region — and each side
changed it for a reason. The right resolution almost always keeps the *intent*
of **both** sides. The default failure mode is to grab one side wholesale
(`--ours` / `--theirs`) and silently throw the other branch's work on the
floor. Don't. **Consolidate, don't choose.**

## When this fires

- Any git operation stops on a conflict: `git merge`, `git rebase`,
  `git cherry-pick`, `git stash pop`, `git pull`, `git revert`. The tell is
  `CONFLICT (content): Merge conflict in …` and `Unmerged paths:` in
  `git status`.
- "resolve the conflicts", "fix the merge conflicts", "I have a merge
  conflict", "consolidate the best of both branches", "help me merge these
  branches", "the branch won't merge cleanly".
- **Delegated from another skill**: `sync-pr-branch` step 5 ("resolve any
  conflicts fully"), `clean-branches`' rebase-onto-main step, or a stacked
  `gii` MR. When one of those stops on a conflict, run this.

## Core principle: consolidate the best of both branches

Each conflict hunk has three inputs — the common **base**, **our** side, and
**their** side. Picking a winner is right only when one side's change is
genuinely the *same* edit, or strictly subsumes the other. Otherwise the merge
should contain a **synthesis** that honors both:

- Two different features touching neighbouring lines → keep **both** edits.
- A refactor on one side + a bugfix on the other → apply the bugfix *to the
  refactored code*.
- A rename on one side + an edit to the old name on the other → carry the edit
  onto the new name.

If you can't see why a side changed the hunk, you're not ready to resolve it —
go read the history first (step 2).

## Procedure

1. **Survey the battlefield.** Know which operation you're in (the semantics of
   "ours"/"theirs" depend on it — see the warning below) and list the
   conflicted files:
   ```bash
   git status                                   # header names the operation
   git diff --name-only --diff-filter=U         # just the unmerged paths
   ```

2. **Understand BOTH sides before editing a single hunk.** For each conflicted
   file, look at the three-way picture and *why* each side diverged:
   ```bash
   git log --merge --oneline -- <file>   # commits from both sides touching it
   git show :1:<file>                    # BASE (common ancestor)
   git show :2:<file>                    # OURS  (HEAD / current side)
   git show :3:<file>                    # THEIRS (incoming side)
   ```
   Ask: what problem was each side solving? Different features? One refactor +
   one fix? A move/rename vs an in-place edit? The answer dictates the merge.

3. **Consolidate.** Edit the working file into a version that keeps the valuable
   change from **both** sides, then delete every conflict marker
   (`<<<<<<<`, `=======`, `>>>>>>>`). Take one side wholesale only when you've
   confirmed the other side has nothing worth keeping — and note that you did.

4. **Prove no markers (or whitespace damage) slipped through:**
   ```bash
   git diff --check                      # flags leftover markers + whitespace errors
   grep -rn '^<<<<<<<\|^=======$\|^>>>>>>>' . --exclude-dir=.git   # belt and suspenders
   ```

5. **Run the repo's pre-commit checks before committing the resolution.** A
   merge where each side compiled *separately* can still break *combined*.
   Build / lint / test / spellcheck per the current repo (use its `render` /
   `lint` / `spell` / `test` skills if it ships them). Don't commit a
   resolution that fails checks.

6. **Stage the resolved files, then finish the operation** — never `--abort` or
   `--skip` away a conflict you were asked to resolve:
   ```bash
   git add <file> …
   git commit                 # for a merge (message is prefilled)
   git rebase --continue      # for a rebase
   git cherry-pick --continue # for a cherry-pick
   ```

## ⚠️ "ours" and "theirs" flip between merge and rebase

- In a **merge** (`git merge X` on branch `B`): `ours`/`:2:` = `B` (where you
  are), `theirs`/`:3:` = `X` (being merged in).
- In a **rebase** (`git rebase X` on branch `B`): rebase replays *your* commits
  onto `X`, so `ours`/`:2:` = **`X`, the branch you're landing on**, and
  `theirs`/`:3:` = **your own commit being replayed**. The opposite of a merge.

Confirm which physical branch is "ours" before you reach for `--ours` /
`--theirs` — getting this backwards silently keeps the wrong side. (This is
*why* the skill defaults to consolidating both rather than picking a side.)

## Relationship to other skills

- **`sync-pr-branch`** (aliases `sync` / `merge-main` / `resync-branch`) — its
  step 5 says "resolve any conflicts fully"; **this** is that step's how-to.
  Run it when that sync stops on a conflict, then return to finish the sync.
- **`clean-branches`** — when rebasing a stale branch onto `main` hits a
  non-trivial conflict, resolve it here instead of skipping the branch.
- **`gii` / `split-concerns`** — stacked or parallel MRs are the usual source
  of conflicts; this is how you clear them once they collide.
- **`check-history`** — run *before* implementing to avoid creating avoidable
  conflicts/regressions in the first place; this skill cleans up the ones that
  still happen.
- **`deconflict-sessions` / `session-lock`** — **not** this skill. Those are
  about two AI *sessions* clobbering one local checkout (a locking concern),
  not git *content* conflicts. Different sense of "conflict."

## Anti-patterns

- ❌ Blind `git checkout --ours/--theirs <file>` (or `git merge -X ours/theirs`)
  without confirming the dropped side had nothing worth keeping — the classic
  silent-data-loss move.
- ❌ Resolving a hunk before understanding *why* each side changed it.
- ❌ Mixing up "ours"/"theirs" in a rebase (they're reversed vs a merge).
- ❌ Committing with conflict markers still in a file — always `git diff --check`.
- ❌ Committing the resolution without running the repo's build/lint/test checks.
- ❌ `git rebase --skip` / `git merge --abort` to dodge a conflict you were
  asked to resolve.
- ❌ Force-pushing a half-resolved merge/rebase.
