---
name: ardia
description: "ARD + Iterate-All: apply ARDI (ARD + iterate) to every open PR/MR in the repo. Drive each one to a clean review verdict in turn. Use when asked to 'ardia', 'iterate all', 'iterate all PRs', 'iterate every open PR', 'carry every open PR to clean', 'review-loop all my PRs', 'drive all MRs to clean', or to run the ARD-iterate loop across the whole open-PR queue rather than a single PR."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ARDIA — ARD + Iterate-All

Apply the ARDI loop (ARD + iterate) to every open PR/MR in the repo, driving
each to a clean review verdict in series.

## Procedure

1. **List the open PRs/MRs and decide which are in scope.**
   ```bash
   gh pr list --state open --limit 100 \
     --json number,title,headRefName,baseRefName,isDraft,author,reviewDecision
   ```
   On GitLab, use `glab api "projects/:id/merge_requests?state=opened&per_page=100"`
   and look for `source_branch` (≡ `headRefName`) and `target_branch` (≡ `baseRefName`)
   in the JSON — `glab mr list` alone does not expose these fields.
   State the scope rules when you report, so the user can
   correct:
   - **Skip drafts** by default (`isDraft: true`) — they aren't ready for the
     clean-verdict bar. Include one only if the user explicitly asks.
   - **Only iterate PRs the user owns / is responsible for** by default. In a
     shared repo, don't start review loops (which push commits) on other
     people's PRs unless told to. If unsure who owns what, ask first.
   - If the list is empty, say so and stop — nothing to do.

   **Detect and sort stacked PRs.** Check each PR's `baseRefName`. If any PR's
   `baseRefName` matches another open PR's `headRefName`, they are stacked.
   Sort the list so base PRs come before the PRs stacked on them —
   process bases first so derived PRs always sit on a clean, reviewed base. Note
   any stack in the scope report:
   ```
   Stacked PRs detected: #A → #B (process #A first)
   ```
   If a circular stack is found (impossible in practice but check anyway),
   surface it to the user and skip those PRs.

   Report the in-scope list (with bare PR URLs) **before** you start, so the
   user can veto any before the loop pushes commits.

2. **For each PR/MR, in series, run ARDI** (the full single-PR loop — see the
   `ardi` skill): claim → sync main → read latest review → ARD every finding →
   push → post summary → re-request review → repeat until fully clean. Don't
   reimplement that loop here; follow it per PR.

   **For stacked PRs:** the ideal flow is to merge the base PR before starting
   ARDI on the derived PR. If the base isn't mergeable yet (pending CI, open
   review findings), complete ARDI on the base first to drive it to clean and
   merge it, then start the derived PR. Never run ARDI on a derived PR while its
   base is still open and unclean — you'd be reviewing against a moving target.

   Drive each to a terminal state:
   - **Clean** — zero flagged items under any heading; post the unclaim
     comment, record the round count.
   - **Asymptotic noise** — per ARDI's guard, if after 3–4 rounds the reviewer
     keeps emitting *new* nits, stop that PR, record it "stalled (noise)", move on.
   - **Blocked** — needs a human decision, has unresolvable conflicts, or fails
     preflight in a way your change didn't cause. Record what's blocking, move on.

   **Process PRs one at a time, not concurrently.** Each ARDI run pushes
   commits, triggers review workflows, and polls for the result; running them
   in parallel would interleave pushes, collide on shared review runners, and
   make per-PR status illegible. One PR stalling or blocking must not abort the
   batch — keep going to the next.

3. **Report a summary table** at the end, with clickable links:

   | MR/PR | Rounds | Final status |
   |-------|--------|--------------|
   | [#25](url) | 3 | ✅ Clean |
   | [#26](url) | 4 | ⚠️ Stalled (noise) — open items: … |
   | [#27](url) | 1 | ⛔ Blocked — needs human decision on … |

   For any PR not driven to clean, **list its remaining open items** so triage
   is one glance, not a re-investigation. Don't merge anything — opening merges
   is the user's call.

## Orchestration

ARDIA drives PRs **one at a time on purpose** (see *Process PRs one at a time*
above): each round pushes commits and triggers shared review runners, so parallel
pushes collide and make per-PR status illegible. A Workflow does not change that
external limit --- do **not** fan out the push --- re-review --- merge loop. What
you *can* orchestrate is the read-only survey: pull every open PR's latest review
and triage its findings in parallel, then feed that into the serial fix loop.
Consult `shared/workflow/when-to-orchestrate.md` (the shared-runner exception);
default to the serial loop, and propose the read-only fan-out only when there are
many PRs to survey.

## Recurring / unattended runs

If asked to keep the queue clean on an interval, drive this skill from a
recurring runner (e.g. the `loop` skill) rather than busy-waiting inside one
invocation. Each tick re-enumerates open PRs (new ones appear, merged ones drop
off) and runs the series loop over the current set.
