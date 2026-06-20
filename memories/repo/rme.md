# rme / Epi 204 (UC Davis) — working notes

## Project map
- `d-morrison/rme` (public) = the **"Regression Models for Epidemiology"** Quarto book = the **Epi 204** lecture notes (site: <https://d-morrison.github.io/rme/>; subject metadata "Epidemiology 204"). Course = "Quantitative Epidemiology III: Statistical Models" (GLMs: linear/logistic/Poisson; survival: KM/NA/Cox; appendices = prereqs).
- `ucdavis/epi204` (private) = the course R package (hw/solutions). It includes `rme` and `macros` / `latex-macros` as **git submodules**.
- `_quarto-book.yml` = book TOC (PDF profile); `_quarto-website.yml` = default **website** profile (navbar + explicit `render:` list). New pages must be wired into **both**. `_quarto.yml` sets `profile: default: website`.

## Canonical source = GitHub, NOT OneDrive
- The user's OneDrive course copies (`…/OneDrive…/Teaching/Epi 204/epi204`) are often **online-only stubs**: reading them locally returns **all null bytes** (even `.git`). Don't parse them — pull content from GitHub (`gh api repos/.../contents/...` or a fresh clone).

## Parallel sessions — always isolate
- The `~/Documents/GitHub/rme` checkout is used by **multiple concurrent agent sessions** (its branch switches under you; commits land on PR branches from other sessions / the `@claude` bot). The `ai-config` repo, too, often has another session's uncommitted edits — never `git add -A`.
- Work in an **isolated `git worktree` off `origin/main`** (`git worktree add -b <branch> /tmp/<dir> origin/main`); `git submodule update --init`; `renv::restore()` is fast from the shared cache; render a single chapter with `quarto render chapters/<x>.qmd --to html`.
- Before pushing a PR branch, **fetch + reconcile `origin/<branch>`** — another session may have already pushed the same change (saw both local & remote independently merge `main` into the same PR branch).

## CI: preview-deploy "green but nothing happens" gotcha (fixed in PR #913)
- Symptom: preview **build** green + `pr-preview-site` artifact uploaded, yet `pr-preview/pr-N/` never publishes and **all checks stay green**.
- Cause: a step that created files **before `actions/checkout`** had them wiped by checkout's default `clean: true` (`git clean -ffdx`), so the metadata never reached the artifact; the deploy's `if: …outputs.action == 'deploy'` was silently false. `pr_number=$(cat missing)` inside `echo` → empty output + exit 0, so the step "passed."
- **General lesson:** when CI is green but an expected side-effect (deploy/comment/output) didn't happen, **read the run logs**, not just the check status; suspect a guard that evaluated false on empty/missing inputs. (Download the artifact to see what actually shipped.)
- Preview URL: `https://d-morrison.github.io/rme/pr-preview/pr-<N>/`, deployed by `rossjrw/pr-preview-action` to the `gh-pages` branch. A PR's preview build uses the `preview.yml` from the **PR head branch**, so an open PR needs `main` merged in to pick up a workflow fix.

## rme conventions (reviewer-enforced; also in repo CLAUDE.md)
- Tables: `:::{#tbl-…}` fenced-div + caption as the last line, **not** `#| tbl-cap:`.
- Figure/table chunks: `#| code-fold: true` (not `echo: false`).
- Utility/content pages don't need a `revealjs` output; link text must match its destination.
- `.github`/CI changes go in their **own** PR, never mixed with book-content PRs.

## GGE PQE study-topics doc (`GGE-WrittenExam-StudyTopics_<year>.docx`)
- It's the biostat portion of the Graduate Group in Epidemiology written pre-qualifying exam; the Biostatistics section maps to EPI 202/203/**204** (204 = the regression + survival modeling part).
- Edit **against what's actually taught that year** per the syllabus/schedule, not the whole book. (2026 omitted: parametric survival/AFT, multilevel models, predictor-selection detail, tied-event-times handling, competing risks, left-truncation, IRLS.)
- **Consolidate** new points into the existing related bullets rather than adding near-duplicate bullets; don't restate content already in the list.
- Match the course's notation (2026 used hazard **λ(t)** / cumulative hazard **Λ(t)**, not h/H).
- Author tracked changes as **"Douglas Ezra Morrison"** (the file circulates to the GGE committee), not "Claude".
- When converting course docs into the **public** rme site, **redact secrets** — Posit Cloud `access_code=` join links, instructor-only SharePoint links.
