# User preferences (cross-workspace)

- NEVER assume; ALWAYS verify. Before stating a status/fact/outcome (PR or issue
  state, merge status, CI/review verdict, branch position, file contents) or acting
  on one, confirm it with a tool call — don't rely on what was true earlier in the
  session or what "should" be the case. State drifts between turns. "It should be X" /
  "I left it as X" / "presumably X" are red flags; replace with a fresh check.
- NEVER fabricate anything, under any circumstances — always PRODUCE IT FOR REAL.
  Demos/recordings must be captured from the actual system through the real code path
  (not hand-authored data dressed up as a recording); results/metrics must come from
  actually running the thing; screenshots must be of real state. If it can't be produced
  for real yet, do the work to make it real (build the harness, drive the real pipeline) —
  do NOT fall back to "disclosing a limitation" instead, and never mock/synthesize/hand-author
  something and present it as captured or real. (Learned the hard way on sparta#247: a demo's
  "mouse recording" was hand-written JSON; the fix was a cursor-injection seam so a real
  recorder drives the actual game.)
- ALWAYS record what I learn in memory/AI-instruction notes as I work (standing request).
- When recording a factual claim about tool/workflow behavior (an implementation detail
  or a causal explanation derived from a specific source), cite the source inline —
  e.g., "(source: gha#70 PR body)" — so future sessions can calibrate trust and verify
  if needed. Directly observed facts need no citation, but explanations inferred from a PR
  body, commit message, or doc do. (Learned on ai-config#118.)
- When creating a GitHub PR, request reviewer `d-morrison` (see request-pr-review skill).
- When deferring work out of scope during a review iteration, always file a follow-up issue
  (via `gh issue create` or `glab issue create`) capturing the deferred item. Don't just
  mention it in a comment — create the issue so it's tracked.
- Always open MRs/PRs after pushing — never ask first ("always yes").
- Always ARDI an open PR/MR to a clean review verdict — don't ask "want me to ARDI it?"
  first, just drive it to clean. (Still don't merge unless asked; "always ardi" means
  always drive to clean, not always merge.)
- "Fully clean" (the ARDI/iterate terminal state) means BOTH: (1) all CI workflows green
  (every workflow — not just required checks, not just the review job; includes non-gating
  checks like Coverage/codecov), AND (2) the latest review is totally
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
- When there's a well-scoped next step — a filed follow-up issue, a sequenced item, an obvious
  continuation of the current work — just start it; don't pause to ask "want me to keep going?"
  first. The answer is a standing yes. This removes the extra "should I continue?" pause between
  already-scoped steps; it does NOT override holding for genuinely ambiguous or architecturally
  significant decisions. When unsure whether a step is "well-scoped" vs. "needs a decision," lean
  toward continuing and flag any judgment calls made along the way. (Learned on sparta 2026-07-01.)
- If I ask the user a question and they don't answer within ~5 minutes, make an informed guess from
  the conversation, their established preferences, and sensible defaults, then proceed — stating the
  assumption so they can redirect. This lowers the bar to proceed on my own judgment; it does NOT
  mean fire questions and barrel ahead. Still reserve questions for genuine decisions their answer
  would change, and still hold for truly irreversible or high-stakes actions. For the ordinary
  "which of these reasonable options" case, pick the best after a short wait and keep moving.
  (Learned on sparta 2026-07-01, during a high-throughput parallel-PR run where the user was
  away for stretches and didn't want progress to stall on unanswered questions.)
- Operate as a COORDINATOR, not an implementer. Delegate all hands-on implementation to subagents
  (Agent tool, worktree isolation) — even core, high-stakes, architecturally-significant changes.
  Stay at the bird's-eye level: decide WHAT to build and in what order, write precise specs,
  launch/direct agents, sequence merges, verify results, surface decisions to the user, and relay
  feedback to the right agent. Don't drop into editing files, running the suite, or resolving merge
  conflicts by hand when an agent can. What stays mine: the merge button, decisions the user must
  weigh in on, and relaying user feedback — NOT the implementation. Keep the pipeline full; delegate
  broadly and in parallel. (Learned on sparta 2026-07-01: "always delegate; stay at a bird's-eye level.")
- Delegating implementation does NOT mean trusting an agent's "CLEAN, ready to merge" report blind.
  Before merging (or reporting a PR clean), the coordinator double-checks the agent's work against
  ground truth: re-verify CI myself (`gh pr checks <N>` / `gh pr view <N> --json mergeable,mergeStateStatus`
  — a flaky check may have passed by luck, or main may have moved); read the diff on anything
  load-bearing (CI/workflow files, security-relevant code, conflict resolutions — an agent can
  merge-resolve semantically but silently drop one side, so spot-check both features survived); and
  read verification artifacts myself. ESPECIALLY when the bot review self-skipped (a PR that edits
  the review workflow itself — the reusable `claude-code-review` workflow in `d-morrison/gha`, or the
  repo's own caller that invokes it, whatever it's named in that repo — makes the `@claude` bot
  self-skip: it 401s from a PR ref and only runs after merge) or was quota-skipped — then my own diff
  read is the ONLY review. The merge gate is MY independent check, not the agent's word.
- A verification artifact (state transcript, frame/state dump) is worthless unless something actually
  READS it. Put it where the reviewer looks: the `@claude` review bot reviews only the checked-out PR
  tree plus the diff, so a JSON linked by raw URL on a side/media branch is invisible to it — inline a
  compact state summary in the PR conversation/diff (and add a line telling the reviewer to use it); a
  bare link is decoration. And the coordinator must actually read the dumps too — don't build a
  verification tool and then keep trusting agents' written "I verified tick-by-tick" reports without
  ever reading a dump. Design for the CONSUMER first (what the review bot / human sees), then durability.
- Don't merge a PR while ANY of its workflows is red — INCLUDING non-gating checks like the
  `Test coverage` / codecov job — unless there's a specific, deliberate reason stated for THAT merge.
  "It's only the non-gating Coverage job" / "it's a pre-existing flake" is not a blanket pass; the
  project wants to maintain decent coverage, so a red Coverage job is a real signal to fix. If a red
  check is a genuine flake, the fix is to make it green (sequence the flake-fix PR FIRST so main goes
  green, then resync the dependent PRs onto green main) — not to merge past it. Refines the fully-clean
  rule (ALL workflows green, not just the required set). (Learned on sparta 2026-07-01.)
- During multi-PR autonomous work, keep a live TaskList (one task per claimed issue/PR: issue#, PR#,
  branch, state — open/review-pending/merged/blocked) and refresh it with fresh `gh pr view` /
  `gh issue view` queries on any status ask — never recite state from memory (per never-assume/always-verify).
  A merge/close event or an explicit "status?" ask is the trigger to refresh. This is a session tool;
  it doesn't survive `/clear`, so don't rely on it across sessions. (Learned on sparta 2026-07-01, after
  several PRs in flight plus stacked-branch fallout made it easy to lose track.)
- When several in-flight PRs touch the SAME files, merging any one moves `main` and re-conflicts the
  rest — so serialize the merges: merge one, wait for the others to recompute (CONFLICTING/DIRTY, or
  briefly UNKNOWN — re-poll after a few seconds), and merge the next only once it's re-resynced clean.
  Merge the most-isolated PR (disjoint files) FIRST — it rides through without a re-resync; sequence
  foundational/big same-file PRs LAST so lighter PRs rebase onto simpler `main`. An agent watching a
  PR must POLL its own `mergeable`/`mergeStateStatus` on EVERY watch tick (a newly-appearing conflict
  from someone else's merge is NOT a CI event, so a CI-completion monitor never fires on it), and on
  catching one immediately `git fetch origin main && git merge origin/main`, resolve, re-run checks,
  push — staying in the watch loop until the PR is merged or closed (clean regresses to CONFLICTING
  when main moves). The coordinator's nudge is only a backstop for a genuinely-dead agent. (Learned on
  sparta 2026-07-01 merging the movement cluster.)
- **Before grabbing any issue (GI/GII), check that no other session is already on it.** Two signals must BOTH be clear: (1) the issue's most recent comment does NOT contain "Working on this" or equivalent claim; (2) there is NO open PR referencing the issue — by branch name or title, or via a cross-reference event on the issue (which covers most `#N` / `Closes #N` body mentions). If either signal fires, skip that issue — don't open a competing PR or claim it. (Twice grabbed issues already in-flight: sparta#325 had PR #327 open; sparta#292 had PR #329 open. Both required closing a duplicate.) And once both signals are clear, **post your own claim comment the INSTANT you decide to work the issue** — before the investigation phase (reading the body in depth, grepping, designing), not just before branching. The claim flags the issue as actively worked so a parallel session or the `@claude` agent doesn't collide, and that collision risk begins the moment you start investigating. (Learned after investigating sparta#390 fully before claiming, and after fully implementing sparta#404 only to find an unclaimed in-flight PR #405 had already fixed it — a duplicate that had to be closed.)
- Before starting a new task, always go issue-first: search the tracker for an existing issue;
  if none covers it, FILE one before branching or opening a PR. Never jump straight into a PR
  without a tracking issue behind it. (see the `st` / `start-task` skill — the issue is the
  durable record of intent/scope/"done" and lets the PR auto-close it via `Closes #N`.)
  Search EVEN when the idea emerged organically mid-conversation (a design discussion, a
  code-review finding) and feels novel — "I haven't seen it this session" is not evidence
  it doesn't exist. Always `gh issue list --search "<keywords>" --state all` before every
  `gh issue create`, regardless of how the idea surfaced. (Learned on sparta: filed #447
  without searching; the user had already filed #446 with the same core ask minutes earlier,
  and #447 had to be closed as a duplicate and folded into #446.)
- When implementing a user instruction that edits a tracked file in the repo (e.g. CLAUDE.md,
  README, a config file), the task is not done at "made the local edit." Go all the way:
  file an issue, commit on a branch, and open a PR — without waiting to be asked. Stopping at
  a local edit leaves the change uncommitted and invisible to reviewers.
- `dem-extra1/ai-config` is a FORK of the upstream `d-morrison/ai-config`. When working in
  that fork, open PRs against the upstream original (`d-morrison/ai-config`, base `main`) as
  a cross-fork PR with head `dem-extra1:<branch>` — NOT against the fork's own `main`. (If a
  remote/web session is scoped only to `dem-extra1/ai-config` with no `add_repo` tool, the
  cross-fork PR can't be created from that session; push the branch and surface that the
  upstream PR must be opened where `d-morrison/ai-config` is in scope.)
- Always include `Closes #N` in MR/PR descriptions to auto-close the linked issue on merge.
- On GitLab, assign MRs to `demorrison`.
- Run local validation before pushing R-pkg work: lintr::lint_package(), devtools::document(),
  devtools::test(), devtools::check(), pkgdown::build_site() (per repo copilot-instructions).
- Before opening a PR, read the repo's own agent/contributor instructions (CLAUDE.md →
  the canonical reference it points to, e.g. `.github/copilot-instructions.md` / CONTRIBUTING)
  and front-load the required pre-PR housekeeping in the FIRST commit instead of discovering it
  via red CI. For R packages this means a NEWS.md entry AND a `usethis::use_version()`
  DESCRIPTION dev-version bump, even for a docs-only / vignette-only change — see
  `tools.md`'s "R-package PR CI gates" section for the full changelog-check /
  version-check / spellcheck / opt-out-label details.
- In the HACtions repo, use the `test.hac` project/group as a test bed (always).
- After an iterate loop completes, ALWAYS create follow-up issues for every deferred/acknowledged
  item before reporting done. Never leave deferred items untracked.
- When an MR/PR addresses multiple independent concerns, proactively offer to split it into
  separate MRs/PRs (one per concern). Simpler diffs = easier review, independent merge timelines,
  and less risk of one concern blocking another.
- When resolving a git merge/rebase/cherry-pick conflict, consolidate the best of BOTH branches —
  read why each side changed the hunk and preserve both intents; never blind-pick `--ours`/`--theirs`,
  which silently discards the other side's work. Remove every marker (verify with `git diff --check`),
  run the repo's pre-commit checks (a merge clean on each side separately can break combined), then
  stage and finish the operation — don't `--abort`/`--skip` a conflict you were asked to resolve.
  Note: "ours"/"theirs" are reversed in a rebase vs a merge. The `resolve-conflicts` skill (alias
  `rc`) operationalizes this; `sync-pr-branch`/`clean-branches`/`gii` delegate to it. (Distinct from
  `session-lock`/`deconflict-sessions`, which deconflicts AI *sessions*, not git content.)
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
  Do all of this automatically — including opening the follow-up branch and PR that records the
  lessons — without asking permission first; opening that follow-up PR is a standing yes.
- **This applies per-merge, not once per session.** During a backlog-clearing run (many PRs
  merged back-to-back), it's easy to treat "run UMS after merging" as a one-off end-of-session
  step and batch it — wrong: run it after EACH merge, before starting the next PR. Caught on
  sparta (2026-06-30): merged ~8 PRs in one session without running UMS once, until the user
  explicitly said "do ums after each merge; then keep going." The existing instruction already
  covered this; the gap was execution discipline in a fast multi-merge loop, not missing
  guidance — re-read this bullet at the top of every "pick the next backlog item" cycle.
  In a multi-AGENT pipeline, UMS runs at BOTH levels: each subagent runs UMS once ITS PR
  merges (it stops after reporting CLEAN, so the coordinator resumes it post-merge with a
  "your PR merged, run UMS" nudge — or the agent-launch spec bakes in a final UMS step), and
  the coordinator runs its own UMS for the cross-PR orchestration learnings no single subagent
  can see (merge-order sequencing, conflict-cascade handling, pipeline mechanics). Each agent
  writes its OWN memory file plus one MEMORY.md index line to keep the conflict surface small;
  avoid rewriting shared memory bodies concurrently. (Learned on sparta 2026-07-01.)
- Keep it simple. Don't over-explain or ask permission for straightforward fixes — just do them.
- Don't re-ask a decision that's already settled and built. Once an answer is given and the
  work is implemented to match it (and CI-green), don't reopen it with a fresh AskUserQuestion —
  that invites a contradictory answer you then have to reconcile, and discounts work already
  done. If you think the scope should change, say so explicitly with a recommendation instead
  of silently re-asking. (Learned on gha#110: re-asked content structure + deploy after the
  PR was built and green; the user had to reconcile the conflict with "keep what's built.")
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
- When fixing a bug or a fragile/duplicated pattern, grep the WHOLE repo for sibling
  instances and fix them all in one pass — don't patch only the occurrence you happened
  to notice. Otherwise a reviewer flags the missed copies as a separate finding, costing
  an extra round. (Learned on d-morrison/ai-config#45: the `git -C ~/.claude/skills`
  path fix was applied to `ums/SKILL.md` but the identical line in `skill-builder/SKILL.md`
  was missed until review caught it.)
- When renaming a variable or concept, grep for the old term in **both code and
  comments** (including section headers, file-level comments, and inline `# ---` banners).
  A variable rename that also appears in a section header (`# --- 2. Baseline covariates +
  Nelson-Aalen ---`) costs an extra ARDI round every time the header is missed. After
  changing the identifier, run `grep -r "old_name" .` before committing. (Learned on
  ucdavis/bcs#246: `nelson_aalen` → `cumhaz_baseline` fixed the variable and the file
  header but missed the section header — caught two ARDI rounds later.)
- When removing decorative comment banners (e.g. `# ---...---` / `#  Name  #` blocks),
  scan for **every** occurrence in the file — both file-scope banners and inner
  function-body banners. Removing only the outer ones leaves the inner ones, and a
  reviewer catches the inconsistency as a separate finding. Run
  `grep -n "^[[:space:]]*#[[:space:]]*[-=*_#]" file` to surface padded/decorated
  banner lines before committing. (Learned on
  d-morrison/ai-config#274: outer banners stripped in round 1, inner ones missed until
  round 2.)
- Do not commit scratch test files that are not wired into CI. A file like `test_fix.py`
  with a dead `sys.path.insert` at the top and no pytest/CI integration adds noise without
  value and costs an extra ARDI round. Delete it before the initial push, or as soon as
  a reviewer flags it. (Learned on d-morrison/ai-config#274.)
- In test code, express date intervals with lubridate rather than hardcoded day counts.
  Use `lubridate::years(N)` + date arithmetic for calendar-year intervals from a known
  start date, or `lubridate::dyears(N)` when an exact numeric duration (`N × 365.25 × 86400`
  seconds) is what the function under test expects — `years()` returns a Period, `dyears()`
  returns a Duration; pick the one that matches the semantics. Only fall back to a raw day
  count when the function requires one; verify it via `365.25 × N`, not by counting leap
  years manually (e.g., "3 leap years in 2000–2003" is wrong — only 2000 qualifies), and
  confirm with `lubridate::time_length(lubridate::ddays(days_exact), "years") == N`
  (`time_length()` requires a timespan object, not a bare numeric).
  (Learned on ucdavis/bcs#249: using lubridate directly avoids the error class entirely.)
- When writing documentation in a stacked PR (or any branch), only document features whose
  code is actually present on the CURRENT branch's ancestry — `grep` for the symbol/constant
  first. A feature that lives in a sibling branch also targeting `main` is NOT in scope, even
  if conceptually related; documenting it reads as a hallucinated feature and a reviewer will
  flag it. Move those docs to the branch where the code lives. (A specific case of "NEVER
  assume; ALWAYS verify" above.)
- Reference material derived from a repo's own code constants — tables of values, spawn
  layouts, file-format/API semantics — belongs in THAT repo's docs next to the code, not in
  central `ai-config` memory. A memory copy rots silently when the constants change (nobody
  editing the game/library code thinks to update a memory in another repo) and isn't
  discoverable by human contributors. Keep the durable *lesson/gotcha* in memory and point
  at the in-repo docs for the tables. (Learned splitting a sparta scenario cheat-sheet: the
  lesson "team 0 is stationary by default" now lives in sparta's `CLAUDE.md`; the
  speed/UID/order-target tables live in sparta's `demos/README.md` + `REPLAY.md` —
  ai-config#1 / lacaedemon/sparta#207.)
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
  ensure it persists and is visible across all contexts. When the same rule lives in two
  copies (an expanded one in `CLAUDE.md`, a terse one in `preferences.md`), keep
  load-bearing qualifiers/caveats consistent across both — the short copy is the one that
  most easily drops a qualifier and becomes misleading. (Learned on PR #43: the terse
  pipe-examples bullet dropped the "in R" qualifier that `CLAUDE.md` had, which a reviewer
  flagged as implying `|>` / `%>%` exist in Python/JS.)
- After adding or updating skills OR memory files in the ai-config repo, always commit
  and push everything to origin (on the current branch if a PR is already open, or
  create a new branch + PR if the change is out of scope). Never leave ANY changes in
  ai-config as local-only uncommitted edits — including memory files.
- **AI memories, skills, and commands never stay local-only.** When I capture a durable
  learning, commit it to the right repo via PR — GENERAL/cross-project learnings go to
  `d-morrison/ai-config` (as bullets in the right `memories/*.md` topic file); PROJECT-SPECIFIC
  learnings go to that project's own repo (its `CLAUDE.md` / agent docs / `.claude/memories/`).
  A memory kept only under `~/.claude/projects/<path>/memory/` is invisible to other sessions,
  machines, and humans, and rots silently — so migrate it. Capturing a learning isn't done until
  it's committed where the right audience will see it.
- When committing, stage the SPECIFIC files you touched — NEVER `git add -A`. The working
  tree often holds unrelated in-flight edits (the user's own UMS/skill commits, another
  draft); `git add -A` silently sweeps those into your commit and onto your PR, bloating the
  review and extending the cycle. List paths explicitly, and `git status` before committing
  to confirm only intended files are staged. (Learned the hard way: a
  `git add -A` swept the user's `scout-peers` skill into an unrelated `/prune` PR, adding
  several extra review rounds.)
- Run a local session in an isolated `git worktree` by DEFAULT, not directly in the shared
  working copy — only use the working copy when the user explicitly says to. This default
  holds for EVERY local session, not just substantial multi-file work or when the user flags
  the wd as "in use" / "do this in a separate repo". The ai-config
  working copy is often in use by CONCURRENT Claude sessions; untracked or uncommitted files
  there can be silently wiped by another session (branch switch / `git clean`). Create it off
  `origin/main` (`git worktree add -b <branch> ../ai-config-worktrees/<branch> origin/main`),
  not the shared wd. Clean it up after merge with `git worktree remove`. (Learned when a
  concurrent session deleted a freshly-written, still-untracked skill file from the wd.)
  The `session-lock` skill (alias `deconflict-sessions`) tooling automates this:
  `ai-session.sh worktree <branch> [--base origin/main]` creates the isolated worktree,
  `register`/`check` surface collisions, and the registry under `.git/ai-sessions/` lets
  parallel sessions see each other before they clobber the shared checkout.
- When the session runs INSIDE a worktree, do NOT prefix git commands with
  `cd <main-checkout>`. The Bash tool resets cwd to the worktree each call, so a
  `cd <main-repo> && git …` silently runs against the main checkout, not your worktree.
  That checkout is on a different branch, often another session's. Run git in the worktree
  with no `cd`. If you must touch another checkout, use `git -C <path>`. Run
  `git branch --show-current` before committing or pushing to confirm. `gh` commands keyed
  by PR or issue number are cwd-agnostic, so only `git` breaks. Learned on PR #62: a
  `cd`-prefixed push hit `main` and made my own worktree commits look missing.
- Before pushing skill/memory changes to ai-config, run the two local validators that
  `validate.yml` runs in CI — `python3 scripts/validate-skills.py` and
  `python3 scripts/check-links.py` — to catch frontmatter and broken-relative-link errors
  before they cost an ARDI round.
- When creating a new acronym/short-name skill (e.g., `gi`, `sup`, `ums`), always also
  create a spelled-out alias skill (e.g., `grab-issue`, `send-upstream`,
  `update-memories-and-skills`) that points to the canonical file.
- Some skills are platform/global — present in the Claude Code skill registry but with NO
  local `skills/<name>/` directory (e.g. `deep-research`). Cross-references to them are valid.
  Automated reviewers (Copilot, the `@claude` bot) may wrongly flag such a reference as a
  "non-existent skill"; check the available-skills list presented to the agent (the Claude Code
  skill registry) before treating a skill cross-ref as a broken link, then rebut the false
  positive. (ai-config#120 flagged it 4×.)
- During ARDI loops: if a round has only Rebut/Defer dispositions (no code pushed),
  still explicitly re-request review — the push won't auto-trigger the reviewer bot.
  BUT the converse: when a round DID push code, the push already triggers the review
  workflow — do NOT also post "@claude review again". On workflows with
  `concurrency: cancel-in-progress` (d-morrison/gha) the two runs cancel each other,
  leaving the latest commit with a canceled, never-posted verdict. If a review ends up
  canceled with no comment, dispatch one cleanly: `gh workflow run claude-review.yml -f pr_number=<N>`.
- During ARDI loops: always ANTICIPATE what the reviewer will flag next and fix those
  issues preemptively in the same commit. Don't wait for each round to surface issues
  one at a time — read the code holistically, think about what patterns the reviewer
  has flagged in prior rounds (documentation gaps, coupling without cross-references,
  missing edge-case guards, inconsistent accounting), and fix analogous issues elsewhere
  in the same file before pushing. The goal is to minimize back-and-forth rounds.
- During ARDI loops: only stop iterating (without consensus) if you're at a literal
  impasse — going in circles, redoing and undoing the same changes. Asymptotic new nits
  each round is NOT an impasse; keep addressing them. After 3–4 rounds of asymptotic
  noise (new nits appearing each round with no sign of convergence), surface that to
  the user and ask whether to keep going or accept the current state.
- Keep the bot's `@`-mention trigger phrase OUT of PR/issue comment prose unless you actually
  intend to dispatch. The `issue_comment` trigger fires on the bare mention ANYWHERE in a
  comment — even in a sentence saying you're NOT triggering a review (e.g. an ARD summary noting
  "not posting [the mention]"). A stray mention spawns a run that cancels the push-triggered review
  on `cancel-in-progress` setups. On the d-morrison/gha mention bot it also starts a session whose
  residual-commit sweep can churn the branch. Refer to it obliquely ("re-request review", "the
  review-trigger mention") or split the tokens (e.g. `@ claude`, with a space). (Learned the hard
  way on ai-config#41; ardi/iterate/ard
  carry the warning.)
- Don't ping EXTERNAL people or repos from our OWN repo's PR/issue/commit/comment text. An
  `@username` for a non-team person (e.g. an upstream maintainer) sends them a GitHub
  notification, and the `owner/repo#number` shorthand for an external issue posts a
  cross-reference backlink onto THEIR issue. Both reach into a repo we shouldn't be
  touching. Refer to external people by plain name ("a Quarto collaborator") and external
  issues by a full URL link — never `@name` or `owner/repo#num` — reserving those forms
  for our own team and repos. (ai-config#246: the PR body `@`-mentioned `mcanouil` and the
  commit used `quarto-dev/quarto-cli#NNNNN`, both pinging the very upstream repo the PR was
  meant not to disturb.)
- When writing prose (a PR/issue comment, commit message, chat reply) that references an
  issue or PR in a DIFFERENT repo than the one you're posting in, always disambiguate with
  the full `owner/repo#N` form — never a bare `#N`. GitHub silently resolves a bare `#N` to
  the CURRENT repo, so `#156` typed in an ai-config PR comment links to ai-config#156 even
  when you meant a different repo's #156. This is a correctness bug (a dead or misleading
  link), distinct from the notification-etiquette rule above (which governs whether
  `owner/repo#N` is appropriate to use AT ALL for a given repo, e.g. avoid it for external
  repos you shouldn't ping). Once you've established that a cross-repo reference is
  otherwise fine to make, still spell out `owner/repo#N` in full — don't drop to the bare
  form just because it reads shorter. (ai-config#304: `fxtas#156`/`fxtas#157` written as
  bare `#156`/`#157` in an ai-config PR comment auto-linked to ai-config#156 instead of
  ucdavis/fxtas#156.)
- While I'm iterating a PR, the `@claude` bot (triggered by an `@claude` comment — including
  one I or the user posts mid-loop) runs its OWN ARD and pushes fix commits to the
  SAME PR branch. Before every edit/push during a PR loop, `git fetch` and reconcile
  `origin/<branch>`: sync to the bot's commit and don't redo fixes it already landed. Two
  Claude sessions on one branch is the parallel-session collision `claim-pr`/`session-lock`
  warn about. (ai-config#120: the bot fixed 3 of 4 findings while I worked the same branch.)
- A *suggested fix* (a `suggestion` block or proposed code) from any reviewer — human or bot — can itself be wrong —
  verify it before applying; don't paste it in blind. Check it handles the general case, not
  just the one flagged spot. If the correct fix differs, apply that and say so in the ARD reply
  so the reviewer sees why you diverged. (ai-config#94 round 2: a suggested regex `[>|][-+]?` would have
  blanked every inline `description:` — the very round-1 bug under review; the right fix kept the
  block indicator optional, `[>|]?[-+]?`.)
- In R/Quarto/Rmd prose, prefer inline R expressions (`` `r ...` ``) over hard-coded
  numbers that came from the analysis (means, counts, p-values, sample sizes) so the
  text never goes stale on re-render. Hard-coded literals are fine for genuine constants
  (a chosen threshold, a year). Example: [ucdavis/bcs#191 review comment r3437005734](https://github.com/ucdavis/bcs/pull/191/changes#r3437005734).
- When adding or changing math (LaTeX/Quarto equations — `$...$`, `$$...$$`,
  `\begin{equation}`, `\(...\)`), always verify it actually RENDERS — open the rendered
  HTML page and confirm the equation displays, not just that the build succeeded. A typo
  in a macro can silently break MathJax while the build still passes. For rme, open your
  PR's preview page — e.g.
  `https://d-morrison.github.io/rme/pr-preview/pr-<N>/chapters/proportional-hazards-models.html`
  (the `pr-<N>` previews are per-PR and get deleted when the PR closes, so `<N>` is a
  placeholder for your PR number). (An instance of never assume; always verify, applied to math.)
  - **In a remote/web sandbox the github.io preview may be unreachable** — if the
    environment's network policy blocks `d-morrison.github.io` the proxy answers
    `403` to CONNECT (curl: `CONNECT tunnel failed, response 403`; Chromium:
    `ERR_TUNNEL_CONNECTION_FAILED`), so you can't load the preview to eyeball the
    math. Verify locally instead: `npm i mathjax` (npmjs is allowed through the
    proxy), then init MathJax **with the `[tex]/noundefined` extension loaded**
    (`init({tex:{packages:{'[+]':['noundefined']}}}).then(MJ => MJ.tex2mml(defs + expr))`)
    and check the output. With `noundefined` an undefined macro shows as
    `<mtext mathcolor="red">\cmd</mtext>` (NOT an `<merror>` or a thrown
    exception), so grep for `mathcolor="red"`.
  - **MathJax ignores `\providecommand`** — only `\newcommand` / `\def` /
    `\renewcommand` define a macro. So `\providecommand{\X}{...}` is a *silent
    no-op* whenever `\X` shadows a LaTeX built-in (`\v` caron, `\b` bar, `\u`,
    `\c`, …): the built-in meaning survives and renders broken (rme's
    `\hat{\v{\mu}}` showed a red `\v`). Use `\vec` / `\vecf` (rme defines these
    with `\renewcommand{\vec}{...}`, which properly overrides the built-in), and
    fix upstream by switching `\providecommand` → `\def`/`\renewcommand` for
    built-in names.
- In Quarto, a cross-referenceable figure/table **div** (`::: {#fig-...}` / `::: {#tbl-...}`)
  uses its **last paragraph** as the caption — the caption text must come AFTER the
  image / code chunk / table, not before it. A caption placed first renders as ordinary
  body prose and the float is left uncaptioned. Same rule for both `#fig-` and `#tbl-`
  divs; for a bare pipe/markdown table, put the caption below it with the
  `: Caption {#tbl-...}` syntax. Also: don't give the code chunk *inside* a
  `#fig-`/`#tbl-` div a `fig-`/`tbl-`-prefixed `#| label:` — that registers a second,
  redundant cross-reference id. Give the enclosed chunk a plain label and let the div own
  the `@fig-`/`@tbl-` reference. Refs:
  <https://quarto.org/docs/authoring/figures.html#figure-divs>; ucdavis/bcs#220, #223.
- When a memory, skill, or doc entry points at a location in *another* file, don't cite
  a specific line number — it goes stale the moment that file changes, and a later reader
  who looks it up comes up empty. Quote the section heading or symbol name (e.g. the
  `## Foo` heading) or use a vaguer reference instead. This shares the same root principle
  as the inline-R-expressions rule above: don't bake a volatile value into prose. The same
  goes for ephemeral example URLs — PR-preview deploy links and PR numbers get deleted or
  superseded when the PR closes; parameterize the ephemeral part (`pr-<N>`) rather than
  hardcoding it.
  (ai-config#135 review: a `debugging.md` note cited `scout-peers/SKILL.md` lines
  156/183, which #132's `bfc17ee` had already removed. ai-config#155 review: a hardcoded
  `pr-772` rme-preview URL was flagged — ironically inside the new "verify math renders"
  rule, the very kind of stale-value-in-prose the rule warns against.)
- Always leave yourself handoff notes proactively when pausing — don't wait to be asked —
  especially while a long-running job is in flight (SLURM arrays, builds, CI, background
  tasks, remote agents). Snapshot branch/HEAD, unpushed commits, job IDs + how to check
  status, expected outputs + paths, backups, open decisions, and the exact pick-up steps
  into a project memory, and post a paused-state note on any active PR/MR. See the
  `handoff` and `wait-for-results` skills.
- Always look for opportunities to create new reusable skills from multi-step processes.
  When a workflow emerges that could be codified, proactively suggest creating a skill for it.
  (see the `spot-skill-opportunities` skill — the continuous recognition step that hands off
  to `skill-builder`.)
- When asked to build/create a new skill, FIRST check whether an existing skill should be
  extended instead — search `skills/` for an adjacent one AND scan ALL branches (`git ls-tree`
  over every remote branch) for in-flight similar work — before scaffolding a new one. Prefer
  extending (a new alias/section/trigger) over a near-duplicate skill; if another branch is
  already building it, continue that work rather than opening a colliding branch. (see the
  `skill-builder` skill.)
- "slide <tag>" means force-move a floating Git tag to current main HEAD (delete + recreate + push).
  Common for repos with floating major-version tags that consumers reference.
- Use the `session-lock` skill (alias `deconflict-sessions`) as the detection/recovery layer
  on top of the worktree-by-default policy (see above): register at start, `check` before
  editing, so parallel sessions can see each other. Worktrees are already the default, so most
  sessions start isolated; session-lock surfaces the rare SAME-WORKING-TREE collision before
  files get clobbered. This is the LOCAL counterpart to `claim-pr` (remote) and `sync-pr-branch`
  (reconcile with origin) — use all three together on shared PR work. Registry lives under
  `.git/ai-sessions/` (never committed). Script: `~/.claude/skills/session-lock/scripts/ai-session.sh`.

- When writing a description or comment that will reference a follow-up tracking issue, create the issue first, then use the specific issue URL (e.g. `#229`). Never use the generic issues list URL as a placeholder — a reviewer will catch it and the fix costs an extra ARDI round. (Learned on ucdavis/bcs#226.)
- "dew it" means "do it".
- After implementing a feature or fix, ALWAYS commit and push immediately — don't wait
  for the user to ask "why haven't you pushed?" The implementation isn't done until the
  code is committed, pushed, and (if applicable) an MR is opened.
- Write user-facing prose in my preferred style, per my Principles of Scientific Writing
  guide (https://d-morrison.github.io/psw/ — the authority): limit dependent (subordinate)
  clauses; cut low-content filler and jargon ("in order to" → "to", "due to the fact that" →
  "because", drop "it's worth noting"); prefer plain Anglish words over Latin-derived ones
  ("before" not "prior to", "needed" not "necessary", "use" not "utilize"); prefer short
  simple declarative sentences and active voice; and join ideas with coordinating
  conjunctions (and/but/so/or) over subordinate constructions. Apply this by default to my
  OWN drafts, not just on request. Keep meaning, scope, and load-bearing hedges exact. When
  PSW and the skill disagree, PSW wins. (see the `use-preferred-style` skill, alias `style`;
  the `find-ai-tells` detector, alias `ai-tells`, is the scan-after counterpart.)
- Before presenting non-trivial prose I authored (PR/issue descriptions, commit bodies,
  README/doc/vignette text, long answers meant as deliverable prose), self-check the draft
  for AI tells and cut them — overused vocabulary (delve, tapestry, testament, robust,
  seamless…), the "it's not just X, it's Y" antithesis, mechanical rule-of-three lists,
  hedging stacks, signposting filler ("it's worth noting"), em-dash overuse, bold-leading
  bullets, emoji headers, promotional register. De-slop, don't ban words or flatten voice;
  any single tell is innocent — clustering is the signal. Code, terse status lines, and
  short conversational replies are exempt. This is the scan-after counterpart to the
  plain-prose style above. (see the `find-ai-tells` skill, alias `ai-tells`.)
- It's always OK to register a repo as a consumer in one of our upstream repos'
  reverse-dependency list, without asking — e.g. add it to `d-morrison/gha`'s `REVDEPS.md`
  when a repo starts calling its reusable workflows. Open a small doc-only PR off the
  upstream's `main`. Applies across our orgs: d-morrison, UCD-SERG, ucdavis, UCLA-PHP,
  UCD-IDDRC. The REVDEPS list lets us warn consumers before a breaking tag move, so adding
  is pure upside.
- When adding a new bare keyword directive that routes to a skill (e.g. "merge it"),
  update THREE places to keep routing consistent: (1) `CLAUDE.md` routing documentation,
  (2) the skill's `description:` frontmatter (what the LLM sees when scanning the skill
  list), and (3) the skill's "When this fires" trigger list. If the skill has N synonym
  trigger phrases, list all N in all three places. Missing any one causes inconsistent
  behavior depending on which document is in context first. (Learned on ai-config#125.)
- When documenting in `CLAUDE.md` what a bare directive does, read the skill's procedure
  steps BEFORE writing the description. A mismatch between the prose summary and the actual
  skill logic is a blocker finding — e.g. writing "auto-merges first" when the skill step 1
  says "stop and report if not merged". (Learned on ai-config#125.)
- When writing test plan items for a skill that verifies a precondition and stops if not
  met, describe the test in terms of the SUCCESS state (precondition satisfied), not the
  failure state. E.g. "in a session after a PR has just merged" is correct for a skill that
  stops on unmerged PRs; "with an open PR" is insufficient — it covers only the stop path,
  not the full flow. (Learned on ai-config#125.)
- When editing a skill to introduce a new routing category or exception (e.g. "writes of
  type X don't need a commit"), search the SAME file for ALL other steps that enumerate the
  same category (e.g. "skip list" bullets, "when not to commit" sections) and update them
  consistently. An exception declared in one step but absent from the other step's enumeration
  is a contradiction the reviewer will catch. (Learned on ai-config#172: step 2 said "no
  commit for project memory" but step 5's skip list still said "skip only for /memories/session/".)
- When adding a shared-procedure step to one skill (e.g. "update MEMORY.md as an index"),
  grep sibling skills that perform the same action and add the step there too. Sibling skills
  that diverge on a shared sub-procedure each cost a review round to surface and fix. (Learned
  on ai-config#172: memorize omitted the MEMORY.md index step that record-learnings already had.)
  Put the step in each skill's **numbered action steps** that an agent actually executes, not only
  in a routing or "where to write" header --- a step buried in a description gets skipped by an
  agent following the numbered flow, and the reviewer flags the gap. (Reinforced on
  ai-config#254: the MEMORY.md registration step first landed in routing sections and took
  several review rounds to move into memorize's step 3 and record-learnings' step 4.)
- When writing multi-step workflow instructions, order the steps to match the actual execution
  sequence. A reviewer flagged on ai-config#186 that "Use the existing PR branch" was placed
  before "Claim a GitHub PR/issue" in CLAUDE.md, even though you must claim the PR before you
  look up and switch to its branch. Wrong ordering misleads the reader about the correct flow.
- Repo-specific knowledge does NOT belong in ai-config. When a UMS/learnings pass turns up a
  convention, gotcha, or workflow note tied to one repo we own, check it INTO that repo's own
  agent docs (`CLAUDE.md`, `.github/instructions/*.md`, `.github/copilot-instructions.md`) via a
  PR, so the whole team and every `@claude` session working there sees it — not just my private
  ai-config memory. The `memories/repo/` pattern is retired (don't add to it; `memories/repo/bcs.md`
  was relocated into ucdavis/bcs on ai-config#226, and `sparta.md` was relocated into Lacaedemon/sparta on ai-config#248).
  ai-config still owns genuinely cross-repo lore (`memories/debugging.md`, `tools.md`) and my own
  preferences/workflows — only the single-repo notes move out. (Learned on ai-config#226.)


- **Always show the draft before posting to any external system.** Before running
  `gh issue create`, `gh pr create`, `gh pr comment`, or any equivalent that sends
  content somewhere public, output the draft in the conversation and wait for explicit
  "ok" / approval. This applies even when the user explicitly asked to file/post —
  they still want to see the text first. (Learned 2026-06-26: posted a quarto-cli
  GitHub issue without showing the draft.)

- Before adding a new content section to a Quarto book chapter, search the repo for existing content on the same topic (`mcp__github__search_code` or grep) to catch overlap before committing. Duplicate content costs a review round when the reviewer spots it and asks for consolidation. (Learned on UCD-SERG/lab-manual#360: a new "PR Roles" section was added to `github.qmd` before discovering that `ai-tools/reviewing-copilot-prs.qmd` already covered several of the same roles.)
- When inserting a new section between two existing content blocks, check whether lead-in sentences for the subsequent block become orphaned. A sentence like "Other helpful commands are listed below." becomes a non-sequitur when a new section is inserted before the commands block. (Learned on lab-manual#360.)
- When creating a new `_sec-*.qmd` fragment for a Quarto book, check sibling `_sec-*.qmd` files in the same directory for their heading style (`### Heading {#sec-id}` vs. `**Bold pseudo-headings**`) before committing. Style inconsistency with siblings is a blocker finding in automated review. (Learned on lab-manual#360: used bold pseudo-headings; sibling `_sec-cli-tools.qmd` used `###` subheadings — flagged in round 1.)
- Don't use URLs verbatim from issue body text without verifying they're stable. Beta or staging subdomains (e.g. `beta.p5js.org`) are often ephemeral and will fail link-check CI. Search for the canonical/production URL. (Learned on lab-manual#360: the issue referenced `https://beta.p5js.org/...`; substituted with the GitHub source URL.)
- UCD-SERG/lab-manual branch protection requires at least one human approving review. Bot reviews (automated `@claude` review) alone leave `mergeable_state: blocked`. Request `d-morrison` as a reviewer once the bot gives a clean verdict. (Learned on lab-manual#360.)

- When adding a new `@shared/workflow/*.md` (or `@shared/coding/*.md`, `@shared/writing/*.md`)
  include to `CLAUDE.md`, add the `<!-- Shared with the lab manual; edit
  shared/<dir>/<name>.md, not here. -->` comment on the line immediately before
  the `@shared/...` directive, matching every sibling include. Missing it was
  flagged as a review nit. (Learned on ai-config#297.)
- The `<!-- Shared with the lab manual -->` comment is aspirational, not a
  guarantee: check whether the fragment is actually transcluded in
  `lab-manual`'s matching `.qmd` chapter before asserting it is. On ai-config#336,
  two of three existing `shared/coding/*.md` fragments carried the comment but
  were never added to `coding-style.qmd` (only `avoid-nesting.md` was) — the
  gap survived because the tracking issue (UCD-SERG/lab-manual#328) was closed
  "completed" with an unchecked follow-up box. Don't let a new PR's scope grow
  to fix an unrelated pre-existing gap like this; file a follow-up issue
  instead (UCD-SERG/lab-manual#377) and note it in the PR thread. Also: before closing
  a checklist-style issue as completed, verify no boxes are left unchecked —
  an unchecked box under a "completed" issue is invisible to future sweeps.
- When writing a new shared standing-preference fragment that's wired into more
  than one skill (e.g. a tie-breaker used by both PR-ordering and issue-triage),
  check all the consuming skills first and write the fragment's prose generically
  enough to cover all of them — don't phrase it around only the first skill you
  edit. (Learned on ai-config#297: a "PR" rule had to be broadened to "PR or
  issue" after it turned out to also apply to `gi`'s issue triage.)
- When a new skill claims a convention holds across "all N" existing examples
  (e.g. "the existing three agents all carry this caveat"), check each example
  individually instead of generalizing from a couple you remember reading —
  member-by-member verification catches the odd one out that a summary
  glosses over. (Learned on ai-config#343: `agent-builder` claimed all three
  existing `.claude/agents/*.md` files carried a Bash-caveat that
  `community-demand-scout` doesn't have.)
- Don't describe a sibling skill's current behavior as covering a check it
  doesn't yet perform (e.g. "`link-skills` also checks X"). State what it
  actually does today, and phrase the gap as a manual step or a named
  follow-up, not an implied existing guarantee. (Learned on ai-config#343:
  `agent-builder` implied `link-skills` already audits agent cross-references
  when it only scans `skills/`.)

- When a request matches "add/build/create a skill" (skill-builder's own trigger
  phrases), invoke the `skill-builder` skill via the Skill tool rather than
  freehand-implementing the scaffold-and-ship flow. Skill-builder encodes steps
  that are easy to skip when done ad hoc: the extend-first check, running the
  four local validation scripts (`validate-skills.py`, `check-links.py`,
  `check-vendored-drift.py`, `markdownlint-cli2`) before pushing, registering
  any cited MCP tool in `tool-mappings.yml`, updating `skills.qmd`'s count from
  the actual `skills/` directory count (not a manual +1), cross-linking related
  skills, and explicitly requesting `d-morrison` as reviewer. (Learned on
  ai-config#338 — the `prompt-me`/`pm` skill was built and shipped without
  invoking `skill-builder`, so none of those steps ran; CI happened to catch
  what the scripts would have. Reinforced on ai-config#347 — `resolve-pr-threads`
  was hand-authored and needed a review round to catch a `tool-mappings.yml`
  gap `skill-builder` already documented from a near-identical miss in
  `push-memory` #311.)
- Claim a PR before pushing iterative commits to it, even when you opened the
  PR yourself in the same session — this repo's `@claude` review workflow can
  fire and interleave with an in-flight push. Post the "paws off" comment from
  `claim-pr` right after opening the PR, not just for PRs you're joining
  mid-flight. (Missed on ai-config#338: several commits were pushed across an
  ARDI-style review loop with no claim comment posted.)

## Git author mapping
- Commits by `dem-extra1` to repos owned by `d-morrison`, `ucd-serg`, or `ucdavis` → the true author is `d-morrison` (demorrison@ucdavis.edu); set `--author="Douglas Morrison <demorrison@ucdavis.edu>"` (or amend) when the committing identity is `dem-extra1`.
- Commits to `sparta` by `d-morrison` → the true author is `dem-extra1` (dougmor@gmail.com); set `--author="dem-extra1 <dougmor@gmail.com>"` when the committing identity is `d-morrison`.
