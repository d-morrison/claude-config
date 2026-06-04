---
name: plan-review-session
description: Turn a catalog of common student errors into review-session teaching material — typically a new chapter in the rme Quarto book (mistake callout + worked solution per error) — and open a PR. Use after grade-work, or when asked to "plan a review session", "make a review chapter from these mistakes", or "build review material for the midterm".
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# plan-review-session

Convert a ranked list of common mistakes (e.g. from **grade-work**) into a
review session: a self-contained chapter that, for each common error, pairs a
*"common mistake"* callout with a worked correction, ordered most-impactful
first.

**Origin:** built from the Epi 204 Midterm 2 review chapter added to
d-morrison/rme (PR #881), which distilled grading findings into a
`chapters/midterm-2-review-session.qmd`.

## When to use

- You have a common-errors catalog and want classroom/handout material.
- The target is usually the `rme` book (Quarto), but the structure transfers to
  any Quarto/Markdown course site.

## Content structure

Per error category, in this order:

1. A descriptive `##` heading that states the *correct* principle (not the
   mistake) — e.g. "Nelson-Aalen estimates the cumulative hazard first, then
   exponentiates".
2. A `::: {.callout-warning}` block with a `## Common mistake` sub-heading
   describing what students did wrong (anonymized — patterns, never names).
3. A `::: {.solution}` block working through the correct approach with concrete
   numbers, reproducible R where it helps.

Order categories by **frequency × consequence**; lead each part with its most
consequential error. Close with a summary table cross-linking each mistake to
its section (`@sec-...`).

## rme conventions (the target book)

Match the existing chapters — read one first (e.g.
`chapters/proportional-hazards-models.qmd`) before writing.

- **Header:** front-matter with `title:` and the `html`/`revealjs`/`pdf`/`docx`
  format block, then `{{< include shared-config.qmd >}}` (this pulls in
  `r-config.qmd` and the LaTeX macros).
- **Math macros:** use the project macros from `latex-macros/macros.qmd`
  instead of raw LaTeX — `\surv`, `\haz`, `\cumhaz`, `\loghaz`, `\Lik`,
  `\hr`, `\V`, `\Covt`, `\eqdef`, `\indpt`, `\diff`, `\vx`, `\vb`, etc. Note
  argument arity: `\Cov{...}` wraps its arg in parens, so for hand-written
  parens use the bare operator `\Covt`.
- **Tables/figures:** use div form `::: {#tbl-...}` / `::: {#fig-...}` with the
  caption as the last line inside the div — *not* chunk-option `tbl-cap`.
- **Code chunks:** default `#| code-fold: true` for figure/table chunks; keep R
  simple and runnable (the `survival` + `dplyr` KM/NA recipe and base-R Wald
  test from the origin chapter are good templates).
- **Don't** start an included subfile with a heading; one source line per major
  phrase keeps diffs readable.

## Wiring a new chapter in (three places)

1. `_quarto-book.yml` — add `- chapters/<name>.qmd` under the right part.
2. `_quarto-website.yml` — add it to the `project: render:` list **and** to the
   `website: navbar:` Chapters menu.
3. Keep the chapter out of nowhere-else; a chapter not in the render list won't
   build on the site.

## Pre-commit checks (mandatory in rme)

Run all three and fix what your change caused:

```sh
quarto render chapters/<name>.qmd --to html      # no errors/warnings
Rscript -e 'lintr::lint("chapters/<name>.qmd")'  # no lints in your code
Rscript -e 'res <- spelling::spell_check_files("chapters/<name>.qmd", ignore = readLines("inst/WORDLIST")); print(res)'
```

- Confirm the render has no unresolved cross-refs (grep the output HTML for
  `?@`) and that tables/computed values resolved.
- **Spellcheck gotcha:** local `spell_check_files` on `.qmd` does *not* strip
  in-math content, so it false-flags LaTeX macro tokens (`haz`, `cumhaz`,
  `loghaz`, `Covt`, `mathbf`, `tfrac`, `ge`, …). CI (clean container) does not
  flag these — verified by existing survival subfiles that "leak" the same
  tokens locally yet keep `main` green. So **only add genuine prose words** to
  `inst/WORDLIST` (e.g. `exponentiate`); do not pollute it with math macros.

## PR

- Branch off `origin/main` (`git checkout -b <name> origin/main`); never commit
  to `main` directly.
- Stage only your files — the working tree may carry unrelated dirty files
  (e.g. CRLF-only diffs); don't sweep them in with `git add -A`.
- Commit message ends with the Co-Authored-By line; PR body ends with the
  Generated-with-Claude line.
- After `gh pr create`, request `d-morrison` as reviewer (see
  **request-pr-review**).
- Keep all commit/PR/issue text **anonymized** — no student names.

## Related

- **grade-work** — produces the ranked error catalog this skill consumes.
- **request-pr-review**, **r-pkg-spellcheck**, **sync-pr-branch** — the
  PR-hygiene skills this leans on.
