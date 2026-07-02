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

- **`memories/tools.md`: watch for the bot's `Claude finished` marker** (#367).
  A watcher polling for the @claude bot's verdict must match the completion
  marker (`**Claude finished`), not the absence of an in-progress placeholder
  --- placeholder wording varies between runs, so exclusion filters fire early.
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
