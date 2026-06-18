---
name: ardi
description: "ARD + Iterate: apply the ARD framework within an iterate loop on a single PR/MR. Read the latest review, Address/Rebut/Defer every finding, push fixes, post the ARD summary, then re-request review — repeating until the verdict is clean. Use when asked to 'ardi', 'dc', 'drive to clean', 'iterate this MR', 'drive this PR to clean', or after receiving a review you want to resolve completely."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ARDI — ARD + Iterate (single PR/MR)

Drive one PR/MR to a clean review verdict by looping: read review → ARD every
finding → push → post summary → re-request review → repeat until clean.

## Procedure

1. **Identify and claim the PR/MR.** Use the current branch's open MR, or
   the one the user specified. Post a brief claim comment so a parallel
   `@claude` CI run or another person doesn't start a colliding session:
   `gh pr comment <N> --body "Driving this PR to clean — back off until done."`
   Skip if your most recent comment already says so.

2. **Read the latest review.** Pull the most recent reviewer comment (bot or
   human). Don't trust earlier cached verdicts.

3. **ARD every finding.** For each flagged item, choose exactly one:
   - **Address** — fix it, commit.
   - **Rebut** — explain why it's correct (with evidence).
   - **Defer** — file a follow-up issue, link it.

4. **Push fixes** (if any). Sync with main first if it moved ahead.

5. **Post the ARD summary** as a comment on the MR/PR (table format per the
   ARD skill).

6. **Re-request review — but don't double-trigger.** How depends on whether
   this round pushed code:
   - **Code was pushed:** the push **already** triggers the review (e.g.
     `claude-code-review` on `pull_request` sync). Do **NOT** also post
     "@claude review again". On workflows with `concurrency:
     cancel-in-progress` (the d-morrison/gha setup), the push-triggered and
     mention-triggered runs **cancel each other**, leaving the latest commit
     with a canceled, never-posted verdict. Just wait for the push-triggered
     review.
   - **No code pushed** (all Rebut/Defer): no push occurred, so nothing
     auto-triggers — you **must** explicitly re-request (post `@claude review`,
     or the forge's equivalent). This is the only case where you post the
     mention.
   - **A review ends up canceled with no comment:** trigger one cleanly via
     `gh workflow run claude-review.yml -f pr_number=<N>` (input is
     `pr_number`) and don't push/comment again until it posts. Note: a review
     run on a **bot-pushed** commit may show as `action_required` (gated) and
     never run — the explicit `workflow_dispatch` bypasses that.

   Then wait for the new verdict.

7. **Repeat from step 2** until the verdict has zero findings.

## Fix broken CI/workflows too

If the PR's CI checks are failing (not just the review), investigate and fix
them as part of the ARDI loop — don't declare "clean" with red CI. This
includes:

- **Workflow syntax errors** — fix them in this repo.
- **Upstream template bugs** — if the failure is in a reusable workflow from
  a shared CI library (e.g., HACtions) or a GitHub Action, file an issue (or open a PR) upstream using
  the `sup` skill, then either pin a working version or apply a local
  workaround until the upstream fix lands.
- **Flaky / infra failures** — retry once; if it persists, investigate root
  cause.

The goal is green CI + clean review, not just clean review.

## The bar

Zero flagged items under any heading. "Looks good" / "no findings" / "approved"
with no follow-on bullets. Don't stop at "ready with one minor nit."

## Asymptotic-noise guard

If after 3–4 rounds the reviewer keeps generating new nits (not converging),
surface that to the user and ask whether to continue or accept.

## On clean

Post an unclaim comment (`gh pr comment <N> --body "Done — PR is free."`) to
unblock any parallel sessions that backed off in step 1.

Always provide a clickable link to the MR/PR in the final message.

Report the final verdict and round count. Don't merge unless asked.
