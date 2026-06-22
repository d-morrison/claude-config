# Repo notes: d-morrison/rpt (UCD-SERG R-package template)

- **changelog + version checks trigger on non-workflow `.github/` edits.**
  `news.yaml` (changelog-check) and `version-check.yaml` only `paths-ignore`
  `.github/workflows/**` (version-check also ignores `vignettes/**`). So editing
  `.github/copilot-instructions.md` — or any other non-workflow file — makes
  **both** run. Such a PR then needs a `NEWS.md` bullet AND a DESCRIPTION
  dev-version bump (e.g. `0.0.0.9021` -> `0.0.0.9022`), even when the change is
  CI/docs-only. The `no changelog` / `no version increment` labels skip them, but
  adding the entries is the cleaner fix (don't bypass CI). Learned driving PR #151
  (issue #75).
- This pattern likely applies to repos created from this template (same workflow
  files).
- Workflow convention (documented there): every job sets `timeout-minutes` of at
  most 50, placed right after `runs-on:`.
