# Local tools & CLIs

## gh (GitHub CLI)
- `gh` opens a pager (alternate buffer) that hangs the agent terminal.
- Always disable it: pipe `| cat` or set `GH_PAGER=cat` (e.g. `gh pr view 116 | cat`).
- **Rate limit is shared (5000/hr) and split GraphQL vs REST.** All tools/sessions/agents share the one user's 5000/hr; **GraphQL has its own, smaller pool that exhausts first** — `gh pr checks`, `gh pr view --json comments`, `gh pr list --json` use GraphQL. When GraphQL is spent, get the same data via REST (still has budget): `gh api repos/<o>/<r>/pulls/<n>`, `.../commits/<sha>/check-runs`, `.../issues/<n>/comments`. `gh api rate_limit --jq .resources` is **free** (doesn't count) — check `core` vs `graphql` remaining/reset before retrying. Don't tight-poll; use a background watcher with `sleep` (parallel sessions drain the shared pool fast).
- **The @claude review bot's author name differs by API:** its comment author is `claude[bot]` in REST (`.user.login`) but `claude` in GraphQL (`.author.login`). A watcher filtering REST comments for `.user.login == "claude"` silently finds nothing — use `"claude[bot]"`.

## Re-triggering the @claude PR *review* (d-morrison Quarto / R-pkg repos, e.g. `psw`)
- Filenames below are those in the **content/package repos** (verified in
  `d-morrison/psw`): the review workflow is `.github/workflows/claude-code-review.yml`
  and the comment-triggered agent workflow is `.github/workflows/claude.yml`.
  (ai-config's *own* bot uses different names — `claude-review.yml` /
  `claude-bot.yml` — so don't infer these from *this* repo's `.github/workflows/`.)
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
- `mcp__github__pull_request_read` `method:` enum: `get` · `get_diff` (PR
  unified diff — equivalent to `gh pr diff`) · `get_status` · `get_files` ·
  `get_commits` · `get_review_comments` · `get_reviews` · `get_comments` ·
  `get_check_runs`.
- `mcp__github__pull_request_read` parameter names are **camelCase** — use
  `pullNumber`, NOT `pull_number`. Snake_case fails silently or errors.
- `mcp__github__add_issue_comment` parameter is **`issue_number`** (snake_case),
  NOT `issueNumber`. This is the opposite of `pull_request_read`. Reload the
  tool schema when unsure rather than guessing.
- `mcp__github__pull_request_review_write` with `method: resolve_thread`
  requires **only `threadId`** (node ID, e.g. `PRRT_kwDO...`); `owner`,
  `repo`, and `pullNumber` are ignored for that method. Thread node IDs come
  from `get_review_comments`.
- Webhook PR-activity events cover comments/reviews/CI *failures* but NOT CI
  *success*, new pushes, or merge-conflict transitions — don't rely on events
  alone to know a PR went green or merged; re-check explicitly.
- **Self-wake to re-check CI in remote/web sessions.** There is no `send_later`
  tool, and the `Monitor` tool can't reach the GitHub API (no `gh`; the only git
  remote is a git-only proxy). Since webhooks don't deliver CI *success*, arm a
  one-shot `Monitor` with `sleep <N>; echo recheck` as a self-check-in timer,
  then re-poll `mcp__github__pull_request_read` (`get_check_runs`) when it fires;
  re-arm until the build goes green. (Foreground Bash `sleep` is blocked — the
  background `Monitor` is the workable timer.) Learned driving rme#929.
- The `gh`->MCP substitution **mapping table** lives in `d-morrison/gha`'s
  `CLAUDE.md` specifically (the "GitHub access in remote / web sessions" table);
  other repos' `CLAUDE.md` (e.g. `ai-config`) do NOT carry it. When a skill or
  doc tells a reader to "use the GitHub MCP tools," name the tools by example
  (`mcp__github__add_issue_comment`, `mcp__github__create_pull_request`,
  `mcp__github__search_pull_requests`) rather than pointing at "the repo's
  `CLAUDE.md` mapping table" — that cross-reference
  resolves only in gha and reads as a fabricated reference elsewhere. (Caught in
  ai-config#137 review: the gip skill referenced a table ai-config doesn't have.)

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
- **Self-mod skip in `claude-code-review.yml` (added in gha#70, now in `v1`).** The
  workflow skips when the PR modifies `.claude/**` paths or the
  review workflow file itself (derived from `github.workflow_ref`). CI completes in
  ~48 s without posting a verdict comment. This prevents 401 errors from the
  App-token exchange during workflow validation of a not-yet-merged workflow file
  (source: gha#70 PR body). Not a CI failure — check the job logs for the skip message.

## AskUserQuestion (Claude Code harness tool)
- Each entry in `questions[]` **requires a `question` field** (the full question
  text) — `header` + `options` alone fail with `InputValidationError: required
  parameter questions[0].question is missing`. Easy to omit when you build the
  call from options first; include the `question` string every time.

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
- Memory files (`memories/*.md`) have **no YAML frontmatter** — the file starts
  directly with a `#` heading. `grep -r "^name:" memories/` always returns empty;
  don't use frontmatter fields to locate or identify a memory file.
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
