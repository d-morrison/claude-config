Whenever `main` has moved ahead of a PR branch you're working on, **merge
`main` into the PR branch** before the next push or review trigger. Don't wait
for a conflict to surface or for someone to ask.

Check before pushing:

```bash
git fetch origin main
git log --oneline ..origin/main | head    # any commits? main is ahead --- merge it in
git merge origin/main
```

Always do this before triggering a fresh review, so the reviewer evaluates the
PR against current `main` rather than a stale snapshot.

Don't rebase or squash-rewrite a published PR branch unless explicitly asked ---
a merge commit is the right move because it matches GitHub's "Update branch"
button and preserves the PR history.

If the merge has conflicts, resolve them, run the project's standard pre-commit
checks (render / lint / spell / tests), commit, then push. Don't push a
half-resolved merge.
