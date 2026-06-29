# Local tools & CLIs

## gh (GitHub CLI)
- `gh` opens a pager (alternate buffer) that hangs the agent terminal.
- Always disable it: pipe `| cat` or set `GH_PAGER=cat` (e.g. `gh pr view 116 | cat`).
- **Rate limit is shared (5000/hr) and split GraphQL vs REST.** All tools/sessions/agents share the one user's 5000/hr; **GraphQL has its own, smaller pool that exhausts first** — `gh pr checks`, `gh pr view --json comments`, `gh pr list --json` use GraphQL. When GraphQL is spent, get the same data via REST (still has budget): `gh api repos/<o>/<r>/pulls/<n>`, `.../commits/<sha>/check-runs`, `.../issues/<n>/comments`. `gh api rate_limit --jq .resources` is **free** (doesn't count) — check `core` vs `graphql` remaining/reset before retrying. Don't tight-poll; use a background watcher with `sleep` (parallel sessions drain the shared pool fast).
- **The @claude review bot's author name differs by API:** its comment author is `claude[bot]` in REST (`.user.login`) but `claude` in GraphQL (`.author.login`). A watcher filtering REST comments for `.user.login == "claude"` silently finds nothing — use `"claude[bot]"`.
- **Linking a GitHub sub-issue needs an integer DB id, not the number.** `POST /repos/<o>/<r>/issues/<parent>/sub_issues` takes `sub_issue_id` = the child's **database id** (`gh api repos/<o>/<r>/issues/<child> --jq .id`), *not* its issue number. Pass it with `-F` (typed, integer), never `-f` (string) — `-f sub_issue_id=…` fails with `422 Invalid property /sub_issue_id: "…" is not of type integer`. Full call: `gh api repos/<o>/<r>/issues/<parent>/sub_issues -F sub_issue_id=<child_db_id>`. Verify with `gh api .../issues/<parent>/sub_issues --jq '.[] | "#\(.number) \(.title)"'`.

## Re-triggering the @claude PR *review* (d-morrison Quarto / R-pkg repos, e.g. `psw`)
- Filenames below are those in the **content/package repos** (verified in
  `d-morrison/psw`): the review workflow is `.github/workflows/claude-code-review.yml`
  and the comment-triggered agent workflow is `.github/workflows/claude.yml`.
  (ai-config's *own* bot uses different names — `claude-review.yml` /
  `claude-bot.yml` — so don't infer these from *this* repo's `.github/workflows/`.)
- **`d-morrison/gha` itself (the shared workflow repo) is different:** the
  reusable workflow is `claude-code-review.yml` (no `workflow_dispatch`), and the
  dogfooding caller stub with `workflow_dispatch` is `claude-review.yml`. So to
  dispatch a review in `gha`:
  `gh workflow run claude-review.yml -f pr_number=<N>` (not `claude-code-review.yml`).
- The review workflow (which calls `d-morrison/gha`'s reusable review workflow)
  is **not** comment-triggered. It runs on `pull_request` (`types: [opened,
  synchronize, ready_for_review, reopened]`) and on `workflow_dispatch` (input
  `pr_number`). Posting an `@claude review` *comment* drives the separate agent
  workflow `claude.yml` (which then re-dispatches a review after it pushes) — it
  does not directly fire the review workflow.
- A new push (`synchronize`) auto-fires a fresh review — the normal path during
  an iterate loop.
- To force a fresh review on an existing PR **without a new commit**:
  - **workflow_dispatch** (preferred — no extra PR timeline noise). Same
    dispatch, three ways to send it:
    - **`gh`:** `gh workflow run claude-code-review.yml -f pr_number=<N>`
      (dispatches the workflow as defined on the **default branch** — `gh`
      defaults `--ref` to it).
    - **REST** (remote/web sessions, no `gh`):
      `POST /repos/<owner>/<repo>/actions/workflows/claude-code-review.yml/dispatches`
      with body `{"ref":"main","inputs":{"pr_number":"<N>"}}` (`"main"` = the
      repo's **default branch**; the `ref` must be a branch/tag that *contains*
      the workflow file, not the PR branch, unless you mean to dispatch a
      modified version).
    - **GitHub MCP:** your workflow-dispatch tool if available (e.g.
      `mcp__github__actions_run_trigger`).
  - **Close + reopen the PR** → fires the `reopened` event, which re-runs the
    review. Works reliably, but clutters the timeline with close/reopen events;
    prefer workflow_dispatch unless dispatch isn't available.

## gh — stale remote URL causes cryptic `gh pr create` failure
- `gh pr create` fails with `Head sha can't be blank, Base sha can't be blank, No commits between <owner>:main and <other-owner>:<branch>` when `origin` points to an **old repo URL** (e.g. after a GitHub repo transfer/rename).
- Fix: `git remote set-url origin https://github.com/<new-owner>/<repo>.git` and re-push the branch before creating the PR.
- Diagnosis: `git remote -v` shows the stale URL; `gh repo view --json nameWithOwner` shows where `gh` thinks the canonical repo is.

## GitHub MCP tools (Claude Code remote/web sessions)
- In remote/web sessions the authenticated GitHub identity is the repo owner
  (`d-morrison`), so requesting `d-morrison` as a PR reviewer fails with
  `422 Review cannot be requested from pull request author`. Harmless — the PR
  is still created; the reviewer just isn't added. Don't treat the 422 as a
  failure to retry (it's expected per the standing request-pr-review rule when
  the author == the requested reviewer).
- `gh` is NOT available in these sessions — use the `mcp__github__*` tools for
  all GitHub interactions (PRs, issues, comments, reviews). CI status is always
  available via `mcp__github__pull_request_read` (`get_check_runs` / `get_status`)
  and the `mcp__github__actions_*` tools. Some environments may *also* expose a
  separate `github_ci` MCP server (`mcp__github_ci__*`, e.g. `get_ci_status`),
  which can connect asynchronously after session start. Don't conclude a tool is
  absent from one check — `ToolSearch` for what you need before deciding it's
  missing (and don't assume the `github_ci` server is present either).
- **`mcp__github__actions_run_trigger` can't re-run CI jobs in these sessions —
  it 403s.** `method: rerun_failed_jobs` (and `rerun_workflow_run`) returns
  `403 Resource not accessible by integration`: the integration token lacks the
  `actions: write` the re-run API needs. So a flaky CI failure can't be re-kicked
  via MCP — **push a commit to re-trigger the whole workflow** (the normal path
  during an iterate loop anyway), or ask the user to click Re-run. (Hit
  re-running a flaky `link-checker` timeout on a lab-manual PR.)
- `mcp__github__pull_request_read` `method:` enum: `get` · `get_diff` (PR
  unified diff — equivalent to `gh pr diff`) · `get_status` · `get_files` ·
  `get_commits` · `get_review_comments` · `get_reviews` · `get_comments` ·
  `get_check_runs`.
- **`get_status` can return "pending / 0 checks" even after CI has finished.**
  Use `get_check_runs` for the authoritative CI state — it returns the real
  job conclusions (`success`, `failure`, `skipped`). `get_status` aggregates
  across check suites and can lag or show a stale "pending" when all runs have
  actually completed. Don't rely on `get_status` alone to declare CI green.
  (Hit during the ai-config #275 GII session — `get_status` showed
  `total_count: 0` / `pending` while `get_check_runs` correctly showed all 5
  checks `success`.)
- `mcp__github__pull_request_read` parameter names are **camelCase** — use
  `pullNumber`, NOT `pull_number`. Snake_case fails silently or errors.
- `mcp__github__add_issue_comment` parameter is **`issue_number`** (snake_case),
  NOT `issueNumber`. This is the opposite of `pull_request_read`. Reload the
  tool schema when unsure rather than guessing.
- **Issue *writes* 404 while *reads* succeed → the issue was transferred to
  another repo, not a permissions gap.** If `mcp__github__add_issue_comment` /
  `issue_write` to `owner/repo#<N>` fail (`404 Not Found`, or `Could not resolve
  to an Issue with the number of <N>`) but `issue_read` (`get`) on the *same*
  number succeeds and PR-comment writes work, suspect a **GitHub issue
  transfer**. A transfer redirects the old number for *reads* — `issue_read`
  silently follows the redirect and returns the issue at its NEW home, so check
  the returned `html_url`/`number` (they show a different repo/number). Writes to
  the old `owner/repo/issues/<N>` 404 because the issue no longer lives there.
  Fix: re-read to get the new repo + number, then comment/close *there*. Don't
  misdiagnose it as a missing `Issues:write` token scope. (Caught closing
  `gha#75`, transferred to `rme#941`.)
- **In a fresh web/remote container, local `origin/*` refs can be stale or
  phantom — verify true remote state via MCP, not local refs.** The clone's
  `remotes/origin/main` may lag the real default branch by already-merged
  commits, and the harness-assigned `claude/<id>` branch can appear under
  `git branch -a` as `remotes/origin/claude/<id>` while not existing on the real
  remote (`get_file_contents` with `ref: refs/heads/claude/<id>` returns 404).
  `git fetch origin` (all refs) can also exceed the 2-min Bash limit on large
  repos with submodules (rme). To read the real default-branch HEAD cheaply,
  `get_file_contents` any file with no `ref` (= default branch) — the returned
  resource path embeds the live commit SHA. Fetch the single branch you need
  (`git fetch origin main`) and branch off that, so you don't build on a
  stale/polluted base.
- `mcp__github__pull_request_review_write` with `method: resolve_thread`
  requires **only `threadId`** (node ID, e.g. `PRRT_kwDO...`); `owner`,
  `repo`, and `pullNumber` are ignored for that method. Thread node IDs come
  from `get_review_comments`.
- Webhook PR-activity events cover comments/reviews/CI *failures* but NOT CI
  *success*, new pushes, or merge-conflict transitions — don't rely on events
  alone to know a PR went green or merged; re-check explicitly.
- **Self-wake to re-check CI in remote/web sessions.** Webhooks don't deliver CI
  *success*, new pushes, or merge transitions, so re-check on a timer. Prefer
  `CronCreate` (a harness scheduling tool, not an MCP tool): schedule a one-shot
  (`recurring: false`) or recurring (`recurring: true`) job whose prompt re-polls
  `mcp__github__pull_request_read` (`get_check_runs`) and acts on the result; it
  fires at wall-clock time without holding a background process. (Used to watch
  both PRs' merge transitions while migrating rme's preview workflows to the gha
  reusable family.) Fallback when `CronCreate` isn't available: arm a one-shot
  `Monitor` with `sleep <N>; echo recheck` and re-poll when it fires — the
  `Monitor` can't reach the GitHub API itself (no `gh`; the only git remote is a
  git-only proxy), so it's purely a timer, and foreground Bash `sleep` is
  blocked, which is why the background `Monitor` is the workable one. There is no
  `send_later` tool. Re-arm until the build goes green. Learned driving rme#929.
- The `gh`->MCP substitution **mapping table** lives in `d-morrison/gha`'s
  `CLAUDE.md` specifically (the "GitHub access in remote / web sessions" table);
  other repos' `CLAUDE.md` (e.g. `ai-config`) do NOT carry it. When a skill or
  doc tells a reader to "use the GitHub MCP tools," name the tools by example
  (`mcp__github__add_issue_comment`, `mcp__github__create_pull_request`,
  `mcp__github__search_pull_requests`) rather than pointing at "the repo's
  `CLAUDE.md` mapping table" — that cross-reference
  resolves only in gha and reads as a fabricated reference elsewhere. (Caught in
  ai-config#137 review: the gip skill referenced a table ai-config doesn't have.)

## GII (Grab Issues Iteratively) — startup cleanup sweep

When starting a GII loop, do a cleanup pass before diving into ARDI:

1. **List all open PRs** with `mcp__github__list_pull_requests`. Look for
   stale bot-opened PRs that target the same issues as the queue.
2. **Close empty PRs** — bot-opened branches with no commits (e.g. a `@claude`
   task run that posted a comment but never pushed code). Check `get_commits`
   on each PR before closing.
3. **Identify the canonical PR** for each in-flight issue. Superseded drafts
   should be closed with a note pointing to the canonical one.
4. **Collapse stacked changes** — if two open PRs both touch the same file,
   merge one branch into the other before starting ARDI, so the reviewer
   evaluates the combined diff rather than two separate PRs.

Skipping this sweep leads to confusion: multiple PRs for the same issue,
closed-issue references in multiple PR bodies, and stacking conflicts mid-ARDI.
(Learned from the ai-config #275 / #272 / #265 / #266 cleanup pass.)

## Git tags (force-move / slide)
- To move a tag to a new commit: `git tag -d <tag> && git tag <tag> <target> && git push origin :refs/tags/<tag> && git push origin <tag>`
- Can't use `git push --force origin <tag>` on some GitLab instances (protected tags). The delete+recreate pattern always works.
- `git fetch --tags` silently refuses to update a local tag that already exists if the remote moved it. Use `git fetch --tags --force` to get the latest remote tag positions. Without `--force`, you'll see stale local tags and draw wrong conclusions about what the tag includes.

## Git — bump a submodule pin without initializing it
- To advance a submodule pointer when the submodule isn't checked out (common in
  a remote/web session, where the configured submodule URL may be unreachable
  from the sandbox), update the gitlink directly in the index:
  `git update-index --cacheinfo 160000,<full-sha>,<path>`, then commit and push.
  Clones and CI resolve the new SHA from the submodule's own remote.
- The `<full-sha>` must already exist on the submodule's remote, so push or merge
  it there first or clones can't resolve the pin.
- `git diff --cached --submodule=log` reports the change as `Submodule <path>
  <old>...<new> (commits not present)`. The "commits not present" note just means
  the submodule isn't checked out locally; it is not an error.
- This is the manual form of what lab-manual's `bump-ai-config.yml` and gha's
  `bump-submodule` workflows do automatically. Use it for a one-off bump (e.g.
  lab-manual#338 picked up an ai-config reprexes fix this way).

## Git — scanning for parallel/in-flight work
- A remote-only scan (`git branch -r`) **misses** work a parallel CLI session is
  building in an **unpushed local worktree** — the branch exists only locally
  until that session pushes. Hit PR #67: a sibling skill was caught by a stray
  system-reminder, not the scan.
- To find all in-flight work before starting (skill-builder Step 0, deconflict,
  scout-peers, etc.), run two scans: `git branch -a` for local + remote refs
  (catches committed-but-unpushed local branches), and the `git worktree list`
  working trees for *untracked* files that never reached any ref
  (`git -C <wt> ls-files --others --exclude-standard -- 'skills/'`).

## Git — looking up a PR's branch name
- `git branch -r` lists **all** remote branches — useless for finding a specific PR's branch: it has no way to filter by PR number. Don't suggest it as a fallback.
- Targeted lookup: `gh pr view <N> --json headRefName -q .headRefName` in CLI sessions;
  `mcp__github__pull_request_read` with `method: get` in remote/web sessions.
- Flagged on ai-config#186: the first draft of the harness-override instruction included
  `git branch -r` as the fallback; reviewer (claude-review bot) caught it.

## Git branch create/reset (`git switch -C`)
- `git switch -C "$BRANCH"` is already safe against flag-shaped branch names: `$BRANCH` is the argument *to* `-C`, so a value like `--weird` fails cleanly as `fatal: '--weird' is not a valid branch name` rather than being parsed as an option.
- Do NOT "harden" it to `git switch -C -- "$BRANCH"` — that form is **broken**: the `--` is consumed as the branch name (the required argument to `-C`), so `$BRANCH` is parsed as the start-point instead and the command fails without creating the branch. (Verified on git 2.x; a review bot suggested the broken form on d-morrison/gha#58.)

## Git — `worktree add` does not cd into the new worktree
- `git worktree add <path> <ref>` creates the worktree at `<path>` but leaves the
  shell in the **original** checkout. Subsequent bare git commands (`git checkout`,
  `git merge`, etc.) run against the original checkout, not the new worktree.
- Always follow `git worktree add <path> …` with `cd <path>` before any further
  git work inside that worktree.
- When creating a worktree to fix a **conflict caused by a squash-merge on main**,
  `git fetch origin main <branch>` (both refs) **before** `git worktree add` so
  the squash commit is present when you merge. Fetching only the PR branch leaves
  origin/main stale and the merge won't pick up the commit that caused the conflict.

## Git — removing a worktree that contains a submodule
- `git worktree remove <path>` **fails** on a worktree that has an initialized
  submodule: `fatal: working trees containing submodules cannot be moved or
  removed`. Many repos with a vendored `.ai-config` submodule hit this after a
  feature branch merges.
- Fix: `git worktree remove --force <path>` removes it cleanly. (Plain `--force`
  is enough; the submodule warning is the only blocker.) If the dir somehow
  lingers, `rm -rf <path> && git worktree prune` finishes the cleanup.
- The branch can't be deleted while the worktree still references it
  (`error: cannot delete branch '…' used by worktree at '…'`), so remove the
  worktree **first**, then `git branch -D <branch>`.

## Git — `merge --continue` takes no arguments
- `git merge --continue --no-edit` fails with `fatal: --continue expects no arguments`.
- After resolving conflicts and staging (`git add <files>`), use `git merge --continue` alone.
- In a non-interactive (headless) session git uses the auto-generated merge commit message without prompting — no editor opens.

## GitLab Discussions API (inline diff comments)
- Endpoint: `POST /projects/:id/merge_requests/:iid/discussions`
- For inline comments, include `position` object: `position_type: "text"`, `base_sha`, `head_sha`, `start_sha`, `new_path`, `old_path`, `new_line`
- Get SHAs from MR Versions API: `GET /projects/:id/merge_requests/:iid/versions` → `[0].base_commit_sha`, `[0].head_commit_sha`, `[0].start_commit_sha`
- If the position is rejected (e.g., line not in diff), the API returns 400 — handle gracefully

## glab (GitLab CLI)
- Installed via Homebrew (macOS) or system package manager — verify with `which glab`.
- Authenticated on your GitLab instance — run `glab auth status` to verify host and username
- Use for MR comments, pipeline checks, CI job logs, etc.
- `glab issue list --opened` is deprecated — `--opened` is the default when `--closed` is not used. Just use `glab issue list` (no flag needed).
- No `GITLAB_TOKEN` env var — glab uses its own config at `~/Library/Application Support/glab-cli/config.yml`
- Key commands:
  - `glab ci list` — list pipelines
  - `glab ci get --pipeline-id <ID>` — view pipeline details (non-interactive)
  - `glab ci create --branch <branch>` — trigger a NEW pipeline (picks up upstream template changes)
  - `glab ci retry --branch <branch>` — retries the EXISTING pipeline (does NOT pick up template changes)
  - `glab ci view <id>` — requires TTY; use `glab ci get` or `glab api .../trace` instead
  - `glab api "/projects/<ID>/jobs/<JOB_ID>/trace"` — get job log non-interactively
  - `glab mr note create <MR_IID> --message "..."` — post MR comment
  - `glab mr list` — list merge requests
  - `glab mr view <MR_IID>` — view MR details
- GitLab CI job token allowlist:
  - When repo A's CI job needs API access to repo B, repo B must add A to its allowlist
  - `glab api --method POST "/projects/<TARGET_ID>/job_token_scope/allowlist" -f "target_project_id=<SOURCE_ID>"`
  - `include:` (for CI templates) works independently of the API allowlist
  - Check existing: `glab api "/projects/<ID>/job_token_scope/allowlist"`

## Julia in Claude Code cloud / web sessions
- To install Julia, prefer downloading the official binary tarball from
  `julialang-s3.julialang.org` via `curl` (system CA store) over `juliaup`:
  juliaup's rustls HTTP client rejects TLS-intercepting proxies common in cloud
  environments, so it can fail even when the host is allowlisted. Prebuilt Linux
  Julia binaries live ONLY on `julialang-s3.julialang.org` — the
  `JuliaLang/julia` GitHub releases attach source tarballs only. `Pkg`
  operations need `pkg.julialang.org` allowlisted too.
- Reference implementation: `references/cloud-setup/cloud-setup.sh` in ai-config
  (curl+tarball, `$SUDO`-aware, best-effort/non-fatal).
- Layering: the build-time **Setup script** is the right place for slow,
  repo-independent toolchain installs (R, Julia, Quarto); the **SessionStart
  hook** is for repo-dependent per-session work (`renv::restore`,
  `Pkg.instantiate`). BUT the build-time Setup script can't be committed to a
  repo (it's pasted into the web UI), so a SessionStart hook is the only
  in-repo lever to auto-install a toolchain for *that repo's own* sessions.

## R / Quarto (rme etc.) in Claude Code cloud / web sessions
- The renv library is NOT provisioned at session start (`requireNamespace`
  returns FALSE for lintr/spelling/rmarkdown). `renv::restore()` from the
  lockfile's CRAN *source* repo is slow. Instead install only what a given
  chapter needs, from BINARY repos:
  - CRAN pkgs → P3M binaries:
    `options(repos = c(P3M = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))`
    then `install.packages(...)` (installs into the active renv library; fast).
  - d-morrison GitHub-only pkgs → r-universe `https://d-morrison.r-universe.dev`
    has `dobson`, `regress3d` (and more), but NOT `rmb` — `rmb` is unavailable
    anywhere reachable, so it blocks full renders of any chapter that does
    `rmb::hers` / `library(rmb)`.
  - `igraph` needs system lib `libglpk.so.40` → `apt-get install -y libglpk40`
    (you're root in these containers). Needed to run `data-raw/callout-graph.R`.
  - The install routes through **pak** (renv's pak backend), which is ATOMIC:
    if ONE requested pkg is unavailable (e.g. rmb), the WHOLE transaction rolls
    back and nothing installs — drop the unavailable pkg and retry. (Holds for
    `pak::pkg_install()`, and for `install.packages()` while renv's pak backend
    is active; base `install.packages()` on its own is NOT atomic.)
  - The **`renv` autoloader can shadow a system-library install.** If you
    `install.packages()` a Suggests-only tool (e.g. `lintr`, `spelling`) into the
    *default* libPaths rather than the active renv library, `Rscript` run from the
    repo root STILL fails with "no package called 'lintr'" — the project
    `.Rprofile` autoloader resets `.libPaths()` to the renv library on startup.
    Either install into the renv library (the P3M path above), or run the one-off
    with the autoloader off:
    `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript -e 'lintr::lint("path/to/file.qmd")'`.
    (Used to lint the changed files for rme #873 when lintr wasn't in the renv lib.)
- **renv activation failure when a GitHub remote is blocked**: if `DESCRIPTION`
  lists a GitHub `Remotes:` entry the proxy can't reach (e.g. bcs's
  `d-morrison/altdoc@recursive-qmd-search`), renv activation (via `.Rprofile`)
  aborts on startup — every subsequent `R` call errors before loading any package.
  Bypass: `R --no-save --no-restore --no-site-file --no-init-file` skips
  `.Rprofile` entirely. Install needed packages from P3M into the user library
  and proceed. (Observed on ucdavis/bcs cloud sessions.)
- **`snapr` is not on CRAN or P3M**: install from the GitHub tarball.
  `curl -L https://codeload.github.com/d-morrison/snapr/tar.gz/refs/heads/main -o /tmp/snapr.tar.gz`
  then in R, install `readr` first (a direct `snapr` `Imports:` dependency):
  `install.packages("readr")`, then
  `install.packages("/tmp/snapr.tar.gz", repos=NULL, type="source")`.
  `snapr::expect_snapshot_data()` silently skips snapshot generation/comparison when
  `NOT_CRAN` is unset (respects the standard CRAN-skip convention):
  `NOT_CRAN=true Rscript -e 'devtools::test()'`.
- The `latex-macros` submodule (d-morrison/macros) is uninitialized on a fresh
  clone → `git submodule update --init latex-macros` before any render, else
  `{{< include latex-macros/macros.qmd >}}` fails for every chapter.
- In a Quarto **project** (observed on rme), `{{< include >}}` paths for files
  rendered via a root wrapper resolved from the PROJECT ROOT *in practice* —
  even for *nested* includes inside subfiles (a `{{< include _root.qmd >}}`
  inside `_subdir/nested.qmd`, rendered via a root wrapper, picked up `_root.qmd`
  from the project root, not from `_subdir/`). This is contrary to the Quarto
  docs' single-document rule ("relative to the file containing the include").
  One observation can't rule out a confound, and behavior may differ across
  Quarto versions or project configs — so test; don't assume *either* rule holds
  without checking. To verify touched subfiles when the full
  chapter needs an unavailable pkg (rmb): write a minimal wrapper `.qmd` AT THE
  REPO ROOT that includes `latex-macros/macros.qmd` + the subfiles, loading data
  manually
  (`hers <- haven::read_dta(here::here("inst/extdata/hersdata.dta"))`). This
  checks LaTeX/markdown/cross-refs for edits that don't touch R chunks without
  provisioning the whole dep tree. Grep the rendered HTML for `?@` / `>??<` to
  catch broken cross-refs.
- Chapters that `{{< include r-config.qmd >}}` pull the full ~40-pkg set
  (dobson, survminer, gtsummary, …); chapters that only include macros.qmd are
  light (math-prereqs needs just plotly).

## R-package PR CI gates (d-morrison / UCD-SERG R packages, e.g. `bcs`)
- These repos gate PRs on a **changelog check** (`news.yaml` / "Check Changelog
  Action") and a **version-check**. A user-visible PR needs **both** a
  `NEWS.md` entry under `# <pkg> (development version)` **and** a `DESCRIPTION`
  `Version:` dev-bump (e.g. `0.0.0.9053` → `.9054`), or CI fails. Add them up
  front rather than waiting for the red check. (Observed on ucdavis/bcs#223.)
  For a **non-user-visible** PR (CI/workflow-only), skip both with the
  `no changelog` + `no version increment` labels instead — see the label-bypass
  note below.
- The **Spellcheck** job (`spelling::spell_check_package()`) fails on any word
  not in `inst/WORDLIST`. For one-off non-dictionary words in NEWS/prose, prefer
  rewording (e.g. "uncaptioned" → "without captions") over polluting WORDLIST;
  add to WORDLIST only for real domain terms you'll reuse.
  - **When the offending token is a code identifier or a literal log/warning
    message** (e.g. quoting `non-integer #successes in a binomial glm!` in a
    NEWS entry, which tripped on `glm`), wrap it in backticks as inline code
    instead — the spellcheck parses markdown and skips code spans, and
    backticking a `pkg::fn()`/identifier/message is the correct markdown style
    anyway. Cleaner than both rewording and a WORDLIST add. (ucdavis/ettbc#30.)
- A `docs-check` / `R-check-docs` job runs `roxygenize()` then `git diff --exit-code
  man/`, so a roxygen edit with a stale `man/*.Rd` fails. **When you can't run
  `devtools::document()` (no R toolchain, e.g. a cloud/web session), you can still
  edit roxygen docs**: hand-edit the matching `man/*.Rd` in lockstep, as long as the
  change doesn't re-wrap lines — a **same-length word swap** (e.g. `biannual`→`biennial`,
  both 8 chars) is ideal because roxygen copies description/param/return prose verbatim
  into the `.Rd` and `roxygenize()` is deterministic, so an identical edit to both
  reproduces exactly what `document()` would generate and `docs-check` passes. Watch
  `@inheritParams`/`@inherit`: editing one function's roxygen also changes the `.Rd` of
  every function that inherits that text, so grep `man/` for the changed sentence and
  edit those `.Rd` files too. (Used on ucdavis/bcs#225 across 13 R files + ~18 man pages.)

## GitHub access from bash in remote/web sessions
- The git proxy proxies ONLY git operations — there is no `gh`/`glab` and no
  GitHub REST API reachable from a Bash/Monitor script. Use `mcp__github__*`
  tools for any API need.
- **The proxy allows branch creation/push but BLOCKS branch deletion.** Pushing a
  *new* branch (even one other than the harness-assigned `claude/...`) works, but a
  delete push — `git push origin --delete <b>` or `git push origin :<b>` — is rejected.
  Observed verbatim: "send-pack: unexpected disconnect" / "remote end hung up", then a
  misleading "Everything up-to-date" (the proxy returns that no-op message instead of a
  normal `failed to push some refs` error), but the command still exits non-zero. So a
  throwaway branch (e.g. a push-capability probe) can't be cleaned up from the session;
  delete it via the GitHub UI/API, or just leave it if it's identical to `main` and has
  no PR. (Seen on ai-config, 2026-06-28.)
- Consequence: you CANNOT poll PR review/CI state from a background Monitor.
  Rely on `mcp__github__subscribe_pr_activity`, which delivers review comments
  and CI *failures* — but NOT CI success, new pushes, or merge-conflict
  transitions. A self-check-in scheduler may be absent: rme's instructions
  reference `send_later` (from the `claude-code-remote` MCP server), and the
  harness may expose its own (e.g. `ScheduleWakeup`) — but in this remote rme
  session ToolSearch surfaced neither, so you can't arm the safety re-poll the
  watch-guidance suggests. Say so rather than implying it's armed.
- rme runs TWO review workflows per push: `claude-code-review.yml` (sticky
  comment, gives the "ready to merge" verdict) and `claude.yml` agent post-step
  (separate findings). They can DISAGREE — one says clean while the other finds
  nits. Reconcile BOTH before calling a PR clean; the agent post-step tends to
  drip 1–2 pre-existing cosmetic nits per round (asymptotic).

## @claude CI action (d-morrison/gha `claude.yml`)
- The reusable `claude.yml@v1` agent workflow restores config files (`CLAUDE.md`,
  `.claude/**`) to `origin/main` during its run (`restoreConfigFromBase`), so a
  PR can't rewrite the reviewer's own instructions. With `eager-pr: true` +
  `contents: write`, the **residual auto-commit step** historically then committed
  that reset onto the PR branch as `claude[bot]` "chore: auto-commit residual
  @claude session changes" — **deleting the PR's own `CLAUDE.md` edits**.
  `memories/**` and `skills/**` were untouched; only the restored-config paths
  were affected.
- **FIXED in gha `v1` (≈2026-06-20):** the residual sweep now force-reverts the
  protected config paths (incl. `CLAUDE.md`, `.claude`, `.mcp.json`, `.gitmodules`,
  `.husky`) back to **PR-tip (HEAD)** before `git add -A`, so it no longer commits
  the reset. A follow-up commit (`78fe7bc`, "honor PR deletions of config files in
  the residual sweep") prevents the sweep from reverting legitimate config-file
  deletions in the PR.
  Verified on ai-config#41: once the fix landed, the gut stopped recurring (the
  config-edit payload stayed on the branch across later bot runs). Was tracked as
  d-morrison/gha#39.
- If a repo pins an **older** gha tag (pre-fix), the workaround still applies. The
  symptom was `claude[bot]` "auto-commit residual @claude session changes" commits
  that reverted only config paths. Restore the section
  (`git checkout <my-commit> -- CLAUDE.md`, commit), then before merging verify with
  `git diff origin/main -- CLAUDE.md` being **non-empty** (an empty diff means the
  payload was silently reverted to main), and merge promptly.
- **The `@claude` agent can push a `main`-merge commit to your PR branch — not just
  comment.** Triggered by PR activity, the `claude.yml` agent may merge `origin/main`
  into the branch and push it (e.g. `claude[bot]` "Merge branch 'main' into <branch>").
  Two consequences: (1) your in-flight local push is rejected ("fetch first" / RPC
  `HTTP 403` from the git backend — a non-fast-forward, **not** a policy denial); (2)
  the bot may resolve a `DESCRIPTION` version conflict to `== main`, which then fails
  `version-check`. Recovery: stash any uncommitted work first (`git stash` — `reset
  --hard` discards it), then `git fetch origin <branch>`, `git reset --hard
  origin/<branch>` onto the bot's merge (don't force-push a competing parallel merge of
  your own — build on the bot's), then re-bump the version above main and push.
  (Hit on bcs#255: the bot pushed `4807f0c` and resolved the version to `.9062` == main,
  failing version-check until I bumped to `.9063` on top.)
- **The `@claude` agent can run a parallel session that posts a phantom commit SHA.**
  While you ARDI a PR (pushing fixes + posting reply comments), the activity can trigger
  the `claude.yml` agent to spin up its own run that attempts the *same* fixes, fails to
  push (it collides with your pushes), then posts review comments crediting a commit SHA
  that **never reached the remote** (e.g. it posts "Addressed in `a841fc7`", but that SHA
  was never pushed and isn't on the remote). The fixes are really there via *your* pushed commit; the cited SHA
  is a phantom. Don't chase it: verify the real branch head with `git ls-remote origin
  <branch>` (or `git rev-parse HEAD` vs `origin/<branch>`), and if the cited SHA fails
  `git cat-file -t <sha>` it never existed. Post a one-line clarification on the PR so the
  phantom doesn't confuse later readers, and keep going. (Hit on ai-config#254.)
- **Dispatched reviews now post a PR comment (gha#89, now in `v1`).** Before this fix,
  `workflow_dispatch` runs wrote output to the step summary only —
  `github.event.pull_request.number` is null for dispatch events, so the action's
  internal post-step failed silently, and the old-comment collapse step then minimized
  all prior review comments, leaving the PR thread silent. Fixed by a "Post review
  comment for dispatched run" step that reads the last assistant text from the execution
  file and posts it via `gh issue comment`. When the review finds no new issues, Claude
  is prompted to link the most recent prior `claude[bot]` review comment and state it
  still stands. Execution file extraction (for debugging):
  ```
  jq -r '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text] | last // ""' \
    "${RUNNER_TEMP}/claude-execution-output.json"
  ```
- **Dispatched review quoting bug (gha#90, not yet fixed).** When the review body
  contains backtick-quoted text (e.g. `` `@v1` ``), the "Post review comment for
  dispatched run" step fails with `unexpected EOF while looking for matching '"'` — the
  backticks are interpreted as shell command substitution. The review itself still
  completes: look for `Claude review completed cleanly (subtype=success)` in the step
  logs to confirm. The PR comment simply isn't posted. Workaround: push a trivial
  commit to trigger the push-based review instead of dispatching again.
- **Self-mod skip in `claude-code-review.yml` (added in gha#70, now in `v1`).** The
  workflow skips when the PR modifies `.claude/**` paths or the
  review workflow file itself (derived from `github.workflow_ref`). CI completes in
  ~48 s without posting a verdict comment. This prevents 401 errors from the
  App-token exchange during workflow validation of a not-yet-merged workflow file
  (source: gha#70 PR body). Not a CI failure — check the job logs for the skip message.
- **`grep -qxF` for literal fixed-string line matching in workflow files.** Flags: `-q`
  = quiet, `-x` = full-line match, `-F` = treat pattern as a fixed string (not a
  regex). Omitting `-F` makes `.` in file paths (e.g.
  `.github/workflows/claude-code-review.yml`) act as a regex wildcard, so the selfmod
  check would match any file with a similar path structure. Use `-qxF` whenever
  comparing file paths literally. The `selfmod` step in `claude-code-review.yml` uses
  `grep -qxF` for this reason.
- **`is_error=true, subtype=success` in review execution output — two distinct causes:**
  - **Quota/auth exhaustion** (`total_cost_usd=0`, `num_turns=1`, `duration_ms` < 2000):
    the API rejected the request before Claude did any work. Fixed in gha#102 (`@v1`):
    the guard step exits 0 and posts a `[!WARNING]` PR comment naming `CLAUDE_CODE_OAUTH_TOKEN`
    as the account whose quota is exhausted. Further fixed in gha#104: a second `require-review`
    gate job (whose `if:` is false when `quota_exhausted=true`) shows as the gray **skipped**
    icon rather than a misleading green checkmark. Consumers should add `require-review` (e.g.
    `review / require-review`) to their branch protection required-checks.
    Fix: wait for quota reset (or auth fix), then re-trigger. No need to push a commit.
    ⚠️ **Verify the consumed guard actually warns — don't assume the fix is live.**
    Observed 2026-06 on sparta#207 (consuming `d-morrison/gha@v1`) AND in `dem-extra1/gha`'s
    own `claude-code-review.yml`: the guard still `exit 1`d on `is_error=true` (RED check, no
    `[!WARNING]` comment) — gha#102's exit-0 behavior was not yet on the consumed `@v1` pin
    there. Read the actual guard code on the pin you consume rather than trusting this note.
    Note OAuth/subscription auth (`CLAUDE_CODE_OAUTH_TOKEN`) shows `total_cost_usd=0`
    regardless, because it isn't metered per-call — so cost=0 + 1 turn + immediate `is_error`
    points to a **subscription usage-limit**, not only API credits; confirm via the Anthropic
    Console usage for that account.
  - **Intermittent upstream bug** (`total_cost_usd > 0`, `duration_ms` ~192 s): the
    `claude-code-action` completes a real review but exits with `is_error=true` anyway.
    The guard step fails the check ❌. The prior clean review on the same diff is still
    valid. Fix: push a trivial commit to trigger a fresh review. Observed on gha#92 run
    #28034977099.
- **Reading the hidden error behind a failed `claude-code-review`.** The action prints
  `Running Claude Code via SDK (full output hidden for security)…` and suppresses the real
  API error. The reusable `claude-code-review.yml` now accepts a **`show-full-output`** input
  (default false; added in dem-extra1/gha#1) that passes through to the action's
  `show_full_output` — flip it to print the raw error in the job log. The live consumer pin
  `d-morrison/gha@v1` may not carry it yet, so check the tag. You CANNOT side-channel the
  error from a throwaway workflow on a feature branch: `claude-code-action` rejects `push`
  events (`Unsupported event type: push`) and refuses to run unless the workflow file is
  byte-identical to the default-branch copy (`Workflow validation failed … must … match the
  default branch`) — both are deliberate guards, so a diagnostic workflow only works once
  it's on `main`.
- **Write accurate `workflow_dispatch` comments when adapting the upstream
  `claude-code-review.yml` template.** The upstream template says "workflow_dispatch is
  fired by claude.yml" — but that's only true when the repo's `claude.yml` actually
  dispatches the review workflow. In repos where `claude.yml` runs `claude-code-action`
  directly (e.g. qbt), that comment is wrong. When adapting the template, check whether
  the local `claude.yml` dispatches `claude-code-review.yml`; if not, rewrite the
  comment to say "workflow_dispatch is a manual re-review from the Actions UI" rather
  than citing `claude.yml`. The `PR_NUMBER` env comment (was "when claude.yml triggered
  us") should become "when a manual re-review is triggered." Fixed in rpt#153 and qbt#43.
- **`@claude review` produced no review? Trace the whole dispatch chain — the
  failure is usually in the *dispatched* review run, not the agent run.** An
  `@claude review` *comment* fires the agent workflow `claude.yml` (issue_comment),
  which **succeeds** and then, in a later step (a regular step after the Claude run —
  not an Actions post-step), re-dispatches `claude-code-review.yml` via
  `gh workflow run` (workflow_dispatch). So a green `claude.yml` run with no review
  comment means the review died in the separately-dispatched run. Find it:
  `actions_list` the runs of `claude-code-review.yml` filtered to
  `event=workflow_dispatch` around the comment time, then read that run's failed
  job logs. Don't stop at the agent run's green checkmark. (Diagnosed on rme#706:
  agent run 28256515868 was green; the dispatched review run 28257175025 had failed.)
- **`allowed_bots` actor gate: dispatched reviews fail in ~6 s with "Workflow
  initiated by non-human actor: github-actions (type: Bot)".** `anthropics/claude-code-action`
  has its **own** actor gate, separate from the workflow's job-level `if:`. Because
  `claude.yml` re-dispatches as `github-actions[bot]`, the action aborts
  ("Add bot to allowed_bots list or use '*'") unless the action step sets
  `allowed_bots: "github-actions[bot]"` in its `with:` (underscore — the action's
  own input name; the gha reusable exposes this as `allowed-bots` with a hyphen
  and maps it through). A job `if:` that permits
  `workflow_dispatch` is **not** enough — the run passes the `if:` then dies one layer
  deeper in the action. The canonical gha reusable `claude-code-review.yml` already
  sets this (via its `allowed-bots` input, default `github-actions[bot]`); a
  standalone copy must add it. Fixed for rme in #945.
- **Consumer repos may carry a standalone `claude-code-review.yml` that has drifted
  from the gha reusable one — check gha first when debugging CI/infra bugs.** Not
  every consumer calls `uses: d-morrison/gha/.github/workflows/claude-code-review.yml@v1`;
  some (rme, pre-#948) kept a hand-maintained fork that missed fixes gha already
  had — that drift is how the `allowed_bots` bug reached rme. When debugging a
  CI/infra bug in a consumer repo, compare against the canonical gha `@v1` version;
  the fix often already exists there. Preferred remedy: migrate the standalone file
  to a thin reusable-workflow caller (gha ships example caller stubs in `examples/`)
  so it can't drift again. Keep the workflow filename and the `pr_number`
  workflow_dispatch input so `claude.yml`'s
  `gh workflow run claude-code-review.yml -f pr_number=<N>` still works, mapping it
  to the reusable's `pr-number` input; set `checkout-submodules: true` if the repo
  has submodules the reviewer must read (e.g. rme's `latex-macros`). Done for rme
  in #948.
- **The `@claude` reviewer may re-raise a finding that was previously rebutted and
  its thread resolved, if a new commit triggers a fresh review cycle.** Each review
  run re-reads the diff from scratch; a rebuttal reply in the thread does not persist
  into the next run's context. Keep the rebuttal text ready to post again. (Hit
  repeatedly on ai-config#267 with the MD060/table-column-style finding.)

## AskUserQuestion (Claude Code harness tool)
- Each entry in `questions[]` **requires a `question` field** (the full question
  text) — `header` + `options` alone fail with `InputValidationError: required
  parameter questions[0].question is missing`. Easy to omit when you build the
  call from options first; include the `question` string every time.
- **`Tool permission request failed: Error: Tool permission stream closed before
  response received`** is a **transient** harness glitch, not a user denial —
  **retry the same call.** Hit AskUserQuestion twice and `ExitPlanMode` twice in
  one web session; every retry went through. Applies to any permission-gated
  harness tool (AskUserQuestion, ExitPlanMode, …), so don't abandon the
  interactive flow or fall back to a workaround on the first failure. (A genuine
  denial reads differently — the user declining the specific action.)

## Bash tool runs under zsh — avoid bash-isms & reserved variable names
- The Bash tool's shell is zsh-initialized, where some names are **read-only
  special variables**: `status`, `path`, `pipestatus`, `argv`, `options`, `?`.
  Assigning to them (e.g. `status=$(...)` in a poll loop) fails with
  `read-only variable: status` and aborts the command.
- Use neutral names instead — `st`, `rc`, `out`, `p`. Bit a `gh run view`
  status-poll loop once; renaming `status`→`st` fixed it.
- **No bash-only builtins.** `mapfile`/`readarray` are undefined in zsh —
  `mapfile -t arr < <(cmd)` fails with `command not found: mapfile`. Iterate the
  glob/list directly instead, e.g. `for d in skills/*/; do s=$(basename "$d");
  …; done`, rather than slurping into an array first. This matters double for
  **skill command blocks**: the user's local shell is zsh too, so a command
  block I write into a skill gets run under zsh — keep it bash/zsh-portable.
  (A `mapfile` loop in the link-skills draft failed this way; PR #71.)

## Skill command blocks — resolve the ai-config repo root with the per-skill symlink
- To `cd` to the repo root from inside a skill, use the **per-skill** form
  `git -C ~/.claude/skills/<this-skill> rev-parse --show-toplevel`, never the
  bare-parent `git -C ~/.claude/skills rev-parse --show-toplevel`. `bootstrap.sh`
  may symlink skills
  *per-child* into a real `~/.claude/skills` directory, so the parent isn't a
  symlink into the repo and `git -C` there fails with "not a git repository".
  The `@claude` reviewer enforces the per-skill form on new skills (it flagged
  the bare-parent form on PR #71); `skill-builder` and `ums` already use it.
- Issue #36 originally proposed the bare-parent `git -C ~/.claude/skills
  rev-parse --show-toplevel` — but that example is the unreliable one (it can
  error with "not a git repository", not a security risk). #36 was closed by
  PR #110, which standardized on the **per-skill** form for `record-learnings`
  and `memorize`; PR #109 swept the last straggler #110 missed (`find-overlap`).
- **Worktree caveat:** the resolved toplevel is the **MAIN** checkout, often on
  another session's branch — don't author files there. Work in your own
  worktree's `skills/<name>/` dir (full rationale in `skill-builder`'s Ship-it
  caveat).
- **Use `<angle-bracket>` placeholders in command blocks — never bare ALLCAPS.**
  `PATH`, `URL`, `TARGET`, etc. look like shell env vars: bare `PATH` looks like
  the `$PATH` env var, and `path` is a zsh special that mirrors `$PATH`. A reader
  who copies the command without substituting the placeholder runs something wrong.
  Use `<path>`, `<url>`, `<target>` instead. (PR #99 fixed `test -e PATH` →
  `test -e <path>` and `curl … URL` → `curl … <url>` in purge-hallucinations.)

## ai-config memory file structure
- Memory files (`memories/*.md`) **may** carry YAML frontmatter (`name`,
  `description`, `metadata`) — while older ones
  start directly with a `#` heading. Don't assume either form: `grep -rn "^name:"
  memories/` finds the frontmatter'd files, and a file without it is still valid.
  Preserve whatever frontmatter a file already has rather than stripping it.
- `[[link]]` cross-links in skills and memories resolve to **skill directories**
  (`skills/<target>/`), not to named entries in memory files. To verify a
  `[[target]]` link: `ls skills/<target>/`. If no skill dir exists, fall back to
  searching memory headings: `grep -rn "^# .*<target>" memories/`.
- System skills (e.g. `claude-api`) may be globally available but have no local
  `skills/<name>/` directory. An absent local dir means ❓ Unverifiable, not
  ❌ Fabricated — check the session's available-skills list before classifying.

## Quarto HTML sites (build & layout gotchas)
Hit while adding a mobile within-chapter TOC to `d-morrison/rme` (#929); apply to
any Quarto website (rme, psw, qwt, …).
- **Single-file `quarto render <file>.qmd` serves cached compiled theme CSS.**
  Edits to `custom.scss` / theme SCSS may NOT appear in the output — Quarto reuses
  the cached sass bundle. The tell: the
  `_site/site_libs/bootstrap/bootstrap-*.min.css` content hash stays identical
  across renders. Force a recompile by clearing the sass cache and the stale libs
  first: `rm -rf ~/.cache/quarto/sass _site/site_libs`, then re-render. (A
  "verified" CSS rule was actually stale until I cleared this.)
- **The within-chapter "On this page" TOC is hidden on mobile with no built-in
  replacement.** Quarto's bootstrap hides `#quarto-margin-sidebar` below the `md`
  breakpoint (`@media (max-width: 767.98px)` in `_bootstrap-rules.scss`). There is
  no `toc:` option to re-enable it; the `quarto-toc-toggle` "convert TOC to a
  floating menu" in `quarto.js` is an overlap-avoidance feature for wide screens,
  not a mobile feature (on a phone the margin sidebar is already `display:none`,
  so it never fires).
- **A cloned within-chapter TOC must NOT carry `role="doc-toc"`.** Quarto's mobile
  CSS includes a bare `nav[role=doc-toc] { display: none }` (inside the `md` media
  query), so any clone with that role stays hidden even when you mean to show it.
  Use a plain `<nav aria-label="…">` instead.
- **Navbar headroom = reveal-on-scroll-up.** Quarto attaches Headroom to
  `#quarto-header`; on scroll it toggles `sidebar-unpinned` on the header AND on
  every `.sidebar` / `.headroom-target` element (see `quarto-nav.js`). To make a
  custom element hide-on-scroll-down / reappear-on-scroll-up in step with the
  navbar, place it inside `#quarto-header` (it inherits the header's transform) or
  give it `.headroom-target`. (Used to put a "Contents" TOC button in the navbar.)
- **`quarto render` auto-modifies `.gitignore`.** On first render, Quarto appends
  `/.quarto/` and `**/*.quarto_ipynb` to `.gitignore`. If `.quarto/` is already
  present, `/.quarto/` is redundant (the unanchored form already covers the root).
  Remove `/.quarto/` only when `.quarto/` is already present; keep `**/*.quarto_ipynb`.
- **Manuscript projects do NOT support `repo-url` / `repo-actions` natively.**
  `book` and `website` inherit `base-website` schema (which includes these keys);
  `manuscript-schema` is `closed: true` with no `super`, so the keys are silently
  ignored even when placed under `website:` or `format: html:` in `_quarto.yml`.
  Workaround: a Lua filter that reads those keys from metadata and injects the links
  via inline JS — see `d-morrison/qmt/_repo-links.lua` for a full implementation.
  Upstream issue: quarto-dev/quarto-cli#14627.
- **In Quarto Lua filters, use `quarto.doc.input_file` (not `PANDOC_STATE.input_files[1]`)
  to get the real source path.** Quarto preprocesses `.qmd` files into temp files before
  passing them to Pandoc; `PANDOC_STATE.input_files[1]` gives the temp path, not the
  original `.qmd`. `quarto.doc.input_file` reads the `quarto-source` param and returns
  the real path. To compute the repo-relative path: strip `os.getenv("QUARTO_PROJECT_DIR")`
  from the front (`abs_input:sub(#project_root + 2)`). (Learned while writing `_repo-links.lua`
  for d-morrison/qmt.)

## d-morrison/gha reusable workflows
Check `d-morrison/gha` before writing bespoke CI — it has reusable workflows for
common patterns.

- **`quarto-publish.yml`** — sets up Quarto, renders, and deploys the site.
  Caller stub is ~12 lines. See `examples/quarto-publish.yml` in the gha repo.
  **`@v1` vs `@v2` differ in HOW they deploy, and the two are mutually exclusive
  at the repo-Pages-source level:**
  - **`@v1`** deploys via the Pages **artifact** (`actions/upload-pages-artifact`
    + `actions/deploy-pages`). Repo setup: Settings → Pages → Source = **"GitHub
    Actions"**. No `gh-pages` branch served.
  - **`@v2`** (gha#118) deploys to the **`gh-pages` branch** (`JamesIves/github-pages-deploy-action`,
    `clean-exclude: pr-preview/`, plus a `.nojekyll`). Repo setup: Settings → Pages
    → Source = **"Deploy from a branch", `gh-pages` / `(root)`**. Caller grants
    `contents: write` (not `pages:write` + `id-token:write`), **even with
    `deploy: false`** (see the reusable-workflow permission rule below).
  - **WHY the switch:** the gha PR-preview family (`preview-deploy`,
    `cleanup-pr-previews`) pushes previews to the `gh-pages` branch. A repo serves
    Pages from **one** source, so Actions-artifact publish + branch-based previews
    can't coexist — under Actions-source Pages, every `…/pr-preview/pr-N/` link
    404s. `rossjrw/pr-preview-action` REQUIRES branch-based Pages. So a repo that
    wants both a main site AND PR previews must use `@v2` + branch Pages.
  - **Branch-served Quarto needs `.nojekyll`** at the gh-pages root, or Jekyll
    strips Quarto's `_`-prefixed asset dirs. `quarto publish gh-pages` adds it
    automatically; `JamesIves` does not, so `@v2` touches one in before deploy.
  - **The repo's Pages *source* is a manual setting** — not changeable via the
    MCP tools or (in scoped sessions) the API. Hand the flip to the user, and
    order it safely: deploy to `gh-pages` FIRST (populates root; live site keeps
    serving the old artifact), THEN flip the source, or the root 404s in between.
- **Convention:** ai-config (and d-morrison repos generally) call `d-morrison/gha`
  reusable workflows with `@v1` (not a SHA-pinned ref). SHA-pinning is the pattern
  for third-party actions only.
- **gha's major tag auto-slides on EVERY merge to main** (`slide-major-tag.yml`,
  r-lib/actions style): it re-points the major derived from the latest `vX.Y.Z`
  tag to HEAD. So a **breaking** change that merges to main **silently slides
  `v1` onto the breaking commit** — `@v1` consumers get it on their next run.
  Cutting a breaking release therefore needs TWO tag moves, run BEFORE the next
  main merge (else the slide re-breaks v1): (1) force `v1` back to the last
  non-breaking commit (`git tag -f v1 <sha>; git push --force origin refs/tags/v1`),
  and (2) create `v2.0.0` + `v2` at HEAD. Once `v2.0.0` exists it's the latest
  semver, so the slide moves `v2` thereafter and `v1` stays frozen. There is NO
  MCP tool to create tags/releases — use `git` (but see the 403 caveat below).
  Notify registered consumers in `REVDEPS.md` (e.g. `Lacaedemon/sparta`).
- **`check-non-standard-chars` (the `chars` selftest job) scans only `.qmd` and
  `.R` files.** Em dashes / smart quotes in workflow YAML comments, README, or
  example stubs pass; the SAME character in a `.qmd` fails CI (`U+2014` etc.).
  When editing gha docs, keep `.qmd` ASCII (`-`/`;`, not `—`).
- **403 caveat — scoped sessions can push ONLY the assigned branch; tag pushes
  are denied.** In remote/web sessions the proxy rejects any ref that isn't the
  harness-assigned branch with `HTTP 403` — including `refs/tags/*`. **`git push
  --dry-run` gives a FALSE POSITIVE here** (it prints `* [new tag] …` because the
  negotiation succeeds, but the real push 403s on the ref update). So you cannot
  cut tags from such a session — hand the exact `git tag` + `git push` commands to
  the user instead. Don't retry the 403 (policy denial, not transient).
- **`mcp__github__actions_list` / `list_workflow_runs` returns HUGE objects**
  (full repo metadata embedded per run, ~30-60KB even at `per_page: 1`), which
  blows the tool-output cap and gets saved to a file. To read a run's
  status/conclusion cheaply, prefer `actions_get` (`get_workflow_run`, single
  object) or parse the saved file with `python3 -c "json.load(...)"`; don't keep
  re-listing.
- **Input-forwarding checklist when adding an input to a gha composite action.**
  Adding a new `inputs:` entry to `<name>/action.yml` requires four coordinated updates:
  1. Expose it in the wrapping reusable workflow (`.github/workflows/<name>.yml`) under
     `on: workflow_call: inputs:`.
  2. Forward it in the reusable workflow's `uses: d-morrison/gha/<name>@v1` step's
     `with:` block.
  3. Update `examples/<name>.yml` (the caller stub) if the input is consumer-visible.
  4. Update the README table row for `<name>.yml` to list the new input under "Key inputs".
  Missing any of these leaves the input wired only partway — consumers can't pass it
  through the reusable workflow even though it exists in the composite. (Caught by
  Copilot on gha#92: `fail-if-empty` was in the composite but not in README or examples;
  a separate pre-existing gap — the `fail` input — was filed as gha#93.)
- **Reusable workflow input descriptions say "workflow run", not "action."** A
  `workflow_call` wrapper is not a composite action — `inputs:` descriptions should say
  "Fail the workflow run …" not "Fail the action …". When copying an input description
  from `action.yml` into the wrapping `workflow_call` file, update "action" → "workflow
  run". (Fixed in gha#92: `fail-if-empty` description in `check-links.yml`.)
- **GitHub Actions job conclusions: no "skipped" from a running job.** A job that has
  started can only conclude `success` or `failure` — never `skipped`. The only way to get
  the gray skip icon on a check is a false `if:` on an *unstarted* job. Pattern for
  infrastructure conditions (quota exhaustion, pre-flight failures): have the main job
  succeed (exit 0) and set an output flag, then add a second gate job whose `if:` is
  false when the flag is set. The gate job is what consumers watch in branch protection;
  it shows skipped (gray) on infra conditions and success on clean reviews. See gha#104
  for the `require-review` job implementation.
- **`mcp__github__get_job_logs` usage.** Two calling modes — use the right one:
  - Single job: pass `job_id` (number) + `return_content: true`. Do NOT pass `run_id` alongside. Without `return_content: true` the tool returns only a `logs_url` download link and `"Job logs are available for download"` — no actual log text.
  - All failed jobs in a run: pass `run_id` (number) + `failed_only: true` + `return_content: true`. Do NOT pass `job_id`.
  The tool's error message ("job_id is required when failed_only is false") is misleading when you pass `failed_only: true` with `run_id`; the issue is actually conflicting parameters.
- **`update-snapshots.yml@v1`** — regenerates testthat snapshots, commits, and pushes.
  Supports `workflow_dispatch`, `/update-snapshots` PR comment (`pr-mode: true`), and
  auto-update before R-CMD-check (`ref: github.head_ref`). Pass system deps via
  `apt-packages`. Added in gha#103; bcs#226 is the reference caller.

## GitHub Actions — gathering prior review context in reusable workflows

When a reusable workflow needs to fetch prior `claude[bot]` review comments for
deduplication, two API endpoints carry different content:

- **`/repos/{owner}/{repo}/issues/{n}/comments`** — top-level PR comments
  (summary/tracking verdicts). Filter to review comments with
  `select(.user.login == "claude[bot]" and (.body | test("### Code Review")))`.
  This pattern discriminates review summaries from `@claude` task-handler responses
  (which also post as `claude[bot]` but use "Claude finished…" / "Claude Code is
  working…" headers, not the "### Code Review" heading the review workflow uses).
- **`/repos/{owner}/{repo}/pulls/{n}/comments`** — inline review findings posted
  via the review API. These are already `claude[bot]`-only (the `@claude` task
  handler posts to `/issues/`, not `/pulls/`), so no content filter is needed.
  Fetch the most recent ~30, map to `"=== Inline finding on {path}:{line} ===\n{body}"`.

Combine both (inline first, summary last) and cap at ~12000 chars with `head -c`.
Require `pull-requests: read` permission in the job that fetches inline comments.

**`GITHUB_OUTPUT` multiline heredoc — always use a random delimiter.**
A static delimiter like `__EOF__` collides with content in prior review comments
(e.g. a review suggestion showing a shell heredoc). Use:
```bash
DELIMITER="eof_$(openssl rand -hex 8)"
{
  echo "my-output<<${DELIMITER}"
  printf '%s\n' "$VALUE"
  echo "${DELIMITER}"
} >> "$GITHUB_OUTPUT"
```
The ai-config `claude-review.yml` (merged in #275) uses a static
`__REVIEWS_EOF__` delimiter instead — accepted by design but is a known
divergence from this best practice.

**Content filter for issue-comments endpoint.** When fetching
`/issues/{n}/comments` for prior reviews, the filter
`select(.user.login == "claude[bot]")` picks up BOTH review summaries AND
`@claude` task-handler responses ("Claude finished…" / "Claude Code is
working…"). Add `and (.body | test("### Code Review"))` to discriminate review
summaries from task-handler posts. The ai-config `claude-review.yml` (#275)
omits this content filter — it was accepted, but task-handler responses can
appear in the `prior-reviews` context.

**`needs.X.result != 'cancelled'` vs `== 'success'`** — when the dependency job
is non-critical (acceptable to proceed without its output), use
`!= 'cancelled'` in the dependent job's `if:` so genuine failures fall through
rather than blocking. When the dependency is truly required, use `== 'success'`
(not `!= 'failure'` — that still runs when the dep was cancelled, which usually
means its output was never produced). (gha#133: `gather-context` failure should
not block `claude-review`.)

## GitHub Actions workflow authoring gotchas

- **Local composite refs (`./`) in reusable workflows resolve relative to the HOST repo.**
  A `workflow_call` reusable workflow living in gha cannot call `./path/to/composite` from
  a CALLER's repo — `./` always resolves to gha itself. Workaround: pass the data the
  composite would have consumed as a plain input (e.g. an `apt-packages` string). Learned
  while extracting `update-snapshots` (gha#103): bcs's `install-system-deps` composite
  couldn't be called; the package list was passed as a string input instead.
- **`secrets: inherit` is NOT needed when the reusable workflow only uses `github.token`.**
  `github.token` auto-injects the caller's token via `permissions:` — not via `secrets:`.
  `secrets: inherit` is only needed for named secrets (`secrets.MY_PAT`, etc.). Automated
  reviewers (claude-bot, Copilot) routinely flag this as a false positive — rebut it by
  confirming the callee has no `secrets:` inputs.
- **A reusable workflow's job permissions are checked against the caller's grant at
  graph-build time — `if:`-skipped jobs are NOT exempt.** A called workflow's job that
  declares `permissions: contents: write` makes the WHOLE call fail with
  `startup_failure` (instant, <1s, no jobs created) if the caller grants only
  `contents: read` — even when that job has `if: inputs.deploy` evaluating false and
  never runs. Consequence: you canNOT offer a "deploy: false ⇒ caller needs only read"
  optimization in a reusable workflow whose deploy job statically requests write; the
  caller must grant write regardless. Keep the read-only work in a separate
  `contents: read` build job (it downscopes its own token), but the caller still grants
  the union (write). Cost me two red CI rounds on gha#118. To debug a `startup_failure`
  with `total_jobs: 0`: it's a graph/permission/parse error, not a runtime one — check
  the called workflow's permission ceilings first.
- **An OMITTED key in a caller's explicit `permissions:` block defaults to `none`, not
  "inherit" — so the caller must enumerate EVERY permission the callee's jobs request.**
  Same `startup_failure` failure mode as above, but the trap is silence: gha's
  `claude-code-review.yml@v1` job requests `actions: read` (for the `github_ci` MCP
  server), and ai-config's caller granted `contents`/`pull-requests`/`issues`/`id-token`
  but never listed `actions` — which then defaulted to `none`, so every review run died
  at `startup_failure` (`The nested job is requesting actions: read, but is only allowed
  actions: none`) and no review ever posted. When wiring a caller stub for a gha reusable
  workflow, copy the `permissions:` block from the matching `examples/<name>.yml` verbatim
  rather than hand-picking keys, and re-diff against it when the stub drifts. (ai-config#224.)
- **Detached HEAD on `pull_request` events.** `actions/checkout` without an explicit `ref`
  on a PR event checks out a synthetic merge commit in detached HEAD — `git push` then
  fails. Fix: pass `ref: ${{ github.head_ref }}` so the branch name is checked out, not the
  merge commit SHA. Required for any reusable workflow that needs to `git push` from a PR
  caller.
- **`always()` + optional upstream job needs an explicit result guard.** The pattern
  `if: ${{ always() && !cancelled() && needs.X.result == 'success' }}` keeps the job
  running when X is *skipped* (non-PR events), but also lets it run when X *fails* —
  causing noise from a job that depended on work that didn't land. Full guard:
  `(needs.X.result == 'success' || needs.X.result == 'skipped')`. (Fixed in bcs#226.)
- **Canonical GitHub privacy-safe noreply email is `<numeric-id>+<username>@users.noreply.github.com`.**
  The bare `<username>@users.noreply.github.com` is not privacy-safe and can match a real inbox.
  For `issue_comment` events, the actor's numeric ID is in `github.event.comment.user.id`:
  `committer-email: ${{ github.event.comment.user.id }}+${{ github.actor }}@users.noreply.github.com`.
- **Both bcs PR gates have a label bypass for non-user-visible changes.** `version-check`
  (`version-check.yaml`, derived from RMI-PACTA's R-semver-check) does a pure version
  comparison and fails if the PR branch version ≤ main's, **but** it skips when the
  `no version increment` label is present. The changelog check (`news.yaml` ->
  gha `check-news.yml`) skips with the `no changelog` label. Both workflows trigger on
  `labeled`/`unlabeled`, so adding the labels re-runs and clears them with no push. For a
  CI-only / workflow-only PR (no user-visible R-package change), apply **both** labels
  rather than bumping `DESCRIPTION` and editing `NEWS.md`. (Verified on ucdavis/bcs#236 —
  corrects an earlier note that claimed `version-check` had no bypass.)
- **bcs `docs` build (altdoc) EXECUTES the rendered man-page examples.** altdoc
  renders each `man/*.Rd` to a `man/*.qmd` and runs the example chunk, so
  `@examplesIf FALSE` does NOT protect an example — the code still runs and a
  data-dependent call fails the `docs` job (`object 'pt_a' not found`). For any
  example that needs the protected/real cohort, use `\dontrun{}` (altdoc renders
  it without evaluating), matching the existing convention (e.g.
  `R/calc_ip_weights.R`). Runnable examples with self-contained synthetic data
  are fine and do execute. (Hit on ucdavis/bcs#238.)
- **`NEWS.md` section headers need a blank line before them.** A bullet that ends
  immediately before a `## Next-section` heading (no blank line) can cause
  `utils::news()` to misparse adjacent sections. Always leave one blank line
  between the last bullet of a section and the next `##` heading. (bcs#275:
  `## Internal` bullet → `## Tests` with no blank line; bot caught it.)
- **`merge_group:` trigger — guard PR-context workflows at the job level.**
  When adding `merge_group:` to a workflow's `on:` block so the GitHub merge
  queue fires CI checks, any job that uses `github.event.pull_request.*`
  context needs `if: github.event_name == 'pull_request'` at the job level —
  otherwise the job errors on merge-group commits where that context is absent.
  A job with a false `if:` counts as skipped (passing) for branch-protection
  purposes. Also update matrix-selection shell conditions that branch on
  `pull_request` to cover `merge_group` too (use release-only matrix for both).
  Affected jobs in bcs: `version-check`, `news`, `lint-changed-files`, and the
  `R-CMD-check` matrix selector. (bcs#275.)
- **bcs `test-coverage` (codecov) is NOT a required check.** A coverage drop
  leaves the PR `mergeable_state: unstable` (not `blocked`) and does not block
  the merge — `docs`, `version-check`, the R-CMD-check matrix, lint, and
  spellcheck are the required ones. So a PR that adds integration code only
  exercisable against protected data (which inherently lowers coverage) can
  still merge once the required checks are green. (Verified merging #238.)
- **During a long review, re-bump `DESCRIPTION` after every `main` merge.**
  `version-check` compares the PR version to *current* main; if main advances
  (another PR bumps `0.0.0.905x`) and you merge main in, the PR's version is no
  longer strictly greater and version-check flips to failing even though it
  passed before. Bump again (e.g. `9057` -> `9058`). (Hit on #238 after main
  moved to 9057.)
- **bcs object-name lint (`.lintr.R` custom `snake_case_ACROs1` rex regex)**
  rejected study/protocol codes like `ab507bs` (a lowercase segment with letters
  *after* digits) until the lowercase branch was widened to
  `some_of(lower), zero_or_more(one_of(lower, digit))`. As of #238 such
  alphanumeric codes are valid name components; before that they failed
  `lint-changed-files` with `object_name_linter`.
- **Sync vignette captions with R-source axis labels after a label fix.**
  A `plot_*()` function's y-axis label and its vignette figure caption often
  carry the same phrase. Changing the axis label in the R source without
  updating the caption leaves a stale inconsistency that the next review round
  will catch. After fixing an axis label, grep the vignette:
  `grep -r "old phrase" vignettes/` to find and update matching captions.
  (bcs#253 round 3.)
- **Check the column's scale before writing an axis label.**
  A `prep_*()` column computed as `mean(...) * 100` is a 0–100 percentage;
  the axis label must say `%`, not `"Probability of …"` (which implies 0–1).
  Inspect the prep function's body or roxygen `@returns` to confirm the scale.
  (bcs#253: `pct_annual` was 0–100, not 0–1 — label was wrong.)
- **Use `geom_point() + geom_errorbar()` for data with a meaningful non-zero minimum.**
  `geom_col()` draws bars from 0; for enrollment-age data (40–70+) this wastes
  most of the chart area and makes ±SD intervals visually tiny. Use
  `geom_point(size = 3) + geom_errorbar(...)` when 0 is not a meaningful
  reference point. (bcs#253: `plot_results_baseline` switch from `geom_col`.)
- **Use `helper-*.R` for shared testthat setup.**
  testthat 3 auto-sources `tests/testthat/helper-*.R` before any tests run.
  Put shared setup (e.g. `make_pt_data()`) in a `helper-*.R` rather than
  repeating it across test files. One test file per source file is the bcs
  convention — `test-plot_fn.R` for `R/plot_fn.R`. (bcs#253.)

## markdownlint / markdownlint-cli2
- **MD060/table-column-style is a real rule, present in `markdownlint-cli2@0.22.1`**
  (added in a recent markdownlint version; the `@claude` reviewer's rule list is
  outdated — it claims rules "top out at MD058", but `MD060/table-column-style` is a
  distinct real rule).
  Under default config it fires ~330 times on the ai-config corpus (2026-06 snapshot;
  count grows as files are added; every table with compact pipe style).
  Reproduction (move aside `.markdownlint-cli2.jsonc` first):
  `npx markdownlint-cli2@0.22.1 "**/*.md" "!codex-skills/**"`. The disable in
  `.markdownlint-cli2.jsonc` is load-bearing; do not remove it on the reviewer's say-so
  — rebut with the reproduction command. (Hit on ai-config#267.)
- **Introducing markdownlint to a legacy corpus — baseline strategy.** Run with all
  defaults first (no config): collect the full violation list. Disable every failing rule
  to achieve a green baseline with zero corpus churn. Re-enable rules incrementally after
  targeted fix passes. This prevents flooding CI with hundreds of pre-existing violations.

## Office Open XML (.docx / .xlsx) — editing committed content
- `.docx`/`.xlsx` are zip archives. To strip or edit content (e.g. remove a sensitive
  link from a committed Word doc): `unzip` the file, edit `word/document.xml` for body
  text, and edit `word/_rels/document.xml.rels` for hyperlink **targets** — a clickable
  URL's address lives in the `.rels` `Target`, not just the visible `<w:t>` text, so
  delete both the `<w:hyperlink r:id="rIdN">...</w:hyperlink>` element and its matching
  `<Relationship Id="rIdN" ... Target="...">` to remove link and address.
- Re-zip from the extracted dir: `zip -r -X out.docx '[Content_Types].xml' _rels docProps word`
  (plus `customXml` if present). Verify with `unzip -t out.docx` and re-extract + grep to
  confirm the removed strings are gone before committing. (Done on ucdavis/bcs#237 to strip
  an internal SharePoint URL and a server reference from a to-do doc.)
