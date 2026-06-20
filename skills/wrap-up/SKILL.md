---
name: wrap-up
description: "End-of-session wrap-up: verify the true state of every PR/issue/branch/working tree (never assume), report a linked final summary that surfaces anything still open or dangling, then run a UMS review to persist what was learned. Use when asked to 'wrap up', 'wrap up the session', 'finish up', 'are we done?', or to close out a multi-PR/issue session."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# wrap-up — verify state, report, then UMS

Close out a work session cleanly: confirm where everything *actually* landed,
report it with clickable links (surfacing anything still open), and capture
what was learned before the context is gone.

Synonyms: `merged` — routes here, and can name the just-merged PR to anchor the
summary (e.g. `/merged #74`). (Distinct from `post-merge`, which wraps up a
single just-merged PR rather than the whole session.)

## When this fires

- "wrap up", "wrap up the session", "finish up", "let's close out", "are we
  done?"
- The end of a multi-PR / multi-issue session.

## Procedure

### 1. Verify state — never assume

Don't report from memory or assume a merge did/didn't happen — query each thing
fresh (this is the **never assume; always verify** rule applied to closing out):

```bash
gh pr list --state open --json number,title,headRefName,author \
  --jq '.[] | "#\(.number) [\(.author.login)] \(.title)"'
gh issue list --state open --json number,title --jq '.[] | "#\(.number) \(.title)"'
git status --short                         # uncommitted work?
git worktree list                          # leftover worktrees (agent isolation / session-lock)?
git log --oneline -5 origin/main           # what actually landed on main
```

- For every PR/issue you touched, confirm its real state with
  `gh pr view <N> --json state,mergedAt` (or `gh issue view`). A PR you think
  you left open may have been merged by the user, and vice-versa.
- If the session touched **other repos** (e.g. an upstream like `d-morrison/gha`),
  check those too — `gh pr list --repo <owner>/<repo> --state open`.

### 2. Surface anything still open or dangling

List, don't bury:

- **Open PRs** — every one, linked. Flag any you didn't expect (e.g. a
  `@claude`-bot-opened PR) instead of silently passing over it.
- **Open issues**, **uncommitted working-tree changes**, **unmerged local
  branches**, and any **deferred follow-up issues** filed this session.
- **Leftover git worktrees** — agent isolation and `session-lock` leave
  worktrees behind (esp. ones whose PR already merged). Flag them and offer to
  run `clean-worktrees` (`cw`) to sweep the dead ones.
- Never report "all done" while something is open — name it and say whose call
  it is (e.g. "PR #25 is the bot's; yours to merge or close").

### 3. Report a linked final summary

- A table of the session's PRs/issues with outcomes, where **every** PR/MR/issue
  number is a markdown link (repo policy — never a bare `#N`).
- A Pacific-time timestamp (`date "+%Y-%m-%d %H:%M %Z"`) so "as of when" is
  unambiguous when the user re-reads it later.

### 4. Run a UMS review

Run the full `ums` procedure (invoke the `ums` skill by name): scan the session
for mistakes-corrected, new user preferences, tool quirks, and skill gaps;
update the relevant memory files and skill definitions; commit via a **branch +
PR** (not direct to `main`). If nothing durable emerged, say so explicitly
rather than manufacturing edits.

## Notes

- Wrap-up is read-only on PR/issue **state** (it reports) except for the UMS
  writes (it persists). It does **not** merge PRs — merging stays the user's
  call unless they ask.
- This is the session-level bookend to `record-learnings` (continuous) and
  `ums` (the learnings checkpoint, which this embeds as step 4).
