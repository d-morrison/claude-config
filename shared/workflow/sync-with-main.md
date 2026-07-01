Whenever `main` has moved ahead of a PR branch you're working on, **merge
`main` into the PR branch** before the next push or review trigger. Don't wait
for a conflict to surface or for someone to ask.

**Always check for merge conflicts with main before pushing results to remote.**
Run this before every push, not just before triggering a review:

```bash
git fetch origin main
git log --oneline ..origin/main | head    # any commits? main is ahead --- merge it in
git merge origin/main
```

If the push is rejected because `main` has moved (`! [rejected]` with
`(fetch first)` or `(non-fast-forward)`), fetch and merge before retrying --- don't
force-push.

Always do this before triggering a fresh review too, so the reviewer evaluates
the PR against current `main` rather than a stale snapshot.

Don't rebase or squash-rewrite a published PR branch unless explicitly asked ---
a merge commit is the right move because it matches GitHub's "Update branch"
button and preserves the PR history.

If the merge has conflicts, resolve them, run the project's standard pre-commit
checks (render / lint / spell / tests), commit, then push. Don't push a
half-resolved merge.

**After merging main, re-check version parity.** In R packages with a
`version-check` CI job, the branch's `DESCRIPTION` `Version:` must *exceed*
main's. A conflict-free merge can silently put them at parity — main advanced
(e.g. another PR merged between when you last bumped and now). After every merge
of main, compare versions:

```bash
git show origin/main:DESCRIPTION | grep ^Version
grep ^Version DESCRIPTION
```

If they match, bump the branch's `Version:` by one patch level before pushing.

**A conflict-free merge does not mean derived artifacts are in sync.** If your
branch regenerates a generated tree (e.g. `codex-skills/`, a lockfile, rendered
docs) and `main` added a new *source* input the generator consumes (a new
skill, a new dependency), git merges both cleanly --- but the generator never
ran against the new input on your branch, so its output is missing or stale and
the sync check fails on `main` after both land. After merging `main`, re-run the
generator and commit the result whenever main touched the generator's inputs ---
don't trust the absence of conflicts. (Concretely: merge the PR that adds the
new skill *first*, then sync the wrapper-regenerating branch and rerun
`scripts/sync-codex-skill-wrappers.py` before merging it.)
