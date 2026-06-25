# User preferences (cross-workspace)

- NEVER assume; ALWAYS verify. Before stating a status/fact/outcome (PR or issue
  state, merge status, CI/review verdict, branch position, file contents) or acting
  on one, confirm it with a tool call — don't rely on what was true earlier in the
  session or what "should" be the case. State drifts between turns. "It should be X" /
  "I left it as X" / "presumably X" are red flags; replace with a fresh check.
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
- When fixing a bug or a fragile/duplicated pattern, grep the WHOLE repo for sibling
  instances and fix them all in one pass — don't patch only the occurrence you happened
  to notice. Otherwise a reviewer flags the missed copies as a separate finding, costing
  an extra round. (Learned on d-morrison/ai-config#45: the `git -C ~/.claude/skills`
  path fix was applied to `ums/SKILL.md` but the identical line in `skill-builder/SKILL.md`
  was missed until review caught it.)
- When writing documentation in a stacked PR (or any branch), only document features whose
  code is actually present on the CURRENT branch's ancestry — `grep` for the symbol/constant
  first. A feature that lives in a sibling branch also targeting `main` is NOT in scope, even
  if conceptually related; documenting it reads as a hallucinated feature and a reviewer will
  flag it. Move those docs to the branch where the code lives. (A specific case of "NEVER
  assume; ALWAYS verify" above.)
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
- When committing, stage the SPECIFIC files you touched — NEVER `git add -A`. The working
  tree often holds unrelated in-flight edits (the user's own UMS/skill commits, another
  draft); `git add -A` silently sweeps those into your commit and onto your PR, bloating the
  review and extending the cycle. List paths explicitly, and `git status` before committing
  to confirm only intended files are staged. (Learned the hard way: a
  `git add -A` swept the user's `scout-peers` skill into an unrelated `/prune` PR, adding
  several extra review rounds.)
- Run a local session in an isolated `git worktree` by DEFAULT, not directly in the shared
  working copy — unless there's a specific reason to use the working copy. This default holds
  for EVERY local session, not just substantial multi-file work or when the user flags the wd
  as "in use" / "do this in a separate repo". The ai-config
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
- When writing multi-step workflow instructions, order the steps to match the actual execution
  sequence. A reviewer flagged on ai-config#186 that "Use the existing PR branch" was placed
  before "Claim a GitHub PR/issue" in CLAUDE.md, even though you must claim the PR before you
  look up and switch to its branch. Wrong ordering misleads the reader about the correct flow.

