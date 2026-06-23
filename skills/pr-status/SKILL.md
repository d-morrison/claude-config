---
name: pr-status
description: Report a PR's true review status by reading the LATEST review comment, not a cached or earlier verdict, and parse it for any remaining findings before declaring "clean" / "ready to merge". Use when asked "what's the status of PR #N", "is this PR ready to merge", or before you report any PR as mergeable. Handles the @claude bot login variants so you never false-pass on a stale or null read.
user-invocable: true
allowed-tools:
  - Bash
---

# pr-status

Report a PR's review status honestly: based on the **most recent** review, with
its findings actually parsed — never on an earlier cached "verdict." A newer
review may have landed since (from the `@claude` bot, a human, or a
re-trigger), and it may carry findings the old one missed.

## When this fires

- "what's the status of PR #N", "is #N ready to merge", "is the review clean".
- Before you state, anywhere, that a PR is mergeable / clean / ready.

## CI green ≠ review clean

`gh pr checks <N>` going green is about **CI state**, not the review verdict. A
PR can have all checks passing and still have unaddressed review findings.
Always parse the latest **review body** for findings — don't infer "clean"
from green checks.

## Read the LATEST review

```bash
gh pr view <N> --json comments \
  --jq '[.comments[] | select(.author.login | startswith("claude"))] | last | .body'
```

The reviewer's bot login **varies by API and setup**:

- `gh pr view` reports it as `claude`
- the REST API (`gh api .../comments`) reports it as `claude[bot]`
- some setups post reviews as `github-actions[bot]`

`startswith("claude")` matches the @claude bot across both `gh pr view` and
`gh api`. If your reviewer posts under a different login (e.g.
`github-actions[bot]`), **broaden the filter** — otherwise the `--jq` returns
`null` and you silently false-pass a PR with open findings. (Structured MCP
GitHub tools like `mcp__github_ci__get_ci_status` are an alternative where the
`gh` JSON parsing gets fragile.)

## Parse for findings before declaring clean

Read the full latest review body and scan for any "Findings", "Issues",
"Remaining", "Non-blocking", "Minor", "Could improve", "Consider", etc.
section. The bar for reporting **clean**: "Looks good" / "no findings" /
"approved" with **zero** follow-on bullets under any heading. A posted rebuttal
the reviewer is still disputing is **open**, not clean — a rebuttal counts only
once it convinced the reviewer (they dropped the item).

A PR is only **fully clean / ready to merge** when its review is clean *and*
all CI workflows are green *and* every inline review thread is resolved (the
only open conversation being the final all-clear and your reply to it — see
*Check thread-resolution state* below). Do **not** report "ready to merge with
one minor nit noted" / "harmless as-is" / "can address if you want" — that
hedging just pushes triage back to the user. If there are open items, report
them as open (and offer to run `ardi` to clear them).

## Check thread-resolution state

A clean review *body* isn't the whole bar — unresolved inline threads count as
open too. Count the unresolved ones via GraphQL:

```bash
gh api graphql -f query='query {
  repository(owner:"<owner>", name:"<repo>") {
    pullRequest(number:<N>) {
      reviewThreads(first:100) {
        totalCount
        nodes { isResolved }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads as $rt |
  ($rt.nodes | map(select(.isResolved | not)) | length) as $open |
  if $rt.totalCount > ($rt.nodes | length)
  then "\($open)+ open (totalCount \($rt.totalCount); cap reached — may undercount)"
  else "\($open)"
  end'
```

Interpret the output as:

- `0` — all threads resolved; clean on this dimension.
- A plain non-zero number (e.g. `3`) — that many threads are unresolved.
- A `+`-suffixed string (e.g. `0+ open (totalCount 150; cap reached — may undercount)`) — the 100-thread cap was hit. **Cannot confirm clean**, even if the visible count is 0; treat as unresolved until the cap is lifted or the PR is confirmed clean another way.

(The resolve mutation lives in the `ard` skill, step 4b.)

## Output

State, plainly: the latest review's verdict, who/what posted it, and the list
of any open findings (or "none"). If you read `null`, say the filter didn't
match a reviewer login — don't report it as clean.
