# User preferences (cross-workspace)

- NEVER assume; ALWAYS verify. Before stating a status/fact/outcome (PR or issue
  state, merge status, CI/review verdict, branch position, file contents) or acting
  on one, confirm it with a tool call — don't rely on what was true earlier in the
  session or what "should" be the case. State drifts between turns. "It should be X" /
  "I left it as X" / "presumably X" are red flags; replace with a fresh check.
- ALWAYS record what I learn in memory/AI-instruction notes as I work (standing request).
- When creating a GitHub PR, request reviewer `d-morrison` (see request-pr-review skill).
- When deferring work out of scope during a review iteration, always file a follow-up issue
  (via `gh issue create` or `glab issue create`) capturing the deferred item. Don't just
  mention it in a comment — create the issue so it's tracked.
- Always open MRs/PRs after pushing — never ask first ("always yes").
- Always ARDI an open PR/MR to a clean review verdict — don't ask "want me to ARDI it?"
  first, just drive it to clean. (Still don't merge unless asked; "always ardi" means
  always drive to clean, not always merge.)
- "Fully clean" (the ARDI/iterate terminal state) means BOTH: (1) all CI workflows green
  (every required check, not just the review job), AND (2) the latest review is totally
  clean — no nits, and every item not directly Addressed is either Deferred to a tracked
  issue or Rebutted with a rebuttal that actually CONVINCED the reviewer (they didn't
  re-raise it). A rebuttal the reviewer still disputes does NOT count as clean. At
  fully-clean, every INLINE review thread is resolved, and the only open conversation is
  the final all-clear exchange (the reviewer's all-clear comment and your reply to it).
- If you and the reviewer(s) can't reach consensus on an item (rebuttal exchanged, neither
  side budging), escalate to a HUMAN reviewer for the final decision — request `d-morrison`
  via the `request-pr-review` skill (or `gh pr edit <N> --add-reviewer d-morrison`) and
  `@`-mention them with the impasse. Don't loop forever and don't unilaterally override.
- After creating a PR in a remote/web session (where PR-activity subscription is
  available), always subscribe to its CI/review activity (`subscribe_pr_activity`)
  and follow through — autofix CI failures and address review comments per the
  ARD framework — without asking first. Keep following until the PR is merged or
  closed (or I say stop). Don't ask "want me to watch it?"; just do it.
- Before starting a new task, always go issue-first: search the tracker for an existing issue;
  if none covers it, FILE one before branching or opening a PR. Never jump straight into a PR
  without a tracking issue behind it. (see the `st` / `start-task` skill — the issue is the
  durable record of intent/scope/"done" and lets the PR auto-close it via `Closes #N`.)
- Always include `Closes #N` in MR/PR descriptions to auto-close the linked issue on merge.
- On GitLab, assign MRs to `demorrison`.
- Run local validation before pushing R-pkg work: lintr::lint_package(), devtools::document(),
  devtools::test(), devtools::check(), pkgdown::build_site() (per repo copilot-instructions).
- In the HACtions repo, use the `test.hac` project/group as a test bed (always).
- After an iterate loop completes, ALWAYS create follow-up issues for every deferred/acknowledged
  item before reporting done. Never leave deferred items untracked.
- When an MR/PR addresses multiple independent concerns, proactively offer to split it into
  separate MRs/PRs (one per concern). Simpler diffs = easier review, independent merge timelines,
  and less risk of one concern blocking another.
- When deferring items to follow-up issues during a PR/MR review loop, always update the
  PR/MR description with a "Known Deferred Items" section listing each deferred issue
  (with link), description, and rationale. This gives automated reviewers context so they
  stop re-flagging the same items. Include a "Notes for Automated Reviewers" section for
  any recurring false positives.
- When noticing potential improvements to the codebase while working, proactively suggest them
  (don't wait to be asked). The user wants to hear about improvements as they come up.
- Always run /ums (Update Memories and Skills) after finishing a task — don't wait to be asked.
- After a PR/MR merges, run the `post-merge` skill: verify the merge actually landed, tidy the
  local branch (checkout main, pull, `git branch -d`), confirm any deferred items are tracked,
  then run UMS to capture what the PR's review lifecycle taught — mistakes corrected and guidance
  given along the way. A merge is the natural checkpoint to bank lessons before context is lost.
- Keep it simple. Don't over-explain or ask permission for straightforward fixes — just do them.
- When finishing work on an MR/PR (clean review, ready to merge, etc.), always provide a
  clickable link to the MR/PR in the chat message.
- When discovering bugs in upstream/shared infrastructure (e.g., HACtions templates), always
  file an issue immediately — don't ask first.
- Always check r-lib, tidyverse, and similar R ecosystem organizations for off-the-shelf
  solutions before building custom implementations. Prefer well-maintained upstream packages
  over hand-rolled code when they meet the requirements.
- When borrowing code or ideas from another repo, verify its license from the source FIRST
  (fetch its LICENSE file / `gh api repos/<o>/<r>/license`). MIT/BSD/Apache/ISC → may adapt
  WITH attribution recorded in a root `CREDITS.md` (keep copyright notices); no-license /
  "all rights reserved" → reimplement the *idea* clean-room, never copy text/code verbatim;
  copyleft (GPL/AGPL/MPL) → flag the compatibility consequence before copying. The
  `/scout-peers` skill encodes the full survey → license-gate → borrow-with-attribution loop.
- Before starting work on an issue/MR, always review the MR history (merged and closed)
  to ensure the proposed changes don't undo past progress or re-introduce previously
  fixed problems.
- Before building setup/infra/toolchain config in a repo, fetch origin/main and scan the
  repo's own reference material (e.g. `references/`, `docs/`) and recent main commits for
  an existing or just-merged solution — build on / align with it rather than a parallel,
  possibly contradictory approach. (Learned after drafting a juliaup-based Julia install
  that conflicted with the repo's reviewed curl+tarball cloud-setup reference.)
- Always simplify code where feasible (without feature loss) — prune dead code paths,
  remove unreachable branches, simplify variable assignments that can never take their
  fallback values given the current invocation context.
- Avoid nested function calls and nested function definitions where feasible — prefer
  named intermediate variables (or a pipe, e.g. `|>` / `%>%` in R) over `f(g(h(x)))`, and
  prefer top-level function definitions over functions defined inside other functions.
  Keep the nesting only when flattening it would be more convoluted. (CLAUDE.md "Coding
  style" section has the full rationale.)
- Follow the SERG lab manual (https://ucd-serg.github.io/lab-manual/) for coding and
  collaboration conventions.
- When mentioning GitLab/GitHub pipelines, jobs, or commits in prose, always hyperlink them:
  - Pipelines: `[#3330](https://host/project/-/pipelines/3330)`
  - Jobs: `[job 11056](https://host/project/-/jobs/11056)`
  - Commits: `[320d7ad](https://host/project/-/commit/320d7ad)`
- When linking to MRs/PRs, link to the bottom of the page so the user doesn't have to scroll:
  - GitLab: use a specific note anchor (e.g., `#note_11437`); there is no symbolic "latest" anchor
  - GitHub: use a specific comment anchor (e.g., `#issuecomment-4739921085`); there is no symbolic "latest" anchor
- When stopping work on an MR/PR (end of conversation, pausing, handing off), always post
  the MR/PR link so the user can click through immediately.
- When the user provides general guidance or a new preference, always update BOTH the
  relevant skills AND `/memories/preferences.md`. Skills encode the behavior; preferences
  ensure it persists and is visible across all contexts.
- After adding or updating skills OR memory files in the ai-config repo, always commit
  and push everything to origin (on the current branch if a PR is already open, or
  create a new branch + PR if the change is out of scope). Never leave ANY changes in
  ai-config as local-only uncommitted edits — including memory files.
- When committing, stage the SPECIFIC files you touched — NEVER `git add -A`. The working
  tree often holds unrelated in-flight edits (the user's own UMS/skill commits, another
  draft); `git add -A` silently sweeps those into your commit and onto your PR, bloating the
  review and extending the cycle. List paths explicitly, and `git status` before committing
  to confirm only intended files are staged. (Learned the hard way: a
  `git add -A` swept the user's `scout-peers` skill into an unrelated `/prune` PR, adding
  several extra review rounds.)
- The ai-config working copy is often in use by CONCURRENT Claude sessions; untracked or
  uncommitted files there can be silently wiped by another session (branch switch /
  `git clean`). For substantial multi-file work in ai-config — and ALWAYS when the user
  says the wd is "in use" / "do this in a separate repo" — work in an isolated `git worktree`
  off `origin/main` (`git worktree add -b <branch> ../ai-config-worktrees/<branch> origin/main`),
  not the shared wd. Clean it up after merge with `git worktree remove`. (Learned when a
  concurrent session deleted a freshly-written, still-untracked skill file from the wd.)
- When creating a new acronym/short-name skill (e.g., `gi`, `sup`, `ums`), always also
  create a spelled-out alias skill (e.g., `grab-issue`, `send-upstream`,
  `update-memories-and-skills`) that points to the canonical file.
- During ARDI loops: if a round has only Rebut/Defer dispositions (no code pushed),
  still explicitly re-request review — the push won't auto-trigger the reviewer bot.
  BUT the converse: when a round DID push code, the push already triggers the review
  workflow — do NOT also post "@claude review again". On workflows with
  `concurrency: cancel-in-progress` (d-morrison/gha) the two runs cancel each other,
  leaving the latest commit with a canceled, never-posted verdict. If a review ends up
  canceled with no comment, dispatch one cleanly: `gh workflow run claude-review.yml -f pr_number=<N>`.
- In R/Quarto/Rmd prose, prefer inline R expressions (`` `r ...` ``) over hard-coded
  numbers that came from the analysis (means, counts, p-values, sample sizes) so the
  text never goes stale on re-render. Hard-coded literals are fine for genuine constants
  (a chosen threshold, a year). Example: [ucdavis/bcs#191 review comment r3437005734](https://github.com/ucdavis/bcs/pull/191/changes#r3437005734).
- Always look for opportunities to create new reusable skills from multi-step processes.
  When a workflow emerges that could be codified, proactively suggest creating a skill for it.
- When asked to build/create a new skill, FIRST check whether an existing skill should be
  extended instead — search `skills/` for an adjacent one AND scan ALL branches (`git ls-tree`
  over every remote branch) for in-flight similar work — before scaffolding a new one. Prefer
  extending (a new alias/section/trigger) over a near-duplicate skill; if another branch is
  already building it, continue that work rather than opening a colliding branch. (see the
  `skill-builder` skill.)
- "slide <tag>" means force-move a floating Git tag to current main HEAD (delete + recreate + push).
  Common for repos with floating major-version tags that consumers reference.

- "dew it" means "do it".
- After implementing a feature or fix, ALWAYS commit and push immediately — don't wait
  for the user to ask "why haven't you pushed?" The implementation isn't done until the
  code is committed, pushed, and (if applicable) an MR is opened.
