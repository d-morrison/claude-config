When an agent claims an issue it's about to work — in `gi`, `gii`, `gip`, or
`st` — open the PR **immediately**, before writing any code, and keep it a
**draft** until the implementation lands. Don't wait until the work is done to
open it.

**Why up front.** The claim comment on the issue is easy to miss, and it isn't
what other sessions check. The authoritative in-flight signal is the issue's
cross-referenced **open PRs** — the check `gi` runs before grabbing an issue.
Until a PR exists, a parallel issues-sweep can grab the same issue and build a
duplicate. An open PR closes that window: it shows in `gh pr list` and the
issue's timeline, and links the issue via `Closes #N`. An open PR is the
clearest "someone is working this" signal there is — stronger than a comment.
This is the strong form of the "open and link the PR promptly" note in
[`claim-pr`](claim-pr.md).

**Mechanics.** Branch, then open the PR against an empty commit:

```bash
git fetch origin main -q
git checkout -b <type>/<slug> origin/main
git commit --allow-empty -m "start: <issue title> (closes #<N>)"
git push -u origin HEAD
gh pr create --draft --title "<title>" --body "Closes #<N>

WIP — opened up front to claim the issue; implementing now."
```

The empty commit gives the branch a diff so the PR can open with no code yet.
In a remote/web session where `gh` is absent, push the empty commit and open
the PR with the GitHub MCP tools instead (`mcp__github__create_pull_request`
with `draft: true`).

**Draft, not ready-for-review — deliberately.** A draft doesn't trigger the
`@claude` review bot, so no review round is spent on an empty or half-finished
diff. Implement on top, pushing commits to the same PR; when the change is
complete and the repo's checks pass, mark the PR **ready for review**
(`gh pr ready <N>`, or `mcp__github__update_pull_request` with `draft: false`).
Marking it ready is what kicks off ARDI.

So the per-issue order becomes: claim → branch → **open the draft PR now** →
implement → mark ready-for-review → ARDI.
