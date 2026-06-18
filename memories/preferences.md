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
- After creating a PR in a remote/web session (where PR-activity subscription is
  available), always subscribe to its CI/review activity (`subscribe_pr_activity`)
  and follow through — autofix CI failures and address review comments per the
  ARD framework — without asking first. Keep following until the PR is merged or
  closed (or I say stop). Don't ask "want me to watch it?"; just do it.
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
- Keep it simple. Don't over-explain or ask permission for straightforward fixes — just do them.
- When finishing work on an MR/PR (clean review, ready to merge, etc.), always provide a
  clickable link to the MR/PR in the chat message.
- When discovering bugs in upstream/shared infrastructure (e.g., HACtions templates), always
  file an issue immediately — don't ask first.
- Always check r-lib, tidyverse, and similar R ecosystem organizations for off-the-shelf
  solutions before building custom implementations. Prefer well-maintained upstream packages
  over hand-rolled code when they meet the requirements.
- Before starting work on an issue/MR, always review the MR history (merged and closed)
  to ensure the proposed changes don't undo past progress or re-introduce previously
  fixed problems.
- Always simplify code where feasible (without feature loss) — prune dead code paths,
  remove unreachable branches, simplify variable assignments that can never take their
  fallback values given the current invocation context.
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
- "slide <tag>" means force-move a floating Git tag to current main HEAD (delete + recreate + push).
  Common for repos with floating major-version tags that consumers reference.

- "dew it" means "do it".
