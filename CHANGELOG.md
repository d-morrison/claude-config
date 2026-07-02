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

- **Squash-merge branch-reuse gotcha documented in `CLAUDE.md`** (#361).
  Reusing a harness-assigned branch name for follow-up work after its own PR
  squash-merged breaks git ancestry, so pushing more commits on top shows the
  entire prior PR's diff again. Records the check-before-push
  (`git merge-base --is-ancestor`) and rebuild-with-cherry-pick fix.

- **`fact-check-prose` skill (alias `fcp`) and `prose-fact-checker` agent**
  (#344). New standing policy (`shared/writing/fact-check-prose.md`): when
  reviewing prose, check factual claims against domain knowledge and external
  sources, verify document-internal reasoning (formal mathematical
  derivations/proofs and informal arguments) step by step, cross-check
  computed values/figures against rendered output (a PR-preview site or
  `gh-pages` branch), and proactively suggest additional citations. The skill
  operationalizes this standalone or as part of a review pass; the read-only
  agent fans claim verification out across a `Workflow`.
