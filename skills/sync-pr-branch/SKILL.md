---
name: sync-pr-branch
description: Sync the current branch with both `main` and its own remote — fetch origin, merge origin/main into the branch, merge origin/<current-branch> into local (reconciling commits pushed elsewhere, e.g. by the @claude bot or another machine), then resolve conflicts, run the repo's pre-commit checks, and push. Use before triggering a review or pushing fixes, on "sync", "update the branch", "merge main in", "resync the branch", "reconcile local and remote", "the branch is behind main", or whenever main or the remote branch has moved ahead.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# sync-pr-branch

Keep a PR branch current with **both** `main` and **its own remote**, so
reviewers (human and the `@claude` bot) evaluate it against today's `main`, and
so commits that reached the remote from elsewhere (the `@claude` CI bot,
another machine, a teammate, GitHub's web editor) are merged in rather than
causing a rejected `git push`. The standing rule: whenever `main` *or* the
remote branch has moved, **merge it in** — don't wait for a conflict to surface
or for the user to ask.

Synonyms: `sync`, `resync-branch`, `merge-main` — all route here.

## When this fires

- Before pushing fixes to a PR branch, or before triggering a fresh review.
- "sync", "sync the branch", "resync the branch", "update the branch", "merge
  main in", "sync with main", "reconcile local and remote", "my branch and
  origin have diverged", "the branch is behind main", "resolve the conflicts
  with main".
- Any time you notice `main` is ahead of the branch, or suspect the remote copy
  of the branch has moved ahead of (or sideways from) your local copy — e.g.
  the `@claude` bot pushed a commit, or you worked on this branch from two
  machines.

## The procedure

1. **Fetch everything from origin** (gets both `origin/main` and the
   remote-tracking copy of the current branch in one shot):
   ```bash
   git fetch origin
   BR="$(git branch --show-current)"
   ```
   If `BR` is empty (detached HEAD) or `main`/`master`, stop and tell the user
   — this skill is for a feature/PR branch, not `main` itself.

2. **Merge `origin/main` into the branch.** A merge commit (not a rebase)
   matches GitHub's "Update branch" button and preserves PR history. **Never**
   rebase or squash-rewrite a *published* branch unless the user explicitly
   asks.
   ```bash
   git merge origin/main
   ```

3. **Merge `origin/<current-branch>` into local** — reconcile any commits that
   reached the remote from elsewhere:
   ```bash
   git merge "origin/$BR"
   ```
   "Already up to date" just means local was already ahead of or equal to the
   remote — fine, carry on.

4. **(As you see fit) re-merge `origin/main`.** If step 3 pulled in new
   commits, those may predate the `main` you merged in step 2. When that's the
   case, merge `main` once more so the final tree is current with both inputs:
   ```bash
   git merge origin/main
   ```
   Skip this when step 3 was a no-op — it would just be an empty merge.

5. **Resolve any conflicts fully** in the working tree (from any of steps 2–4)
   — consolidate the best of both sides, don't blind-pick `--ours`/`--theirs`.
   See the `resolve-conflicts` skill (alias `rc`) for the how-to. Don't push a
   half-resolved merge.

6. **Run the repo's pre-commit checks before committing a conflict
   resolution.** Run whatever the current repo's checks are — build, lint,
   test, spellcheck — and only proceed once they pass. If the repo ships
   `render` / `lint` / `spell` / `test` skills, use them. A clean,
   conflict-free merge auto-commits and needs no extra commit.

   <details><summary>Example: an R + Quarto package (e.g. <code>rme</code>)</summary>

   ```bash
   quarto render <chapter.qmd> --to html      # each parent chapter touched by the merge
   Rscript -e 'lintr::lint("path/to/file")'   # each changed .R / .qmd
   Rscript -e 'spelling::spell_check_package()'
   ```
   (Or use that repo's `quarto-preflight` / `render` / `lint` / `spell` skills.)
   </details>

7. **Push the branch back to origin:**
   ```bash
   git push origin HEAD
   ```
   Because step 3 already merged the remote tip, this is a fast-forward of the
   remote and won't be rejected. If it *is* rejected, the remote moved again
   between fetch and push — re-run from step 1.

## Notes

- If everything is already up to date (steps 2–4 all no-ops, clean tree), say
  so and stop — nothing to push.
- Order matters only loosely: merging `origin/main` first (step 2) then the
  remote branch (step 3) is the canonical flow, but the reverse converges to
  the same tree. Optional step 4 papers over whichever you did first.
- This skill is the sync-with-main step of an `ardi` round (step 4). When
  iterating, run it before each review trigger.
- Only merge **`origin/main`** and **`origin/<this branch>`** — never another
  open PR's branch. Cross-PR changes belong in their own branch.
