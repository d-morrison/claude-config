---
name: bcs-gotchas
description: "Operational gotchas and codebase conventions for ucdavis/bcs"
metadata:
  type: feedback
---

# bcs — working notes

## Person-time builder tests: use constructed fixtures, not simulate_data()

`build_advanced_cancer_person_time()` and `build_bc_death_person_time()` should be
tested with a constructed fixture, not `simulate_data(n = 50, seed = ...)`. Rare events
like `event_bc_death` never fire in an n = 50 simulation, leaving branches silently
uncovered.

The canonical fixture (`tests/testthat/helper-person_time_fixture.R`) covers:

| id | arm | event coverage |
|---|---|---|
| 1 | annual | `event_advanced_cancer = 1`, `event_bc_death = 1` |
| 2 | biennial | `event_other_death = 1` (competing event) |
| 3 | annual | censored at admin cap (no events) |

**Key person-time arithmetic** (for designing fixture rows):
- Admin cap: `round(max_months * 30.44)` days
- Follow-up months: `as.numeric(time_end - time_start) / 30.44`
- Event fires at: `floor(follow_up_months)`
- 180 days → `180 / 30.44 = 5.91` months → event at month 5 (6 rows total)
- 365 days, max_months = 24 → `365 / 30.44 = 11.99` months → event at month 11 (12 rows)

**Use day counts, not rounded months, in fixture comments.** A comment saying
"other-cause death at 6 months" is wrong when the value is `base_date + 180L`
(180 days = 5.91 months → exits at month 5). Write "180 days (exits at month 5
in person-time)" — the day count is the source of truth.

## Identical snapshots: add an explanatory comment

`event_bc_death` and `event_other_death` both dispatch to `build_bc_death_person_time()`,
so their snapshots are byte-for-byte identical. Without a comment the reviewer flags this.
Always note it in the test:

```r
# "event_other_death" dispatches to build_bc_death_person_time(), the same
# function as "event_bc_death", so this snapshot is intentionally identical
# to build_outcome_person_time_bc_death.csv.
```

## Add explicit event assertions alongside snapshot tests

When a snapshot covers a rare event, add an `expect_true()` before the snapshot so the
test fails fast if the event stops firing:

```r
expect_true(any(result$event_bc_death == 1L))
snapr::expect_snapshot_data(result, name = "...")
```

## snapr and NOT_CRAN in cloud sessions

`snapr` is not on CRAN or P3M. Install from the GitHub tarball:

```bash
curl -L https://codeload.github.com/d-morrison/snapr/tar.gz/refs/heads/main \
     -o /tmp/snapr.tar.gz
```

then in R:

```r
install.packages("readr")   # snapr dependency
install.packages("/tmp/snapr.tar.gz", repos = NULL, type = "source")
```

`snapr::expect_snapshot_data()` silently skips snapshot generation and comparison when
`NOT_CRAN` is unset (respects the standard CRAN-skip convention):

```bash
NOT_CRAN=true Rscript -e 'devtools::test()'
```

or `Sys.setenv(NOT_CRAN = "true")` in an interactive session.

## renv activation failure (blocked GitHub remote)

`bcs` lists `d-morrison/altdoc@recursive-qmd-search` as a GitHub `Remotes:` entry.
The cloud proxy blocks GitHub API calls, so renv activation (via `.Rprofile`) fails on
startup with an unresolvable remote error. Every subsequent `R` call aborts before
loading any package.

Bypass by skipping `.Rprofile` and renv entirely:

```bash
R --no-save --no-restore --no-site-file --no-init-file -e '
  options(repos = "https://packagemanager.posit.co/cran/__linux__/noble/latest")
  install.packages(c("devtools", "testthat", ...))
  devtools::load_all()
  devtools::test()
'
```

This installs into the user library (not the renv cache), which is fine for one-off
cloud sessions.
