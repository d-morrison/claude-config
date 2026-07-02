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

- **`stack-prs` skill** (#358). Branch new work off an existing, unmerged
  PR's tip instead of `main`, open the dependent PR with `base` set to that
  PR's branch, keep it in sync as the base branch moves, and re-target it to
  `main` once the base merges. The general-purpose, directly-invocable
  counterpart to the stacking logic that `ardia`, `gii`/`gia`, and
  `stack-dont-pause` each already do as a side effect of their own loops.
- **`fact-check-prose` skill (alias `fcp`) and `prose-fact-checker` agent**
  (#344). New standing policy (`shared/writing/fact-check-prose.md`): when
  reviewing prose, check factual claims against domain knowledge and external
  sources, verify document-internal reasoning (formal mathematical
  derivations/proofs and informal arguments) step by step, cross-check
  computed values/figures against rendered output (a PR-preview site or
  `gh-pages` branch), and proactively suggest additional citations. The skill
  operationalizes this standalone or as part of a review pass; the read-only
  agent fans claim verification out across a `Workflow`.
