---
name: bcs-gotchas
description: "Operational gotchas and conventions for ucdavis/bcs (breast-cancer-screening R package, UCD-SERG)"
metadata:
  type: feedback
---

# bcs — working notes

## `version-check` requires the branch DESCRIPTION version > main's

The `version-check` CI job fails unless the branch's `DESCRIPTION` `Version:`
field is strictly greater than `main`'s. The dev version is a long
`0.0.0.9xxx` string — bump the last component on every PR. **`main` moves while
your PR is open** (other PRs merge and bump it too), so a version that passed
yesterday can go stale: re-check `main`'s current version and re-bump if
`version-check` flips red. On #264 this forced three successive bumps
(9064 → 9065 → 9066).

## Simulation validation: snapshot + warning gotchas

The ETT/MSM validation suite is snapshot-heavy (snapr `expect_snapshot_data`)
and runs small-n Monte Carlo fits that emit benign warnings. The general
mechanics — `NOT_CRAN=true` to un-skip snapr, per-file regen to avoid pruning
`_snaps/`, sequential-then-copy for `furrr` snapshots, and the
`stop_on_warning = TRUE` capture-the-real-warning trick — live in
`memories/debugging.md` ("R snapshot tests (snapr / testthat)"). bcs-specific:

- Small-n fits emit three expected warnings — `stats::glm()` "fitted
  probabilities numerically 0 or 1 occurred" and "algorithm did not converge",
  plus a `cli::cli_warn("risk ratio is undefined")` from a zero-risk group.
  `suppress_small_sample_warnings()` (in `R/`) muffles all three in the source
  path; the test helper `without_separation_warning()` muffles the same set.
  (The helper's name predates the broadening — despite "separation" it now
  covers all three patterns, not just GLM separation. Defined in
  `tests/testthat/helper-muffle_separation_warning.R`.)
  Add new patterns to BOTH if a fit starts emitting something else.
- Committed `inst/extdata/*-validation*.rds` are a **reduced-scale** refresh
  (smaller N, fewer reps) with the **MSM bootstrap off** (`msm_n_boot = 0`), so
  MSM coverage reads `NA` in the committed artifacts; ETT coverage is populated
  (closed-form delta-method). Full-scale numbers come from
  `data-raw/precompute-*-validation.R` / the SLURM path with `msm_n_boot > 0` on
  HPC. Don't "fix" the NA MSM coverage locally — it's expected without HPC.

## Repo conventions worth remembering

- `cli::cli_abort()` / `cli::cli_warn()` / `cli::cli_inform()` — never `stop()` /
  `warning()` / `message()`. Native `|>` pipe, not `%>%`. `::` everywhere in
  `R/` (no `library()`). One top-level function per file, filename = function.
- No issue numbers in source code — reference issues only in `NEWS.md` / the PR.
- `Check Changelog` CI job requires a `NEWS.md` entry on every PR.
