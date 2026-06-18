---
name: ard
description: "Address, Rebut, Defer, or Acknowledge: respond to every review comment on a PR/MR with exactly one disposition. For each item a reviewer (human or bot) raises, choose one — fix it (Address), explain why it's correct as-is (Rebut), file a follow-up issue (Defer), or acknowledge a no-change-requested observation (Acknowledge). Silently ignoring a comment is never acceptable. Works on GitHub (gh) and GitLab (glab). Use after receiving a review, when asked to 'address reviews' / 'respond to the review', or as the inner loop of the iterate skill."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# ARD — Address, Rebut, Defer, or Acknowledge

Every review comment gets exactly one disposition: **A**, **R**, **D**, or **K**. Ignoring is not an option.

## What counts as a finding

A *finding* is anything the reviewer requests or implies a change to — including items tagged "nit", "minor", "non-blocker", "optional", or "consider". All of these require **Address**, **Rebut**, or **Defer**.

Pure praise or neutral observations with **no** requested change ("nice refactor", "TIL") still get a row — disposition **Acknowledge** — so the summary accounts for *every* comment the reviewer made and nothing reads as silently dropped.

## The four dispositions

| Code | Meaning | Action required |
|------|---------|-----------------|
| **A** — Address | Valid and in-scope. | Fix it in this PR/MR and commit. |
| **R** — Rebut | Incorrect, already handled, or a misunderstanding. | Explain *why*, citing concrete evidence (line, test, doc, spec). Specific enough that the reviewer can verify it without re-reading the whole PR. |
| **D** — Defer | Valid but out of scope (new feature, broad refactor, needs design discussion). | File a follow-up issue (`gh issue create` / `glab issue create`), link it, and add it to the PR/MR's **Deferred / Out-of-Scope** section. |
| **K** — Acknowledge | Praise or a neutral observation with no change requested. | Give it a row so it's accounted for; no code change, no rebuttal needed. Don't stretch this to dodge a real finding. |

### Decision order

For anything that requests a change, choose among the first three (Acknowledge is only for no-ask comments):

1. **Address** — the default. Most findings are 1–5 line fixes; if it takes under ~2 min, just fix it.
2. **Rebut** — only when you're confident the reviewer is mistaken. A rebuttal that isn't falsifiable ("I think it's fine") is not a rebuttal.
3. **Defer** — only when the fix genuinely expands scope. Never defer just because a fix is "minor" — minor fixes get Addressed.

## Procedure

### 1. Gather every finding

Collect the full set *before* dispositioning, so none slips through. Pull both the summary comment and the inline review threads.

**GitHub**

```bash
gh pr view <N> --comments                            # top-level + summary comments
gh api repos/{owner}/{repo}/pulls/<N>/comments       # inline review-thread comments
```

**GitLab**

```bash
glab mr view <N> --comments                          # discussion notes
glab api "projects/:id/merge_requests/<N>/discussions"   # inline threads
```

Bots often post the same finding twice — once inline and once in the summary comment. Collect the **union and dedupe** before numbering, so one issue doesn't get two rows (or two conflicting dispositions). Then number 1..n; every number must end up with a row in the summary.

### 2. Disposition each one

Apply the decision order above. For Address items, make the edits now.

### 3. Commit Addressed fixes (one commit per review round)

```bash
git add -p                                           # stage deliberately
git commit -m "fix: address round <k> review findings"
git push
```

- **One commit per round**, not one per finding — reference its SHA in every Address row.
- **Never `--amend`** the already-reviewed commits: the reviewer (and CI) ran against them and others may have pulled. A fresh commit keeps the audit trail.
- Don't push generated cruft (`.Rout`, build artifacts); respect the repo's `.gitignore`.
- If every finding is Rebut/Defer, there's nothing to commit — skip to step 4 and still post the summary.

### 4. Post one summary comment

Write the summary to a file and post it *from* the file — **never inline on GitLab**, because `glab` mis-parses backticks (e.g. commit SHAs in code spans) as shell subcommands:

```bash
# write the summary to ard-summary.md, then:
gh pr comment <N> --body-file ard-summary.md         # GitHub
glab mr note <N> -F ard-summary.md                   # GitLab
```

Summary format:

```
Addressed findings from review of <commit-or-range>:

| # | Finding | Disposition | Detail |
|---|---------|-------------|--------|
| 1 | <summary> | ✅ Address | Fixed in <commit-sha> |
| 2 | <summary> | 🔄 Rebut | <one-line reason> |
| 3 | <summary> | 📌 Defer | <issue-link> |
| 4 | <summary> | 👍 Acknowledge | <one-line thanks / note> |

### Rebuttal: Finding 2
<full explanation with evidence>
```

Expand each Rebut below the table. Deferred rows must carry a real issue link.

### 4b. Reply to every inline review thread — and resolve where appropriate

The one summary comment is **not** enough on its own. A reviewer who left
inline comments wants a response **on each thread**, not just a table posted
elsewhere. For every inline comment, post a short reply on its own thread with
the disposition (and the commit SHA for an Address), then **resolve** the thread
once the item is genuinely settled.

**GitHub** — reply on the comment's thread, then resolve via GraphQL:

```bash
# Reply on the same thread as inline comment <comment_id>:
gh api repos/{owner}/{repo}/pulls/<N>/comments \
  -f body="✅ Addressed in <sha>." -F in_reply_to=<comment_id>

# List threads to get the node id, then resolve the settled one:
gh api graphql -f query='query { repository(owner:"<owner>",name:"<repo>") {
  pullRequest(number:<N>) { reviewThreads(first:100) { nodes {
    id isResolved comments(first:1){ nodes { databaseId body } } } } } } }'
gh api graphql -f query='mutation {
  resolveReviewThread(input:{threadId:"<thread_node_id>"}) { thread { isResolved } } }'
```

**GitLab** — reply to the discussion, then resolve it:

```bash
glab api -X POST "projects/:id/merge_requests/<N>/discussions/<discussion_id>/notes" \
  -f body="Addressed in <sha>."
glab api -X PUT "projects/:id/merge_requests/<N>/discussions/<discussion_id>?resolved=true"
```

**Resolve only when the item is actually settled:**

- **Address** — resolve after the fix is **pushed** (reply names the SHA). Never
  resolve an Address whose fix isn't on the branch yet.
- **Defer** — reply with the tracked issue link, then resolve (work lives
  elsewhere now).
- **Acknowledge** — reply briefly, then resolve.
- **Rebut** — reply with the falsifiable evidence. Resolve if the reviewer is a
  bot or you're confident; **leave a human's thread open** if they may want to
  respond to the rebuttal.

Don't resolve a thread you haven't replied to. Every inline comment ends with
both a reply and (where appropriate) a resolution — silence on a thread reads as
ignored, exactly the failure ARD exists to prevent.

### 5. Report back with a link

Tell the user what you did and give a **clickable URL** to the PR/MR (and to the posted summary comment if available), so they can review in one click.

## Rules

- **Every reviewer comment appears in the table AND gets a reply on its own inline thread** (step 4b). The summary table is the overview; the per-thread reply is what the reviewer sees in context. A thread with no reply reads as ignored.
- **Resolve threads once settled** (Addressed-and-pushed / Deferred-with-issue / Acknowledged), but never resolve a thread you haven't replied to or whose fix isn't pushed — and leave a human reviewer's thread open if they may want to respond.
- **Severity never exempts.** "Nit" / "optional" / "consider" still require A, R, or D — never K.
- **Rebuttals must be falsifiable** — point to specific code, behavior, or documentation.
- **Deferrals must be tracked.** A defer without a filed issue is just ignoring with extra words.
- **Push before you post.** The reviewer should be able to verify Addressed fixes are on the branch.

## Integration with iterate

Inside the `iterate` loop:

1. Read the latest review (iterate step 4)
2. Apply ARD to each finding (this skill: steps 1–2)
3. Commit + push fixes (this skill: step 3)
4. Post the ARD summary and per-thread replies (this skill: steps 4–4b)
5. Re-request review (iterate step 3) — **even if this round was Rebut/Defer only**, so the reviewer re-evaluates.

The loop continues until the reviewer returns zero findings (and CI is green).

## Edge cases

- **Ambiguous finding** — if you can't tell whether it's a change request or an observation, treat it as a finding and Address or Rebut. Don't assume it's informational.
- **Reviewers contradict each other** — Address the most recent reviewer; note the contradiction in your response so the user can arbitrate.
- **Finding duplicates a deferred item** — Rebut by pointing to the existing issue. Keeping the **Deferred / Out-of-Scope** section current in the PR/MR description should prevent re-flagging; if it recurs, update that section.
