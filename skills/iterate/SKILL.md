---
name: iterate
description: Drive a pull request to a clean review verdict by looping request-review → address every finding → re-request-review until there are zero flagged items. Use when asked to "iterate until clean", "address the review comments", "@claude review again and fix what it finds", or after opening a PR you want carried all the way to mergeable. Handles the @claude bot reviewer and human reviewers.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# iterate

Carry a PR to a genuinely clean review verdict, not "ready with a couple of
nits." The loop: request a review, address **every** flagged item, re-request,
repeat — until the reviewer returns no findings under any heading.

## When this fires

- "iterate until clean", "address the review comments", "keep going until the
  reviewer's happy".
- "@claude review again" / iterative review loops on a PR.
- Right after opening a PR you've been asked to take all the way to mergeable.

## The loop

For each round:

1. **Claim the PR** (first round only). Post a brief comment so a parallel
   `@claude` CI run or another person doesn't start a colliding session:
   `gh pr comment <N> --body "Claude Code CLI (local session) is working on
   this — paws off until I'm done."` Skip if your most recent comment already
   says so.

2. **Sync with main.** If main has moved ahead of the PR branch, merge it in
   *before* triggering review, so the reviewer evaluates against current main:
   ```bash
   git fetch origin main
   git log --oneline ..origin/main | head   # any commits? merge them in
   git merge origin/main
   ```
   Resolve conflicts, run the project's pre-commit checks, commit, then push.
   Don't rebase/squash a published branch — a merge commit matches GitHub's
   "Update branch" button.

3. **Request the review — but don't double-trigger.**
   - `@claude` bot reviewer: if you **just pushed code**, the push already
     triggers the review workflow (e.g. `claude-code-review` on `pull_request`
     sync) — do **NOT** also post `@claude review`. On workflows with
     `concurrency: cancel-in-progress` the two runs cancel each other and the
     latest commit ends up with no posted verdict. Only post `@claude review`
     when **no fixes were pushed** this round. If a review gets
     canceled with no comment, dispatch a clean one:
     `gh workflow run claude-review.yml -f pr_number=<N>`.
   - Human reviewer: request one directly —
     ```bash
     gh api -X POST repos/<owner>/<repo>/pulls/<N>/requested_reviewers \
       -f "reviewers[]=<login>"
     ```
     The login is **repo-specific** (default `d-morrison`; change it if you
     use this skill elsewhere). A self-authored PR can't request its own
     author — GitHub returns 422; surface that, don't swallow it. (If your
     config ships a `request-pr-review` skill, use it — it does the same.)

   **Don't let the trigger phrase leak into prose.** The `issue_comment`
   trigger fires on the bare bot `@`-mention **anywhere** in a comment body —
   even inside a sentence saying you're *not* triggering a review. In ARD
   summaries and status comments, refer to it obliquely ("re-request review",
   "the review-trigger mention") or split the tokens (e.g. `@ claude`, with a
   space, so the raw body never contains the contiguous handle); paste the
   literal `@`-mention only when you actually intend to dispatch. A stray mention
   spawns a run that cancels the push-triggered review on `cancel-in-progress`
   setups. On the d-morrison/gha mention bot it also starts a session whose
   residual-commit sweep can churn the branch.

4. **Wait for the review to land, then read the LATEST one.** Don't trust an
   earlier cached verdict — a newer review may have landed since (bot, human,
   or re-trigger). **You MUST actively poll** until a new review appears that
   references the commit you just pushed. Don't declare "clean" based on a
   review that evaluated an earlier commit.

   **Polling procedure:**
   - After pushing, wait ~30–60 seconds for the CI pipeline to trigger the
     reviewer.
   - Then poll the MR/PR notes until you see a review referencing your latest
     commit SHA. Compare the review's "latest: <sha>" against your push.
   - If no new review appears after ~2 minutes, check pipeline status — it
     may have failed before the review job ran.

   **GitHub:**
   ```bash
   gh pr view <N> --json comments \
     --jq '[.comments[] | select(.author.login | startswith("claude"))] | last | .body'
   ```
   The reviewer's bot login varies by API and setup: `gh pr view` reports it
   as `claude`, the REST API (`gh api .../comments`) as `claude[bot]`, and
   some setups post reviews as `github-actions[bot]`. `startswith("claude")`
   matches the @claude bot across both `gh pr view` and `gh api` — broaden it
   if your reviewer posts under a different login, or you'll silently read
   `null` and false-pass.

   **GitLab:**
   ```bash
   # Poll for a review note referencing the latest commit
   LATEST_SHA=$(git rev-parse --short HEAD)
   glab api "projects/<PID>/merge_requests/<IID>/notes?sort=desc&per_page=3" \
     | python3 -c "
   import json, sys
   notes = json.load(sys.stdin)
   for n in notes:
       if 'Auto-review' in n['body'] and '$LATEST_SHA' in n['body']:
           print(n['body']); sys.exit(0)
   print('NO_NEW_REVIEW'); sys.exit(1)
   "
   ```
   If exit code is 1, wait and retry. Don't proceed until you have a review
   that evaluated your latest push.

   `gh pr checks` / `glab ci list` going green is about **CI state**, **not**
   the review verdict — always parse the latest review body for findings.
   (If `gh` JSON parsing gets fragile, structured MCP GitHub CI tools like
   `mcp__github_ci__get_ci_status` are an alternative where available.)

5. **Address every flagged item — regardless of severity label.** "Not a
   blocker", "minor", "nit", "optional", "consider", "if you want" are for the
   user's prioritization, not a pass for the implementer. For each item,
   exactly one of:
   - **Fix it in this PR** (the default — most nits are 1–3 lines), or
   - **Defer to a tracked issue** — only when the fix genuinely expands scope
     (new feature, broader refactor, separate concern). Open one with
     `gh issue create --title "…" --body "…"` and post its URL back as a PR
     comment so the item isn't lost. (If your config ships a `defer-issue`
     skill, use it — it formats the issue and cross-links the PR.)

6. **Push the fixes** (sync main again first if it moved). Post a short
   comment summarizing what you addressed and how (fixed vs. deferred + issue
   link).

7. **Re-request review (back to step 3) and repeat** until the PR is **fully
   clean** (see *The bar: "fully clean"* below). That means the verdict
   contains **zero** flagged items under any heading — no "non-blocking",
   "minor observation", "could improve", etc.; "Looks good" / "no findings" /
   "approved" with no follow-on bullets — **and** all CI workflows are green
   **and** every inline thread is resolved. Don't exit on a clean review body
   alone.

## Fix broken CI/workflows too

If the PR's CI checks are failing (not just the review), investigate and fix
them as part of the iterate loop — don't declare "clean" with red CI. This
includes:

- **Workflow syntax errors** — fix them in this repo.
- **Upstream template bugs** — if the failure is in a reusable workflow from
  a shared CI library (e.g., HACtions) or a GitHub Action, file an issue (or open a PR) upstream using
  the `sup` skill, then either pin a working version or apply a local
  workaround until the upstream fix lands.
- **Flaky / infra failures** — retry once; if it persists, investigate root
  cause.

The goal is green CI + clean review, not just clean review.

## The bar: "fully clean"

The loop ends only at **fully clean**, which means **both**:

1. **All CI workflows green** — every required check, not just the review job
   (see *Fix broken CI/workflows too* above).
2. **The latest review is totally clean** — nothing flagged under any heading.
   Every item that wasn't directly **Addressed** is either **Deferred** to a
   tracked issue or **Rebutted with a rebuttal that actually convinced the
   reviewer** (they didn't re-raise it on the next round). A rebuttal the
   reviewer still disputes does **not** count as clean.

**Threads:** at fully-clean, every **inline** review thread is resolved, and
the only conversation left open is the final all-clear exchange — the
reviewer's all-clear comment (usually a top-level PR comment, not an inline
thread) and your reply to it (see the `ard` skill, step 4b, for thread
mechanics).

Don't stop at, or report, "ready to merge with one minor nit noted" /
"harmless as-is" / "can address if you want." That hedging just pushes triage
back to the user.

## Asymptotic-noise guard and deadlocks

- **Deadlock on an item:** if you and the reviewer can't reach consensus (your
  rebuttal didn't convince them, and their re-raise didn't convince you),
  **escalate to a human reviewer** for the final call rather than looping or
  unilaterally overriding. Request `d-morrison` via the `request-pr-review`
  skill (or `gh pr edit <N> --add-reviewer d-morrison`), `@`-mention them with
  the impasse, and surface the open item to the user.
- **Asymptotic noise:** if after **3–4 rounds** the reviewer keeps generating
  *new* nits each cycle (chasing diminishing returns rather than converging),
  stop and surface that to the user: summarize the open items and ask whether
  to keep going or accept the current state. Don't loop forever.

## On clean

- If you claimed the PR, post a closing/unclaim comment so it's free for the
  next person.
- Report the final verdict and the round count, with a clickable link to the
  MR/PR. Don't merge unless the user asked — opening the merge is their call.

## Driving many PRs at once

When iterating a batch, process the PRs in series (or on a recurring interval
if your tooling supports it), keeping the per-PR rules above intact (claim,
sync, address *every* item, re-request, latest-review-only). Report a per-PR
status table at the end; link each PR number to its URL.
