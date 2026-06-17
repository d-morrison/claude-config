---
name: ardi
description: "ARD + Iterate: apply the ARD framework within an iterate loop on a single PR/MR. Read the latest review, Address/Rebut/Defer every finding, push fixes, post the ARD summary, then re-request review — repeating until the verdict is clean. Use when asked to 'ardi', 'iterate this MR', 'drive this PR to clean', or after receiving a review you want to resolve completely."
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

6. **Re-request review.** If no code was pushed (all items were Rebutted or
   Deferred), the push won't auto-trigger a new review — you must still
   explicitly re-request review (e.g., post a comment triggering the bot,
   or use the forge API to request a new review). The ARD summary comment
   itself can serve as the trigger if the reviewer bot watches for it.
   Wait for the new verdict.

7. **Repeat from step 2** until the verdict has zero findings.

## The bar

Zero flagged items under any heading. "Looks good" / "no findings" / "approved"
with no follow-on bullets. Don't stop at "ready with one minor nit."

## Asymptotic-noise guard

If after 3–4 rounds the reviewer keeps generating new nits (not converging),
surface that to the user and ask whether to continue or accept.

## On clean

Always provide a clickable link to the MR/PR in the final message.

Report the final verdict and round count. Don't merge unless asked.
