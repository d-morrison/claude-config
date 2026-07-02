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

**Re-check `main` again right before the final push, not just at the start of
a merge.** Resolving a conflict (rerunning generators, fixing prose, updating
a CHANGELOG entry) can take long enough for `main` to advance a second time.
A `git fetch origin main` immediately before `git push` --- after conflict
resolution is done, not only before it started --- catches that case; an
earlier CI failure on a commit you thought was current is a symptom of
skipping this second check.

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

**A CI failure on a brand-new PR's very first commit (e.g. the empty
claim-commit from `pr-on-claim`) is a signal to check `main`'s position
before debugging the failure itself.** A local checkout that sat around since
before the session started can already be many commits behind `main` --- the
failure (a stale generated-tree check, a check `main` has since added or
dropped) often isn't a real problem with your change at all, just `main`
having moved. `git fetch origin main && git log --oneline ..origin/main`
first; if `main` is ahead, merge it in and re-run the checks before treating
the failure as something to fix in the diff. (`stack-prs` #359: an
empty-commit draft PR failed `validate` on a stale `codex-skills/` generated
tree, and the `require-changelog` job on a newly-added `CHANGELOG.md`
requirement from PR #354 --- both were `main` having advanced past a
checkout that predated the session, not a defect in the new skill.)

**A textual conflict in a skill file can be the symptom of a conceptual
duplicate, not just competing edits to the same line.** When merging `main`
into a branch that's authoring a new skill, if the conflict lands in a
`## Relationship to other skills` section (or `main` added an entirely new
skill in the same territory), that's a signal to re-run `skill-builder`'s
Step 0 judgment --- not just resolve the diff mechanically. Compare the new
skill against whatever landed on `main`: are they the same concern (fold
into one, redirect), or genuinely distinct (cross-link both directions so
neither reads as an unexplained near-duplicate)? `skill-builder`'s
in-flight-work scan only runs once, at the start; `main` can grow a
colliding skill in the time a PR is open, so the check has to be repeated
at merge time too. (PR #352's `check-info-quality` landed alongside `#344`'s
independently-authored `fact-check-prose` this way --- distinct enough to
keep both, resolved by adding an explicit boundary in each skill's
Relationship section rather than consolidating.)
