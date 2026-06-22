---
name: pr-status-all
description: Print a table summarizing the true status of every open PR in the repo — for each one, read the LATEST review comment (not a cached verdict) and parse it for remaining findings, alongside CI state and whether the branch is behind main. Gathers the per-PR signals concurrently (one subagent per PR). Use when asked "summarize all open PRs", "status table of my PRs", "what's the state of every PR", "give me a PR dashboard", or any whole-queue status overview. For a single PR use `pr-status`; to actually drive PRs to clean use `ardia`.
user-invocable: true
allowed-tools:
  - Bash
  - Agent
---

# pr-status-all

Produce a **one-row-per-PR status table** for all open PRs. This is the
whole-queue version of [`pr-status`](../pr-status/SKILL.md): apply the same
"read the **latest** review and parse it for findings" discipline to every
open PR, then lay the results out as a table. It is **read-only** — it reports
status, it does not push, merge, or run review loops (use
[`ardia`](../ardia/SKILL.md) for that, or
[`sync-pr-branch`](../sync-pr-branch/SKILL.md) to update a branch).

Because the per-PR signals are independent and read-only, gather them
**concurrently** — one subagent per PR — then assemble the table. See
*Why fan-out is safe here* for why this loop parallelizes and the write-loops
don't.

## When this fires

- "summarize all open PRs", "status table / dashboard of my PRs",
  "what's the state of every open PR", "which PRs are ready to merge".
- Whenever you'd otherwise report on more than one PR at once.

## CI green ≠ review clean

`gh pr checks <N>` going green is about **CI state**, not the review verdict. A
PR can have every check passing and still carry unaddressed review findings.
Report CI state and review verdict as **separate columns** — never collapse
them into one "OK".

## Procedure

### 1. Enumerate the open PRs (orchestrator, one cheap call)

```bash
gh pr list --state open --json number,title,headRefName,isDraft \
  --jq '.[] | "\(.number)\t\(.headRefName)\t\(.isDraft)\t\(.title)"'
```

This is fast and sequential — a single call to get the work units.

### 2. Fan out — one subagent per PR (concurrent)

Spawn **one subagent per open PR, all in a single batch** (multiple `Agent`
calls in one message) so they run at once. The fan-out is read-only, so it
needs **no worktrees** — each subagent only reads PR signals, nothing mutates,
and there is nothing to collide on.

Give each subagent its PR number and `headRefName`, and have it gather the
**four independent signals** below and return one structured row. Carry the
disciplines into the prompt — a subagent that doesn't follow *Read the LATEST
review* will silently misreport:

A subagent starts **fresh** — it sees only this prompt, not this skill file —
so **inline the exact commands**; don't point it at a section it can't read.
Fill in `<N>`, `<headRefName>`, `<owner>`, `<repo>` for each PR (resolve
owner/repo once with `gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'`):

> Gather the status of PR **#<N>** (branch `<headRefName>`) in this repo and
> return a single structured row. Do not push, merge, or modify anything.
>
> 1. **Latest review verdict** — read the *most recent* review comment and parse
>    it for findings. Run exactly:
>    ```bash
>    gh pr view <N> --json comments \
>      --jq '[.comments[] | select(.author.login | startswith("claude"))] | last | .body'
>    ```
>    The reviewer login varies by setup: `gh pr view` reports `claude`; the
>    REST API reports `claude[bot]`. `startswith("claude")` matches both. If the
>    result is `null`, the reviewer may post as `github-actions[bot]` or another
>    login — **never report "clean"**; broaden the filter or say no review was
>    found.
>    The bar for `clean`: "Looks good" / "no findings" / "approved" with zero
>    follow-on bullets under any heading. A rebuttal the reviewer still disputes
>    is **open**, not clean.
> 2. **CI state** — `gh pr checks <N>`; name any failing/pending check, don't
>    just say "red".
> 3. **Unresolved threads** — count open inline review threads. Run exactly:
>    ```bash
>    gh api graphql -f query='query {
>      repository(owner:"<owner>", name:"<repo>") {
>        pullRequest(number:<N>) {
>          reviewThreads(first:100) { nodes { isResolved } }
>        }
>      }
>    }' --jq '[.data.repository.pullRequest.reviewThreads.nodes[]
>              | select(.isResolved | not)] | length'
>    ```
>    >0 means not fully clean even if the body says "approved".
> 4. **Behind main?** — fetch the head ref too (a fresh subagent has no local
>    branch), then compare remote-tracking refs: `git fetch origin main
>    <headRefName> -q && git rev-list --count origin/<headRefName>..origin/main`.
>    >0 means main has moved ahead.
>
> Return: PR number, CI (✅/❌-with-name/⏳), review (`clean` / `N open` with the
> headline finding / `none found` / `in-flight`), threads (`resolved` / `N
> open`), behind-main (`up to date` / `N commits`).

### 3. Assemble (orchestrator)

Collect the rows the subagents return and **pair each with the `title`,
`headRefName`, and `isDraft`** the orchestrator already has from step 1 (the
subagent doesn't re-fetch these), then render the table + per-PR findings list
(see *Output*) — marking draft PRs from `isDraft`. The output is **identical**
to the series version — only the way the signals are gathered changed.

### Graceful degradation to series

If subagent fan-out is unavailable (no `Agent` tool in the session), fall back
to gathering the four signals **in series** — loop the same per-PR gather over
each PR from step 1. The output is the same; it's just slower.

## Read the LATEST review (the subtle part)

```bash
gh pr view <N> --json comments \
  --jq '[.comments[] | select(.author.login | startswith("claude"))] | last | .body'
```

`startswith("claude")` matches the @claude bot across both API modes
(`gh pr view` → `claude`; REST API → `claude[bot]`). If the result is `null`,
the reviewer may post as `github-actions[bot]` or another login — you must
**not** silently report that as "clean": broaden the filter or flag that no
review was found.

Scan the latest body for any "Findings", "Issues", "Remaining",
"Non-blocking", "Minor", "Could improve", "Consider", etc. section. The bar for
**clean**: "Looks good" / "no findings" / "approved" with **zero** follow-on
bullets under any heading. Anything else is **open** — count the items. A
posted rebuttal the reviewer is still disputing is **open**, not clean: a
rebuttal only counts once it convinced the reviewer (they dropped the item).

## Output

A Markdown table, one row per open PR, with these columns:

| PR | Title | Branch | CI | Review | Threads | Behind main |

- **PR** — make the number a markdown link,
  `[#<N>](https://github.com/<owner>/<repo>/pull/<N>)` (repo policy — never a
  bare `#N`), so it's one-click and compact.
- **CI** — ✅ / ❌ (name the failing check) / ⏳ pending.
- **Review** — `clean`, `N open` (with the headline finding), `none found`
  (filter didn't match / no review yet), or `in-flight` if a review run is
  still going.
- **Threads** — `resolved` (none open) or `N open` (unresolved inline review
  threads).
- **Behind main** — `up to date` or `N commits` (offer `sync-pr-branch`).

Below the table, list each PR's open findings briefly (or "none"), and call out
anything needing action: branches behind main, failing CI, drafts, or reviews
that returned `null`. Do **not** label a PR "ready to merge" unless it is
**fully clean** — its review is genuinely clean *and* all CI workflows are
green *and* it's not behind main *and* every inline review thread is resolved
(the only open conversation being the final all-clear and your reply). Never
hedge with "ready except for one nit."

## Why fan-out is safe here (and the write-loops stay series)

This loop parallelizes because its units are **independent and side-effect-free**
— each PR's signals are read-only and don't depend on any other PR. The
whole-queue *write* loops are different, and deliberately stay (mostly) series:

- **`ardia` / `iterate-all`** — share one working directory, compete for CI
  runner capacity, and have human checkpoints. Parallelize only opt-in, with
  worktree isolation + bounded concurrency — not by default.
- **`gii` / `gia`** — intentionally sequential: a later issue's base branch
  depends on whether the prior MR merged, and same-file issues conflict.

Rule of thumb: fan out a whole-queue loop only when its units are provably
independent and don't mutate shared state — like this one.

## Notes

- Skip draft PRs from the "ready" assessment but still show them (mark as
  draft).
- One unit of work per PR: in the parallel path that's one subagent per PR; in
  the series fallback it's one gather per PR. Either way, the *output* table and
  findings list are identical.

## Relationship to other skills

- **`pr-status`** — the single-PR version; this applies its latest-review-only /
  `null`-not-clean discipline across the whole open-PR queue. (pr-status :
  pr-status-all :: `ardi` : `ardia`.)
- **`ardia` / `iterate-all`** — the *write* counterpart: actually drive every
  open PR to clean. This skill only reports; see *Why fan-out is safe here* for
  why those loops stay series.
- **`sync-pr-branch`** — offered for any PR the table flags as behind main.
