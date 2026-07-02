# Changelog

Notable changes to `d-morrison/ai-config` are documented here.

This repo has no `version` tag — every commit counts as a new version, and
sessions with marketplace auto-update pick up the latest automatically (see
`README.md`, "Use these skills"). This changelog is a running, reverse-
chronological log of notable additions and changes for humans skimming
history, not a release log — add an entry for anything a user or another
session would want to know about (a new skill, agent, or shared policy; a
behavior change to an existing one), not every mechanical edit.

## Unreleased

- **Backtick command-substitution gotcha in `-m`/`--body` strings**
  (`memories/tools.md`, #306). New bullet: backticks inside a double-quoted
  `git commit -m`/`gh ... --body` string get command-substituted by the
  shell, silently mangling the message --- use a single-quoted heredoc or
  `--body-file` instead. Corrects the `gh pr comment` example to use
  `--body`, since that subcommand has no `-m` flag.
- **Session-freshness standing rule** (`CLAUDE.md`, #368). New section "Keep
  ai-config and repo checkouts fresh": in every session, at start and
  periodically during long ones, (a) put the local ai-config checkout back on
  `main` (not a leftover work branch) and `git pull --ff-only`; (b) refresh
  the `~/.claude` consumer copies afterward --- the pull alone suffices only
  where the children are real symlinks; on Windows, Git Bash `ln -s` falls
  back to real copies, so changed files must be copy-synced, after
  reconciling any un-upstreamed local edits; (c) fast-forward the `main`
  checkout of whatever repo the session is working on.
- **Windows TZ caveat upstreamed into the timestamp rule** (`CLAUDE.md`,
  #368). On Windows Git Bash, `TZ=America/Los_Angeles date` silently falls
  back to GMT; check the `%Z` suffix and use PowerShell's
  `ConvertTimeBySystemTimeZoneId` when it isn't PDT/PST. Reconciled from an
  edit made directly in `~/.claude/CLAUDE.md` that had never reached the
  repo.
- **`skill-builder` / `sync-with-main`: hallucination and merge-overlap
  lessons from #349.** `skill-builder` now calls out grep-verifying any
  `CLAUDE.md`/`shared/` citation or claimed "existing scale" before writing
  it into new skill prose --- the same discipline `purge-hallucinations`
  applies to other authors' text applies to your own new content too.
  `sync-with-main` now notes that a textual conflict inside a skill's
  `## Relationship to other skills` section can signal a conceptual
  duplicate landed on `main` while the branch was in flight, not just a
  line collision --- worth re-running `skill-builder`'s Step 0 judgment at
  merge time, not only at branch start.
- **`check-history` skill.** New bullet: on a long-lived or foundational
  issue, the issue text and any design-doc status header can lag the code by
  several PRs, so a mature feature may be partly or mostly implemented even
  when the issue reads as unstarted. Verify the actual implementation state
  against the code (key source files, tests) before scoping new work,
  and scope only the genuine remaining slice when the issue is partly done.
  Caught on sparta #164/#240 (nearly rebuilt already-completed work).
- **`skill-builder` now requires re-deriving `skills.qmd`'s skill count from
  the actual `skills/` directory** instead of a manual +1, and flags the gap
  as an anti-pattern alongside the existing tool-mappings.yml registration
  check. New standing preference: invoke `skill-builder` itself when creating
  a skill rather than hand-authoring `SKILL.md` (#360, lessons from #347).
- **`skill-builder` / `sync-with-main` policy refinements** (#371). New
  authoring conventions from PR #359's review lifecycle: every procedural
  step needs a runnable command, not just prose, especially a
  destructive/history-rewriting step that already requires explicit user
  approval; a cross-skill claim ("skill X detects Y via Z") must be verified
  against that skill's actual mechanics before writing it. Also: a CI failure
  on a fresh empty-commit draft PR is a signal to check `main`'s position
  before debugging the failure itself --- a stale local checkout can surface
  failures that are really just "main moved."
- **`memories/tools.md`: watch for the bot's `Claude finished` marker** (#367).
  A watcher polling for the @claude bot's verdict must match the completion
  marker (`**Claude finished`), not the absence of an in-progress placeholder
  --- placeholder wording varies between runs, so exclusion filters fire early.
- **Squash-merge branch-reuse gotcha documented in `CLAUDE.md`** (#361).
  Reusing a harness-assigned branch name for follow-up work after its own PR
  squash-merged breaks git ancestry, so pushing more commits on top shows the
  entire prior PR's diff again. Records the check-before-push
  (`git merge-base --is-ancestor`) and rebuild-with-cherry-pick fix.

- **`mwc` skill (aliases `merge-when-confident`, `maw`, `merge-at-will`).**
  New session-scoped exception to the standing "merge is human-gated" rule:
  when the user explicitly grants it, I may squash-merge any PR I'm driving
  once it reaches fully clean, without asking per PR, for the rest of that
  session. The grant is session-scoped by design, not written to
  `preferences.md` — it's requested fresh each time, not a silent default.
  `shared/workflow/ardi.md` cross-links it as the one case where baking a
  self-merge step into a `ScheduleWakeup`/`/loop` prompt is safe.
- **`configure-gitattributes` skill** (#364). New skill for configuring or
  auditing a repo's `.gitattributes`: union-merge for changelog/news files
  that almost always want both sides kept on conflict, line-ending
  normalization for shell scripts, `linguist-generated`/`linguist-vendored`
  for generated and vendored trees (including R package `NAMESPACE`/`.Rd`
  files regenerated by roxygen2), and binary-file handling.
- **`stack-prs` skill** (#358). Branch new work off an existing, unmerged
  PR's tip instead of `main`, open the dependent PR with `base` set to that
  PR's branch, keep it in sync as the base branch moves, and re-target it to
  `main` once the base merges. The general-purpose, directly-invocable
  counterpart to the stacking logic that `ardia`, `gii`/`gia`, and
  `stack-dont-pause` each already do as a side effect of their own loops.
- **`check-info-quality` skill (alias `ciq`)** (#349). New detector skill:
  three checks for information-quality problems neither `purge-hallucinations`
  nor `find-ai-tells` catches --- out-of-date claims (check A), irrelevant
  content (check B), and misleading/out-of-context claims including
  citation-claim mismatches (check C). Cross-linked with `purge-hallucinations`,
  `find-ai-tells`, `fact-check-prose`, and `shared/writing/citations.md`.
- **`sync-with-main` / `address-every-comment` policy refinements.** Re-check
  `main` again right before the final push (conflict resolution can take long
  enough for `main` to advance a second time); when a review nit is a pattern
  broken in one spot, fix every recurrence in the same file in one pass
  instead of letting the reviewer flag each occurrence separately. Lessons
  from PR #353's review lifecycle.
- **`wrap-up` skill: closing-signal guidance.** Step 4 now spells out how the
  final reply should end: an explicit "this session is at a good stopping
  point" (or similar) when nothing is waiting on the user, or --- when
  something is open (an ambiguous item, a deadlock, a choice only the user
  can make) --- the open question(s) last and clearly visible, rather than
  burying them earlier in a long recap, so the last thing the user reads is
  the open question, not a trailing summary.
- **Growth-mindset shared policy** (`shared/workflow/growth-mindset.md`, #353).
  New standing rule: treat a current limitation (missing tool, manual
  workaround, insufficient model) as a starting point to resolve — via
  packages, upstream fixes, better tooling, asking the user directly, or
  extending the skill/memory corpus itself — rather than a fixed ceiling to
  route around indefinitely. Growth is disciplined, not unchecked: prune and
  consolidate as readily as adding.
- **`fact-check-prose` skill (alias `fcp`) and `prose-fact-checker` agent**
  (#344). New standing policy (`shared/writing/fact-check-prose.md`): when
  reviewing prose, check factual claims against domain knowledge and external
  sources, verify document-internal reasoning (formal mathematical
  derivations/proofs and informal arguments) step by step, cross-check
  computed values/figures against rendered output (a PR-preview site or
  `gh-pages` branch), and proactively suggest additional citations. The skill
  operationalizes this standalone or as part of a review pass; the read-only
  agent fans claim verification out across a `Workflow`.
