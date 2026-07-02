# Debugging notes

## Markdown line-by-line processors: every inner loop needs its own fence tracker

When writing a script that reformats Markdown line by line, the outer loop usually
tracks `in_code_block` to pass fence bodies verbatim. But inner collection loops
(bullet continuation, blockquote accumulation) often collect lines first and process
later — they need their **own** fence-state tracker, or fenced code blocks inside
bullets/blockquotes get stripped, joined, and reflowed as prose.

Pattern: any loop that accumulates lines before processing should break (or track
`in_inner_code`) when it hits a ```` ``` ```` line.

**Test matrix before shipping a Markdown reformatter:**
- Top-level fenced code block (the baseline)
- Fenced code block inside a numbered step / bullet item
- Fenced code block inside a blockquote (`> ``` … > ``` `)
- Multi-line code block body (not just single-line) in each of the above

Hit on d-morrison/ai-config#265: the semantic-line-breaks script lacked fence
tracking in the bullet continuation loop and the blockquote collection loop.
Both took two rounds of review to fully fix (single-line fence caught in round 1,
multi-line body in blockquotes caught in round 2).
A separate edge case also surfaced in round 3: `_flush_bq_prose` silently dropped
lines when `split_sentences` returned `[]` (empty blockquote text) and multiple
lines had accumulated — unrelated to fence state, but found in the same cycle.

## Testing CSS/JS-dependent web features — use a REAL browser, not a DOM stub
- A hand-rolled DOM shim (or jsdom-style unit test) can PASS while the feature is
  visibly broken, because it doesn't apply the page's CSS or run the framework's
  own scripts. On rme#929 a DOM-stub test of a mobile TOC passed, but in a real
  browser the menu never opened: a framework CSS rule (`nav[role=doc-toc]{display:none}`)
  hid the cloned node, and native `<details>` closed-hiding didn't apply either.
  Neither failure is observable without real CSS.
- Drive a real headless browser. **In the remote/web-session runner** (paths
  below are that runner's — they differ on a local CLI setup; `which chromium` /
  `npm root -g` to find yours), Playwright is installed globally; the chromium
  binary is at `/opt/pw-browsers/chromium-*/chrome-linux/chrome` (the
  `/usr/bin/chromium-browser` is a snap stub that won't launch — pass the real
  path as `executablePath`, plus `args:['--no-sandbox']`). Import Playwright by
  its absolute global path (`/opt/node22/lib/node_modules/playwright/index.js`),
  which is a CommonJS default export: `import pkg from '…'; const {chromium}=pkg`.
- Serve the built site over HTTP (`python3 -m http.server` in `_site`) and load
  `http://localhost:<port>/…` — `file://` blocks the framework's `type=module`
  scripts (e.g. Quarto's `quarto-nav.js` / `quarto.js`) via CORS, so headroom/nav
  behavior won't run. Test viewport-specific behavior with `newPage({ viewport })`,
  and assert computed styles / `offsetHeight` (not just DOM presence).
- **Quarto dark mode** (the `theme: {light: cosmo, dark: darkly}` pair in
  `_quarto.yml` that adds a navbar toggle): to force/screenshot the dark theme,
  set `localStorage["quarto-color-scheme"] = "alternate"` via `addInitScript`
  BEFORE navigation, then load over HTTP (not `file://`). The toggle button calls
  `window.quartoToggleColorScheme()`, but it only works once `quarto.js` has
  loaded — which it can't under `file://` (CORS), so the toggle silently no-ops
  and the page stays light. Verify the switch took with
  `getComputedStyle(document.body).backgroundColor` (darkly → `rgb(34,34,34)`),
  not by the toggle icon alone. The stored value is the literal string
  `"alternate"` (dark) / `"default"` (light) — NOT `"dark"`/`"light"`.

## ARDI/iterate: must poll for new review after pushing
- After pushing fixes during an iterate loop, DON'T declare "clean" based on
  the previous review. A new push triggers a new auto-review.
- Poll until a review note appears that references your latest commit SHA.
- Wait ~30-60s, then check. If nothing after ~2min, check pipeline status.
- The iterate skill now has explicit polling instructions for both GitHub and GitLab.

## VS Code editor buffer vs disk desync
- `replace_string_in_file` / `read_file` operate on the VS Code editor buffer.
- If the file was externally modified (e.g., by `git pull`), the editor buffer
  may be stale or the edit may land in a buffer that doesn't match disk.
- `git diff` and terminal `cat`/`sed` see the DISK, not the editor buffer.
- Symptom: `read_file` shows your edit, but `git diff` shows nothing.
- Fix: write via terminal (`sed -i`, `cat >`, etc.) to guarantee disk write,
  OR save the VS Code buffer before committing.
- When `replace_string_in_file` fails with "could not find matching text",
  the disk file likely differs from what `read_file` showed (stale buffer).

## macOS sed vs GNU sed syntax differences
- `sed '1{/pattern/d}'` works on GNU sed (Linux CI) but FAILS on macOS BSD sed
- Portable form: `sed -e '1{' -e '/pattern/d' -e '}'` (separate -e expressions)
- Always test sed commands locally before committing if they use address+command blocks
- The CI runs on Linux (GNU sed) but local dev is macOS (BSD sed) — use portable form

## bash "syntax error: unexpected end of file" at last line
- Almost always an unclosed construct (`if`/`fi`, quote, `$(`).
- BUT a sneaky cause is **CRLF line endings**: `\r` makes bash read `then\r`/`fi\r`
  as non-keywords, so the `if` never closes -> EOF error.
- Diagnose: `sed -n 'A,Bp' file | od -c | head` and look for `\r \n`.
- Fix: `perl -i -pe 's/\r\n/\n/g' file`, then re-run `bash -n file`.
- Prevent: add `.gitattributes` with `*.sh text eol=lf`.

## Programmatic comment edits leave punctuation/grammar artifacts
Recurring across the sparta scrub PRs (Lacaedemon/sparta#150, Lacaedemon/sparta#152)
— removing inline content from comments (issue refs like `(#138)`, parentheticals,
clauses) via sed/scripted passes repeatedly broke the surrounding prose. The reviewer
(and Copilot) flagged ~6 of these. After any scripted comment edit, **re-audit the
touched lines** before pushing:
- **Mid-sentence parenthetical removed → orphaned comma/period on the wrapped continuation line.** When the ref opened a continuation line — `# ...launched from the map` / `# (#122), before...` — stripping `(#122)` leaves `# , before...`. Fix: move the comma/period up to the end of the prior line (`# ...launched from the map,` / `# before...`).
- **Line-leading `(#NN).` removed → comment marker + bare punctuation.** `## (#82/#84).` opening a continuation line → `##.`. Fix: end the previous line's sentence and drop the marker-orphan.
- **Trailing clause/ref removed → dangling text.** `# ... see issue #61.` → `# ... see issue.` (referent gone). Fix: drop the now-meaningless phrase.
- **Repeated word exposed.** `keyed off the uid (#50): keyed off get_instance_id()` → `...uid: keyed off...`. Fix: reword.
- Audit greps (ERE — `grep -E`): `grep -rnE "^[[:space:]]*#+[[:space:]]*[.,;:]"` (orphaned leading punctuation),
  and scan for `see issue\.`, `, #[0-9]+,`, double spaces, broken section-header dashes.
- The blanket strip patterns that work cleanly (with `sed -E` / `sed -r` — they need
  ERE for the `+` quantifier; in ERE, `\(` and `\)` match literal parens, not groups):
  `s/ \(#[0-9]+\)//g` (inline), `s/^# #[0-9]+: /# /` (prefix — `^`-anchored, so no `g`), `s/, #[0-9]+,/,/g` — but
  the line-leading and sentence-internal cases need hand edits, not sed.

## Merging main into a sibling PR can silently clobber an un-customized file
When PR-A merges and you sync sibling PR-B (which touches the same files), a file
that B never customized takes main's (A's) version **with no merge conflict** — so
it can end up with content describing A's change, not B's. Hit on Lacaedemon/sparta#152:
the `demos/demo.json` reason silently became Lacaedemon/sparta#143's diplomacy text.
After such a
merge, don't just resolve the marked conflicts — **diff the whole merge result vs
the PR's intent** and check files that merged "cleanly" but belong to this PR
(demo manifests, PR-specific metadata) still say the right thing. Also re-run the
PR's own invariant (here: the ref-scrub) over files main re-touched, since A may
have re-introduced exactly what B removed.

## A parallel session can force-push your PR branch out from under you
On Lacaedemon/sparta#150 another driver (a second `@claude` task, or GitHub's
"Update with rebase") force-pushed the PR branch three times, each time replacing
my sync-merge commit with a rebase that dropped my conflict resolutions and
reverted fixes. Defenses:
- **Before pushing to a shared PR branch, `git fetch` and check that `origin/<branch>`
  hasn't moved since your last push** — don't assume your last push is still HEAD.
  `git log --oneline HEAD..origin/<branch>`: non-empty means a parallel session pushed
  past you. (This handles unpushed local commits, where a bare `rev-parse HEAD` vs
  `origin` would always differ by design.)
- **When it was force-pushed, reset to origin and re-verify the content** (refs,
  the specific fixes, demo/metadata) rather than force-pushing your divergent copy
  back. The rebase may already carry the same correct content — diff it.
- **If origin's content is already correct, stand down — don't push.** Pushing a
  divergent merge just restarts the tug-of-war. Reset local to origin and let the
  review run.
- **Escalate to the user to settle who drives the PR** once you see repeated
  force-pushes — that's the claim-pr/parallel-session collision, and one driver
  should own it.

## Test implicit path coverage when a change affects more branches than described
When a code block is placed in a shared path (e.g. the non-append `else:` branch
of an order dispatcher), it implicitly covers every non-append command type —
plain moves, reform moves, form-up drags, etc. — even if the PR's focus was one
specific case. Reviewers flag missing coverage for implicit paths.

Pattern: after placing a change in a shared branch, enumerate the full set of
command types that reach it, and add at least one test per type beyond the primary
case. Name each test to make the path explicit (e.g. `test_form_up_pre_faces_march_direction`).

Hit on Lacaedemon/sparta#352: the pre-facing block ran for form-up drags too,
but no test covered that path until the reviewer flagged it.

## Appending to skill/memory files: grep for duplicate sections first
Before adding a new `##` section to an existing skill or memory file, grep the
file for the section heading. It's easy to append a section that already exists —
the scout-peers duplicate `## Relationship to other skills` bug (ai-config#132)
happened because an existing section was missed and a duplicate was appended at
the end. Run `grep -n "^## " <file>` before appending.

## Writing robust bash scripts (recurring review findings)
Lessons the reviewer flagged across the `session-lock` PR (d-morrison/ai-config#38) —
pre-empt these when authoring shell, especially under `set -euo pipefail`:
- **`mktemp` + rename: add a cleanup trap.** A process killed between `mktemp`
  and the `mv` orphans temp files forever. Pattern: `tmp=$(mktemp <dir>/.tmp.XXXXXX);
  trap 'rm -f "${tmp:-}"' EXIT; … > "$tmp"; mv -f "$tmp" "$dest"; trap - EXIT`.
  Belt-and-suspenders for `SIGKILL` (trap can't fire): a prune path that sweeps
  `find <dir> -name '.tmp.*' -mmin +60 -delete` — but the `-name` glob must match
  the `mktemp` prefix you chose, or it silently misses every orphan
  (`.tmp.XXXXXX` → `'.tmp.*'`; mktemp's bare `tmp.XXXXXX` default → `'tmp.*'`).
- **Bounds-check value-taking flags before `shift 2`.** In a `set -e` arg
  parser, `--flag` as the last arg makes `${2:-}` expand to "" but the following
  `shift 2` fail (count out of range) → script aborts with a cryptic error.
  Guard with the `set -u`-safe presence test:
  `--flag) [ "${2+set}" = set ] || die "--flag requires a value"; V="$2"; shift 2 ;;`
  (`${2+set}` → `set` when `$2` is present even if empty, `""` when absent.)
- **Never interpolate shell vars into a `python3 -c` / `awk` program string.**
  Pass them as arguments: `python3 -c '…sys.argv[1]…' "$val"` (not `"…'$val'…"`)
  — keeps code and data separate and avoids quoting/injection breakage.
- **Declare loop-local vars once** in the function's top `local` line; bash
  `local` is function-scoped, so re-declaring inside loop bodies is redundant.
- **bash 3.2 (macOS default) compatibility:** indexed arrays, C-style
  `for ((…))`, and `${2+set}` all work; **associative arrays do NOT** (4.0+).
  Parse key=value records with `while IFS='=' read -r k v; do case "$k" in …`.

## Verifying R-package tests: install + testthat, never `source()` the R files
Hit on ucdavis/ettbc#14. The env had no `devtools`/`renv`, so I "verified" the new
tests by `sys.source()`-ing every `R/*.R` file and re-running the assertions by
hand. They passed — but CI's `R CMD check` failed with
`could not find function "run_augment_one"`. Two lessons:
- **testthat runs each test file top-to-bottom, and `test_that()` executes
  immediately.** Helper functions (and file-scope fixtures) must be defined
  **above** the `test_that()` blocks that call them. A helper defined at the
  bottom of the file is undefined when the earlier tests run. Manual sourcing
  hides this because you naturally define helpers before use in the REPL.
- **Don't emulate the test run by sourcing `R/`.** It reproduces neither
  testthat's execution model nor the package namespace (internal, unexported
  functions resolve under `source()` but the suite's `test_check` exposes them
  differently). Install the toolchain from the Posit package manager and run it
  the way CI does:
  `install.packages(c("testthat","cli", <Suggests used>), repos="https://packagemanager.posit.co/cran/__linux__/noble/latest")`,
  then `R CMD INSTALL .`, then `testthat::test_dir("tests/testthat", load_package="installed")`.
  roxygen2, lintr, and spelling install the same way — so `roxygenise()` (diff
  check), `lint_package()`, and `spell_check_package()` are all runnable locally
  even when `renv::restore()` can't reach the full dependency set.
  **Caution: a full `test_dir()` / `devtools::test()` pass can PRUNE `_snaps/`
  files whose snapshot test was skipped or went unrun this pass** (e.g. snapr
  tests skipped because `NOT_CRAN` is unset) — see the snapr section below before
  running it with `git add -A` in scope.

## R test/lint gotchas that only surface in CI
Also from ettbc#13/#14:
- **`lintr::object_usage_linter` flags package datasets used inside a *named*
  helper function in a test file** (`no visible binding for global variable
  'cohort'`). The same dataset used directly inside a `test_that()` block is
  fine. So reference lazy-loaded data at file scope or inside the test blocks,
  not inside a top-level helper. The repo's `lint-changed-files` job runs
  `R CMD INSTALL .` before `lint_package`, so cross-file *internal* functions
  (e.g. a helper defined in another `R/` file) resolve — a single-file
  `lintr::lint()` can't see them and will false-flag them.
- **`spelling::spell_check_package()` locally over-reports vs CI** on accented
  hyphenated names: line-wrapped `García-Albéniz`/`Hernán` in `.Rd` files
  tokenize as `Garc`/`niz`/`Hern`, which the CI spellcheck action does not flag
  (main passes with them). Trust CI's misspelled count; add only the genuinely
  new words to `inst/WORDLIST`.
- **The ettbc `review / claude-review` check fails/skips org-wide when the
  Anthropic org spend limit is hit** (`github-actions[bot]` posts "monthly spend
  limit"). It's environmental, non-blocking, and unfixable from a content PR
  (the bot can't edit `.github/workflows`). Stand in with a manual self-review
  rather than chasing it.

## R snapshot tests (snapr / testthat) — regenerating without collateral damage
Hit across ucdavis/bcs#264 (the snapr-based `expect_snapshot_data` suite):
- **When a snapshot's test is skipped or doesn't run in a given pass, a full
  `testthat::test_dir()` / `devtools::test()` run PRUNES its now-orphaned
  `_snaps/` file** (not every routine run — the trigger is the snapshot going
  unproduced this pass). On #264 the snapr tests were skipped (`NOT_CRAN` unset,
  see below), so a `test_dir()` pass treated their snapshots as orphaned and
  deleted 23 of them; `git add -A` then silently staged every deletion. (Stock
  testthat 3.x gates orphan *deletion* on snapshot-update mode — a normal run
  only warns — so the #264 prune was likely either an implicit update pass or
  snapr's own `expect_snapshot_data` pruning path; I didn't pin down which. The
  defense below holds either way.) Regenerate **per file** with
  `testthat::test_file("tests/testthat/test-<fn>.R")`, stage only the snapshots
  you meant to touch (`git add tests/testthat/_snaps/<fn>.md`), and if the suite
  did prune others, restore them: `git checkout origin/main -- tests/testthat/_snaps`.
- **snapr snapshot tests are skipped unless `NOT_CRAN=true`** (they're guarded
  like `skip_on_cran()`); locally you must set the env var or every snapshot
  silently no-ops and "passes" without comparing.
- **`furrr`/`future` parallel workers cannot load a `pkgload::load_all()`'d
  package** — a worker starts a fresh R process that only sees installed
  packages, so any snapshot that runs the analysis under `future_map` errors or
  produces nothing. Regenerate those snapshots in a **sequential** plan
  (`future::plan("sequential")` / set workers to 1), then copy the result into
  the parallel snapshot path — verify seq==par output on `main` first so the
  copy is sound.
- **`require-review` failure caused by dispatch winning the concurrency race.**
  `cancel-in-progress: true` on a concurrency group means a newly-dispatched
  review cancels the still-running push-triggered review. The push-triggered
  run's `require-review` gate then shows as failed (cancelled parent = failed
  dependent), while the dispatched run's `require-review` is green. The PR
  shows `mergeable_state: unstable` from the cancelled run but is still
  mergeable — GitHub uses the most recent check run per name and commit SHA, so
  the dispatched run's passing `require-review` replaces the cancelled push
  run's check in branch protection. Confirm the dispatched run posted a clean
  verdict and proceed to merge; don't re-trigger. (gha#133.)
- **`tests/testthat.R` runs with `stop_on_warning = TRUE`**, so any warning
  during a test FAILS CI even with 0 test failures (shows as `WARN N`). When you
  hit it, don't guess the source — **capture the actual messages**
  (`withCallingHandlers(..., warning = \(w) {message(conditionMessage(w)); ...})`).
  On #264 the GLM "fitted probabilities 0 or 1" / "did not converge" warnings
  were a red herring; the real one was a `cli::cli_warn("risk ratio is undefined")`
  from a zero-risk group at small n. Muffle expected small-sample warnings in
  BOTH the package source (a `suppress_*_warnings()` helper wrapping the fit
  chain) AND the test helper, matching every pattern the fits actually emit.

## A push-to-main-only workflow can't fail a PR — add a static PR guard when you fix one
A workflow that triggers only on `push:` to `main` (deploy/publish/release jobs)
never runs on pull requests, so a bug it would catch stays invisible until after
merge — and then it fails on `main`, where no one is watching a specific PR.
Hit on d-morrison/rme#966/#967: the Quarto **publish** workflow (push-to-main
only) went red the moment the concept-map appendix merged and stayed red for two
days across several later merges, because no PR ever ran the full multi-format
website render that collides.

When you fix such a post-merge-only failure, don't stop at the fix — add a
**cheap static check that runs on `pull_request`** so the bug class can't regress
unnoticed. It needn't reproduce the whole heavy job; a few seconds of parsing
that asserts the invariant is enough. d-morrison/rme#970 added `check-render-headers`, a
~120-line Python + PyYAML script that asserts "no two of a render-list page's
formats resolve to the same output file," runs in ~8s, and would have caught the
original bug at PR time. Prevention (fix the scaffolder/template that emits the
bad input) and enforcement (the PR guard) are complementary — ship both.

## Reproduce heavy-tool project bugs minimally
The Quarto
`safeMoveSync`/`renderProject` `rename '<stem>.html' -> No such file` collision
reproduced in an R-free, LaTeX-free two-file website project (`format: {html,
revealjs}`, one page missing the revealjs `output-file` rename so revealjs and
html both write `<stem>.html`) in seconds. When a full render/build is too heavy
to run in the sandbox, strip the failing behavior down to the smallest project
that still triggers it — it confirms both the diagnosis and the fix far faster
than the real pipeline, and becomes the negative test for the guard.
