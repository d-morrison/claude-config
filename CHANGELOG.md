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
