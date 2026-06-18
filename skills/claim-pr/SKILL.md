---
name: claim-pr
description: "Post a 'paws off' claim comment on a PR/MR or issue before starting a work session on it, and resolve/unclaim when done, so other humans and the @claude CI bot don't start a colliding parallel session. Use before fetching a branch, editing, or running review cycles on a PR/issue — and after the work is paused, merged, or closed."
user-invocable: true
allowed-tools:
  - Bash
---

# claim-pr

Before working a PR/MR or issue — fetching its branch, editing, or running
`@claude` review cycles — post a brief comment so other people and the
`@claude` CI bot know not to start a conflicting parallel session. **Resolve**
(or post a closing comment on) the claim when the session ends.

## When this fires

- Before any **write** session on a PR/issue: fix, implement, debug, refactor,
  review-and-edit, or an iterative `@claude review` loop that pushes commits.
- Triggered by a prompt referencing a PR/issue by `#N` or URL that asks you to
  *change* something.

It does **NOT** fire for read-only inspection — "show me PR #X", "what's the
status of #Y", "explain the diff on #Z". Those don't risk a parallel session.

## Claim (start of session)

First check whether you've already claimed it — if your (Claude's) most recent
comment on the thread already says you're working on it, **skip** re-posting.

### GitHub

```bash
gh pr comment <N> --body "Claude Code CLI (local session) is working on this — paws off until I'm done."
gh issue comment <N> --body "Claude Code CLI (local session) is working on this — paws off until I'm done."
```

### GitLab

On GitLab, post the claim as a **resolvable discussion** (not a plain note)
so it can be resolved later:

```bash
glab mr note create <N> --message "Claude Code CLI (local session) is working on this — paws off until I'm done."
```

> GitLab MR notes are resolvable discussions by default.

Then proceed with the work.

## Unclaim (end of session)

After the work is done (MR merged, issue closed) or paused, **resolve the
claim discussion thread** so it doesn't clutter the MR as an open thread.

### GitLab — resolve the discussion

```bash
# 1. Find the discussion ID containing the claim note
DISCUSSION_ID=$(glab api "projects/<PROJECT_ID>/merge_requests/<MR_IID>/discussions?per_page=100" \
  | python3 -c "
import json, sys
for d in json.load(sys.stdin):
    for n in d.get('notes', []):
        if 'paws off' in n.get('body', '') and not n.get('resolved'):
            print(d['id']); break
    else: continue
    break
")

# 2. Resolve it
glab api --method PUT \
  "projects/<PROJECT_ID>/merge_requests/<MR_IID>/discussions/${DISCUSSION_ID}" \
  -f "resolved=true"
```

### GitHub — post a closing comment

```bash
gh pr comment <N> --body "Done with my local session — unclaiming."
gh issue comment <N> --body "Done with my local session — unclaiming."
```

## Notes

- If `@claude` agent runs are in flight on the branch, wait for them before
  pushing or polling — don't edit while the bot is mid-session.
- This is the claim ritual referenced by `iterate` (step 1) and `iterate-all`;
  when those run, they cover the claim for you.
- On GitLab, **always prefer resolving** the discussion over posting a second
  "unclaim" comment — it keeps the MR thread clean and signals completion
  without adding noise.
