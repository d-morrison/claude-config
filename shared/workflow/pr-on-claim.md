After claiming an issue (posting a "paws off" comment), open a **draft PR**
immediately --- before implementing. An open PR is the strongest "in-flight"
signal available: it shows in `gh pr list`, appears in the issue's
cross-referenced timeline via `Closes #N`, and is the check other sessions run
to avoid double-working the same issue. The claim comment is secondary to this
check.

## Mechanics

Right after creating the branch, make an empty commit to give the branch a
commit to open against, push, and open a draft PR:

```bash
git commit --allow-empty -m "chore: claim #<N> [skip ci]"
git push -u origin <branch>

# GitHub
gh pr create --draft \
  --title "<title>" \
  --body "Closes #<N>

Draft --- work in progress."
```

Keep it **draft** until the implementation lands. A draft PR does not trigger
the `@claude` review bot, so no review round is wasted on an empty or partial
diff.

## Converting to ready-for-review

Once the implementation is committed and pushed, mark the PR ready:

```bash
gh pr ready <N>
```

This converts the draft and triggers the `@claude` review bot, which starts
the ARDI loop.

## Cross-reference

See [`claim-pr`](claim-pr.md) for the claim comment this draft PR follows.
The `gi`, `gii`, `gip`, and `st` skills operationalize this step.
