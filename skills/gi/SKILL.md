---
name: gi
description: "Grab Issue: pick the highest-priority open issue from the repo's tracker (re-triaging if helpful), implement it on a branch, open an MR/PR, and ARDI it to clean. Use when asked to 'gi', 'grab an issue', 'pick up the next issue', 'work on the top issue', or 'what should I work on next?'"
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# GI — Grab Issue

Pick the highest-priority open issue, implement it, open an MR/PR, and drive
it to a clean review verdict via ARDI.

## When this fires

- User says "gi", "grab an issue", "pick up the next issue"
- User says "what should I work on next?"
- User says "work on the top issue", "grab the highest-priority one"

## Procedure

### 1. List open issues

```bash
# GitHub
gh issue list --state open --limit 20 --json number,title,labels,assignees,createdAt | cat

# GitLab
glab issue list --per-page=20 2>&1 | cat
```

### 2. Triage / prioritize

Scan the issue list and rank by priority. Use these signals (in order):

| Signal | Weight |
|--------|--------|
| Explicit priority label (`P0`, `critical`, `high-priority`, `urgent`) | Highest |
| Blocking other work (mentioned in other issues/MRs) | High |
| Bug vs feature (bugs first, generally) | Medium |
| Age (older unresolved issues accumulate cost) | Medium |
| Size/complexity (prefer issues you can complete in one session) | Tie-breaker |
| Already assigned to someone else | **Skip** |

**Re-triage if helpful:** If labels are stale, missing, or inconsistent, briefly
suggest re-labeling to the user before proceeding. Don't unilaterally relabel
without asking — but do flag it:

> "Issues #4 and #7 both look high-priority but neither is labeled. Want me to
> label them before picking one, or just grab #4 (older, looks like a bug)?"

### 3. Confirm selection with user

Present the top 1–3 candidates with a one-line summary each. Let the user
pick, or proceed with #1 if they say "just go":

> | # | Issue | Why |
> |---|-------|-----|
> | 1 | #12 — Fix auth timeout on slow networks | Bug, P1, oldest |
> | 2 | #8 — Add retry logic to API client | Feature, blocks #12 |
> | 3 | #15 — Update docs for v3 migration | Docs, easy win |
>
> I'd grab **#12** — want me to proceed, or pick a different one?

If the user already specified an issue ("gi #12"), skip this step.

### 4. Check history

Before implementing, invoke the `check-history` skill to review merged
MRs/PRs that touched the same area. Don't undo past progress.

### 5. Claim the issue

```bash
# GitHub
gh issue comment <N> --body "Claude Code CLI (local session) is working on this — paws off until I'm done."

# GitLab
glab issue note <N> --message "Claude Code CLI (local session) is working on this — paws off until I'm done."
```

### 6. Create a branch

```bash
git fetch origin main
git checkout -b fix/<slug> origin/main   # or feat/<slug>, docs/<slug>
```

Branch naming:
- Bug fix → `fix/<issue-slug>`
- Feature → `feat/<issue-slug>`
- Docs → `docs/<issue-slug>`
- Refactor → `refactor/<issue-slug>`

### 7. Implement

- Read the issue description carefully — understand "done" criteria
- Make the changes (code, tests, docs as needed)
- Run the repo's standard checks (lint, test, build) before committing
- Commit with a message referencing the issue:
  `fix: handle auth timeout on slow networks (closes #12)`

### 8. Push and open MR/PR

```bash
git push -u origin fix/<slug>
```

```bash
# GitHub
gh pr create --title "<title>" --body "Closes #<N>

<description of what was done and why>"

# GitLab
glab mr create --title "<title>" --description "Closes #<N>

<description>" --assignee <your-gitlab-username>  # default: demorrison
```

Include `Closes #N` in the description to auto-close the issue on merge.

### 9. ARDI to clean

Invoke the `ardi` skill on the newly opened MR/PR. Drive it through
review rounds until the verdict is clean (zero findings).

### 10. Report

When ARDI completes clean, report:
- Issue number + link
- MR/PR number + link
- Round count
- Any deferred items (with follow-up issue links)

Don't merge unless asked. When you do merge, see
[§Concurrent-session collisions](#concurrent-session-collisions) first.

## Concurrent-session collisions

This repo often has many sessions running at once, so another session can open
a PR that closes "your" issue *after* you started — the claim comment and the
opening PR-list scan won't catch a PR that didn't exist yet. Re-check right
before merging (and treat an unexpected merge conflict as a signal):

- Search open *and merged* PRs for one that already references `Closes #<N>`
  for your issue (`gh pr list --state all --search "closes #<N>"` / the GitHub
  `search_pull_requests` tool) — the default `gh pr list` lists only open PRs
  and would miss a sibling that already merged and closed the issue, the case
  that matters most. If the issue is already closed, don't merge a now-redundant
  PR blindly.
- If a sibling PR landed first, sync `main` into your branch and **read the
  resulting diff** — keep only the parts the sibling missed, drop the
  duplicates, and reframe the PR (it no longer `Closes #<N>`; it's a follow-up).

## Handling blocked issues

If during implementation you discover the issue is blocked (missing
dependency, needs design decision, upstream bug):

1. Post a comment on the issue explaining the blocker
2. Label it `blocked` if the repo uses that label
3. Report to the user and offer to pick the next issue instead

## Relationship to other skills

- **`check-history`** — invoked in step 4 to avoid undoing past work
- **`ardi`** — invoked in step 9 to drive the MR/PR to clean
- **`claim-pr`** — the issue claim in step 5 follows the same pattern
- **`split-concerns`** — if the implementation grows too large, offer to split
- **`defer-issue`** — if sub-tasks emerge during implementation, defer them

## Anti-patterns

- ❌ Grabbing an issue already assigned to someone else
- ❌ Starting implementation without checking history
- ❌ Opening an MR without running the repo's standard checks first
- ❌ Picking a huge issue that can't be completed in one session without
  discussing scope with the user first
- ❌ Implementing without understanding "done" criteria from the issue
- ❌ Forgetting `Closes #N` in the MR/PR description
- ❌ Merging without re-checking that a concurrent session's PR hasn't already
  closed the issue (resolve a surprise merge conflict by reading the diff, not
  blindly)
