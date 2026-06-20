# User-wide Claude Code instructions

## Run UMS before /clear

When the user says "clear", "/clear", or otherwise asks to reset the
conversation, **first** run the `ums` (Update Memories and Skills) procedure
to capture any accumulated learnings before context is lost. Then proceed
with the clear.

## Timestamp recaps in local time

When printing a status recap or summary, include a timestamp in the user's
local time zone (Pacific Time, `America/Los_Angeles` — get it from
`date "+%Y-%m-%d %H:%M %Z"`). This makes "as of when" unambiguous when the
user reads the recap later.

## Bare queue-command keywords

I maintain a family of slash skills for managing the task queue and amending
requests: `/also`, `/first`, `/next`, `/before`, `/last`, `/and`, and
`/remember`. When I write one of these keywords **without the leading slash** as
a directive — e.g. "also fix the test", "remember that ...", "and bold it",
"next, run the spellcheck", "first, revert that" — interpret it using the
corresponding skill's semantics rather than as ordinary prose. When the word is
genuinely just part of a sentence (ambiguous), fall back to the plain reading.

## Link PRs in tables

When listing PRs in a table (or anywhere they could be clickable), make
each PR number a markdown link to the PR URL —
`[#237](https://github.com/<owner>/<repo>/pull/237)`. The plain text form
forces the user to copy/paste; the linked form lets them open the PR in
one click.

## Re-check for latest review findings before reporting PR status

**Before** reporting status on a PR (especially "clean" / "ready to merge"),
re-read the **most recent** review comment on the PR. Don't trust an earlier
"verdict" you've cached — a new review may have been posted since (by the
@claude bot, by a human, or by a re-trigger), and that newer review may
contain findings the old one missed.

Specifically: when scanning checks (`gh pr checks`) shows green or "no
failures", that's about CI state, **not** review verdict. Always pull the
latest claude comment (`gh pr view N --json comments --jq
'[.comments[] | select(.author.login == "claude")] | last | .body'`)
and parse it for any "Findings", "Issues", "Remaining" sections before
declaring a PR ready.

(A specific case of the standing **never assume; always verify** rule in
`memories/preferences.md` — confirm the verdict with a fresh query, don't
recall it.)

## Claim a GitHub PR/issue before working on it

Before starting a work session on a GitHub PR or issue — i.e. before fetching
the branch, making edits, or invoking `@claude` review cycles — post a brief
comment on the PR/issue so other humans and the `@claude` CI bot know not to
start a conflicting parallel session.

Use:

```
gh pr comment <N> --body "Claude Code CLI (local session) is working on this — paws off until I'm done."
gh issue comment <N> --body "Claude Code CLI (local session) is working on this — paws off until I'm done."
```

Then proceed with the work. After completing the session (PR merged, issue
closed, or work otherwise paused), follow up with a closing comment so the
PR/issue is unclaimed for the next person.

Skip the claim step if the most recent comment from me (Claude) on that
PR/issue already says I'm working on it.

This applies to:

- Direct fix/review/implement/debug/refactor prompts that reference a PR or
  issue (`#N`, a PR URL, or an issue URL)
- Iterative review loops (`@claude review again`, `iterate until clean`)
- Any task that will push commits to a PR branch

It does **not** apply to read-only inspection: `show me PR #X`, `what's the
status of #Y`, `explain the diff on #Z`. Those don't risk a parallel session.

## File an issue before starting a new task

When starting a **new** piece of work, go **issue-first**: before branching,
editing, or opening a PR, make sure a tracking issue exists. Search the tracker
first; if no open issue covers the task, **file one** (`gh issue create` /
`glab issue create`), then proceed. Never jump straight into a PR without a
tracking issue behind it.

The issue is the durable record of intent, scope, and "done" criteria — it
gives reviewers context, lets the PR auto-close it via `Closes #N`, and keeps
the work discoverable even if the PR stalls. The `st` (Start Task) skill
operationalizes this; `gi` (Grab Issue) is the path when the issue already
exists. Skip only when the task is already tracked by an open issue.

## Wrap up a merged PR with UMS

When a PR/MR you were working on **merges**, run the `post-merge` skill:
verify the merge actually landed, tidy the local branch (checkout `main`,
pull, `git branch -d`), confirm any deferred items have follow-up issues, then
run **UMS** to capture what the PR's review lifecycle taught — recurring review
findings, corrections, and guidance given along the way. A merge is the natural
checkpoint to bank lessons before the context is lost.

## Always run ARDI on PRs you touch

Whenever I'm working a PR/MR, run the full **ARDI** loop by default, without
being asked: **A**ddress every flagged item, **R**ebut findings that are wrong,
**D**efer out-of-scope items to tracked issues, then **I**terate with a fresh
review — repeating until the latest review has zero flagged items under any
heading. Don't stop at "review-clean, just needs approval" and hand triage
back; keep the cycle going until it's genuinely clean. (Mechanics for each
step are in the sections below.)

## Address every in-scope review comment, even non-blockers

When iterating on a PR with `@claude review` (or any other reviewer), **address
every in-scope flagged item**, regardless of severity label. The reviewer's
"Not a blocker", "minor", "nit", "optional", "consider", or "if you want"
labels are for the user's prioritization, not a free pass for the implementor.

For each flagged item, exactly one of:

1. **Fix it in this PR.** Default path — most nits are 1–3 line changes.
2. **Defer to a tracked issue.** Only when the fix expands the PR's scope
   (new feature, broader refactor, separate concern) or the user has
   explicitly said this PR shouldn't grow. File a follow-up issue and
   reference it in a PR comment so the item isn't lost.

Then trigger another `@claude review` (or the equivalent) and repeat until the
verdict contains zero flagged items under any heading — no "non-blocking",
"harmless", "minor observation", "could improve", etc. sections. "Looks good"
/ "no findings" / "approved" with no follow-on bullets is the bar.

Do **not** report "ready to merge with one minor nit noted" / "harmless
as-is" / "can address if you want" — that hedging just pushes triage back to
the user.

If after 3–4 rounds the reviewer keeps generating new nits each cycle
(asymptotic noise), surface that to the user and ask whether to keep going or
accept the current state.

## Keep PR branches synced with main

Whenever `main` has moved ahead of a PR branch you're working on, **merge
`main` into the PR branch** before the next push or review trigger. Don't
wait for a conflict to surface or for the user to ask.

Check before pushing:

```bash
git fetch origin main
git log --oneline ..origin/main | head    # any commits? main is ahead — merge it in
git merge origin/main
```

Always do this before triggering a fresh `@claude review`, so the reviewer
evaluates the PR against current `main` rather than a stale snapshot. (Another
instance of **never assume; always verify** — `git fetch` to check main's
actual position instead of assuming the branch is current.)

Don't rebase or squash-rewrite a published PR branch unless explicitly
asked — a merge commit is the right move because it matches GitHub's "Update
branch" button and preserves the PR history.

If the merge has conflicts, resolve them, run the project's standard
pre-commit checks (render / lint / spell / tests), commit, then push. Don't
push a half-resolved merge.

## Coding style: avoid nesting; follow the lab manual

Follow the SERG lab manual (https://ucd-serg.github.io/lab-manual/) for coding
and collaboration conventions.

When writing code, **avoid nested function calls and nested function
definitions where feasible**:

- Prefer named intermediate variables (or a pipe, e.g. `|>` / `%>%` in R) over
  deeply nested calls like `f(g(h(x)))`. Naming each step makes the data flow
  read top-to-bottom and leaves intermediate values inspectable in a debugger.
- Prefer standalone, top-level function definitions over functions defined
  inside other functions. Nested definitions hide reusable logic, complicate
  unit testing, and obscure scope.

This is a readability/maintainability default, not an absolute rule — keep the
nesting when flattening it would be more convoluted (a trivial one-argument
wrapper, or a closure that genuinely needs the enclosing scope).

## Writing style: plain, direct prose

Write user-facing prose in a plain, direct style. This applies to everything I
read — PR/issue/commit text, docs, READMEs, code comments, release notes,
emails, and chat replies. Apply it by default to your own drafts, not just when
asked.

The guide of record is my **Principles of Scientific Writing (PSW)**:
https://d-morrison.github.io/psw/. The rules below operationalize it. When PSW
and this section disagree, PSW wins.

- **Limit dependent (subordinate) clauses.** One per sentence is plenty. When
  two or more stack up, split the sentence.
- **Cut low-content filler and jargon.** Delete words that add no information
  ("it's worth noting", "in order to" → "to", "due to the fact that" →
  "because").
- **Prefer plain (Anglish) words over Latin-derived ones** (PSW, "Word choice").
  "before", not "prior to"; "needed", not "necessary"; "use", not "utilize". A
  heuristic, not a purity rule.
- **Prefer simple declarative sentences and active voice.** Subject, verb,
  point. Name the actor, then the action.
- **Join independent clauses with coordinating conjunctions** (and, but, so, or)
  over subordinate constructions. Prefer "X is fast, but Y is correct" over
  "While X is fast, Y is correct."

This is a default, not an absolute rule. Keep a clause or a technical term when
removing it would lose meaning or precision. Never trade an honest hedge for
false confidence. The `use-preferred-style` skill (alias `style`) spells out the
procedure, the PSW chapter links, and a filler/jargon swap table; the
`find-ai-tells` skill (not yet built — issue #49) is the planned scan-after
detector counterpart.
