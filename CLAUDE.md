# User-wide Claude Code instructions

<!--
Some sections below pull their body from a fragment in `shared/` via Claude
Code's `@path` import (e.g. `@shared/writing/plain-prose.md`). Those fragments
are the single source of truth for guidance shared with the UCD-SERG lab manual,
which transcludes the same files. Edit the fragment, not the inlined copy, and
keep fragments ASCII (write `---` for em-dashes) so the manual's character check
passes. See README.md, "Shared content".
-->

## Run UMS before /clear

When the user says "clear", "/clear", or otherwise asks to reset the
conversation, **first** run the `ums` (Update Memories and Skills) procedure
to capture any accumulated learnings before context is lost. Then proceed
with the clear.

## Timestamp recaps in local time

When printing a status recap or summary, include a timestamp in the user's
local time zone (Pacific Time, `America/Los_Angeles` — get it from
`TZ=America/Los_Angeles date "+%Y-%m-%d %H:%M %Z"`; the explicit `TZ` enforces
PT on a machine set to any other zone). This makes "as of when" unambiguous when
the user reads the recap later.

## Bare queue-command keywords

I maintain a family of slash skills for managing the task queue and amending
requests: `/also`, `/first`, `/next`, `/before`, `/last`, `/and`, `/remember`,
and `/always`. When I write one of these keywords **without the leading slash**
as a directive — e.g. "also fix the test", "remember that ...", "always link
PRs in tables", "and bold it", "next, run the spellcheck", "first, revert
that" — interpret it using the corresponding skill's semantics rather than as
ordinary prose. (`/remember` and `/always` both route to the `memorize` skill.)
When the word is genuinely just part of a sentence (ambiguous), fall back to
the plain reading.

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

## Post in-chat feedback to the PR

When the user gives feedback, corrections, or guidance in the CLI or chat
while working a PR, paraphrase it and post it as a PR comment:

```
gh pr comment <N> --body "..."
```

One to three sentences is enough. Don't quote verbatim — paraphrase so it
reads naturally in the PR thread. Skip trivial acknowledgments or
conversational exchanges with nothing to act on.

This makes context visible to future @claude sessions, other reviewers, and
contributors who only see the PR thread.

## Claim a GitHub PR/issue before working on it

<!-- Shared with the lab manual; edit shared/workflow/claim-pr.md, not here. -->
@shared/workflow/claim-pr.md

The `claim-pr` skill operationalizes this (the exact claim wording, when it
applies, and the closing/unclaim comment).

## File an issue before starting a new task

<!-- Shared with the lab manual; edit shared/workflow/issue-first.md, not here. -->
@shared/workflow/issue-first.md

The `st` (Start Task) skill operationalizes this; `gi` (Grab Issue) is the path
when the issue already exists.

## Tracking issues in upstream repos

<!-- Shared with the lab manual; edit shared/workflow/upstream-issues.md, not here. -->
@shared/workflow/upstream-issues.md

The `sup` / `send-upstream` skill operationalizes steps 1--2 (the PR path, including fork-if-needed, and the issue path) and the link-back. Step 3 (own-repo fallback) is not covered by `sup`; use `gh issue create` in the current repo and ask the user to transfer it.

## Wrap up a merged PR with UMS

When a PR/MR you were working on **merges**, run the `post-merge` skill:
verify the merge actually landed, tidy the local branch (checkout `main`,
pull, `git branch -d`), confirm any deferred items have follow-up issues, then
run **UMS** to capture what the PR's review lifecycle taught — recurring review
findings, corrections, and guidance given along the way. A merge is the natural
checkpoint to bank lessons before the context is lost.

"merge it" / "merge this" / "merge the PR" as bare directives (no slash) trigger
the `merge-it` skill: when the PR isn't merged yet, it merges the ready PR
(squash by default) **then** chains straight into `post-merge` (tidy + UMS); when
the PR is already merged it goes directly to `post-merge`. Either way the
post-merge wrap-up — including the UMS follow-up PR — runs **automatically,
without asking**. If the phrase is clearly part of ordinary prose rather than a
standalone directive, treat it as such.

## What "fully clean" means

<!-- Shared with the lab manual; edit shared/workflow/fully-clean.md, not here. -->
@shared/workflow/fully-clean.md

Escalate a deadlock via the `request-pr-review` skill (human reviewer
`d-morrison`, or `gh pr edit <N> --add-reviewer d-morrison`), and surface the
open item to me.

## Always run ARDI on PRs you touch

<!-- Shared with the lab manual; edit shared/workflow/ardi.md, not here. -->
@shared/workflow/ardi.md

The `ardi` / `iterate` skill family runs this loop. (See *What "fully clean"
means* above; the mechanics for each step are in the sections around here.)

## Watch and ARDI every PR you touch — don't ask first

When you open (or are handed) a PR/MR in **any** repo, subscribe to its activity
and run the ARDI loop to clean **automatically** — never ask "should I watch
this?" or "should I iterate it?" first. That answer is a standing yes across all
PRs and all repos. Subscribe with the `subscribe_pr_activity` tool (provided by
the GitHub MCP server in remote/web sessions) or babysit locally, drive every
review round to fully-clean, and re-arm a periodic check-in since webhooks don't
deliver CI-success or merge-conflict transitions.

Surface to me only when an item is ambiguous, architecturally significant, or
deadlocked (the escalation rule above still applies), or when the PR is clean.
Stop watching only when the PR merges or closes, or I tell you to back off.

## Address every in-scope review comment, even non-blockers

<!-- Shared with the lab manual; edit shared/workflow/address-every-comment.md, not here. -->
@shared/workflow/address-every-comment.md

If you and the reviewer reach an impasse on a single item (your rebuttal didn't
convince them and their re-raise didn't convince you), escalate that item to a
**human reviewer** — request `d-morrison` via the `request-pr-review` skill (or
`gh pr edit <N> --add-reviewer d-morrison`) and `@`-mention them with the
impasse — for the final call rather than looping.

## Keep PR branches synced with main

<!-- Shared with the lab manual; edit shared/workflow/sync-with-main.md, not here. -->
@shared/workflow/sync-with-main.md

(Another instance of **never assume; always verify** — `git fetch` to check
main's actual position instead of assuming the branch is current. The
`sync-pr-branch` / `merge-main` skill runs this.)

## Coding style: avoid nesting; follow the lab manual

Follow the SERG lab manual (https://ucd-serg.github.io/lab-manual/) for coding
and collaboration conventions.

<!-- Shared with the lab manual; edit shared/coding/avoid-nesting.md, not here. -->
@shared/coding/avoid-nesting.md

## Writing style: plain, direct prose

<!-- Shared with the lab manual; edit shared/writing/plain-prose.md, not here. -->
@shared/writing/plain-prose.md

The `use-preferred-style` skill (alias `style`) spells out the procedure, the
PSW chapter links, and a filler/jargon swap table; the `find-ai-tells` skill
(alias `ai-tells`) is the scan-after detector counterpart.

## Writing style: line breaks in .qmd prose

When editing existing `.qmd` prose, preserve the original line breaks exactly —
don't reflow to single long lines or a different wrap width. When writing new
`.qmd` prose, add line breaks at major phrase and sentence boundaries (one
`.qmd` prose, break at sentence boundaries; one clause per line works well.

## Writing style: scan for AI tells

The detector counterpart to the plain-prose guide above.

<!-- Shared with the lab manual; edit shared/writing/ai-tells.md, not here. -->
@shared/writing/ai-tells.md

The `find-ai-tells` skill (alias `ai-tells`) runs this same catalog on demand
against any target text.

## Useful prompt formats for coding agents

<!-- Vendored from UCD-SERG/lab-manual; edit there, not here. See README, "Shared content". -->
@shared/vendored/prompt-formats.md

## Review with Copilot before requesting human review

This is shared lab guidance on getting an automated review before asking a human
reviewer. When *I* iterate a PR, the ARDI loop above is the mechanism — it
already addresses whatever the `@claude` or Copilot reviewer flags — so read this
as the lab-member-facing statement of the same principle, not a second loop to
run.

<!-- Vendored from UCD-SERG/lab-manual; edit there, not here. See README, "Shared content". -->
@shared/vendored/copilot-review-before-human.md
