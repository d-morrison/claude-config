# Repo notes: UCD-SERG/lab-manual

A Quarto book — the lab's style/workflow guide. When editing `.qmd` prose, the
`@claude` and Copilot reviewers reliably flag these (learned driving PR #335):

- **Semantic line breaks (sembr).** The repo follows sembr — documented in
  `.github/copilot-instructions.md` and `coding-style/line-breaks.qmd`. Wrap each
  sentence (and long clauses) onto its own source line; don't write long
  one-line paragraphs. A soft line break inside a paragraph/bullet renders as a
  space, so this is purely a source-formatting convention.
- **Em-dash house style:** `---` with NO surrounding spaces (e.g.
  `compose them---don't`), not ` --- `.
- **US spelling:** e.g. "acknowledgment", not "acknowledgement".
- **Lists:** leave a blank line before a markdown bullet list; use a bullet list
  for 3+ items. Use markdown links, never raw HTML, in `.qmd`.
- New technical terms go in the spell-check wordlist (see
  `.github/workflows/check-spelling*`), not by disabling the check.

CI on a PR: `build-deploy` (full Quarto render), `Spellcheck`, `link-checker`,
`lint-project`, `check-dois`, `check-chars`, plus `claude-review`. A full-book
render can fail locally on an unpopulated submodule include
(`.ai-config/shared/...`) that CI has — render the single edited page locally and
rely on CI for the full build.
