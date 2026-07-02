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

- **`skill-builder` now requires re-deriving `skills.qmd`'s skill count from
  the actual `skills/` directory** instead of a manual +1, and flags the gap
  as an anti-pattern alongside the existing tool-mappings.yml registration
  check. New standing preference: invoke `skill-builder` itself when creating
  a skill rather than hand-authoring `SKILL.md` (#360, lessons from #347).
- **`fact-check-prose` skill (alias `fcp`) and `prose-fact-checker` agent**
  (#344). New standing policy (`shared/writing/fact-check-prose.md`): when
  reviewing prose, check factual claims against domain knowledge and external
  sources, verify document-internal reasoning (formal mathematical
  derivations/proofs and informal arguments) step by step, cross-check
  computed values/figures against rendered output (a PR-preview site or
  `gh-pages` branch), and proactively suggest additional citations. The skill
  operationalizes this standalone or as part of a review pass; the read-only
  agent fans claim verification out across a `Workflow`.
