---
name: ums
description: "Update Memories and Skills: review recent session context for lessons learned, then actively update memory files and skill definitions to capture them. Use when asked to 'ums', 'update memories and skills', 'record what we learned', or after a workflow reveals a gap in existing skills/memories."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# UMS — Update Memories and Skills

Actively review recent session context and update all relevant memory files
and skill definitions to capture what was learned. Unlike `record-learnings`
(which fires passively as you work), UMS is an explicit checkpoint: stop,
reflect, and persist.

## When this fires

- User says "ums", "update memories and skills", "record what we learned"
- **At the start of `/clear`** — before context is lost, capture any
  accumulated learnings from the session
- After a workflow reveals a gap (e.g., a skill was followed but missed a
  step, or a preference wasn't encoded)
- After a multi-step session where several learnings accumulated
- When the user says "did you update memories?" (the answer should be "let
  me do that now")

## Procedure

1. **Scan recent context.** Review the conversation for:
   - Mistakes made and corrected (skill gaps)
   - New preferences expressed by the user
   - Tool quirks discovered
   - Workflow steps that were missing or unclear in existing skills
   - Debugging insights
   - Codebase conventions discovered

2. **Categorize each learning.** For each item, decide:
   - Is it a **skill update**? (workflow step missing, procedure unclear)
   - Is it a **memory note**? (tool quirk, preference, debugging insight)
   - Is it **both**? (general guidance → update skill AND preferences)
   - Is it already recorded? (check before writing — avoid duplicates)

3. **Apply updates.** For each item:
   - Read the target file first (skill or memory) to understand current state
   - Make the edit — concise bullet points, not prose
   - If updating a skill: the change should be specific enough that following
     the skill next time would avoid the mistake

4. **Commit and push ALL ai-config changes — via a branch + PR, not direct to
   `main`.** Skills AND memory files both live in the ai-config repo. Discover
   its path with `git -C ~/.claude/skills rev-parse --show-toplevel` (portable
   across macOS/Linux; the older `dirname "$(readlink …)"` resolves only one
   symlink hop). Never leave ANY changes (skills, memories, etc.) as local-only
   uncommitted edits. Run **one** of the two paths below — not both:

   **Stage only the files you actually edited — NEVER `git add -A`.** The
   working tree often holds unrelated in-flight edits (the user's own UMS
   commits, another skill being drafted); `git add -A` sweeps those into your
   commit and onto your PR, where they bloat the review and extend the cycle.
   List the specific paths instead. Then **`git status` to confirm only your
   intended files are staged** — if something unexpected is there, the working
   tree had in-flight work; unstage it rather than bundling it. (Avoid
   `git add -p` here: it needs a terminal and hangs in non-interactive sessions.)

   *Already on the open PR's branch* (e.g. mid-ARDI): commit + push to it.
   ```bash
   cd "$(git -C ~/.claude/skills rev-parse --show-toplevel)"
   git add skills/<name>/SKILL.md memories/<file>.md   # the files you touched
   git commit -m "ums: <brief summary>"
   git push origin HEAD
   ```

   *No PR yet:* branch off main first — a direct-to-main push is denied by
   auto-mode and bypasses review.
   ```bash
   cd "$(git -C ~/.claude/skills rev-parse --show-toplevel)"
   git fetch origin main && git checkout -b ums-<topic> origin/main
   git add skills/<name>/SKILL.md memories/<file>.md   # the files you touched
   git commit -m "ums: <brief summary>"
   git push -u origin HEAD && gh pr create --fill   # then request d-morrison as reviewer
   ```
   **CAUTION:** if a compound `add && commit && push` is **denied**, *nothing*
   was committed — verify with `git status` / `git log` before any `git reset
   --hard`, or you'll silently discard the still-uncommitted edits.

5. **Report what was updated.** Provide a brief summary table:

   | What | Where | Change |
   |------|-------|--------|
   | Poll for new reviews | `iterate/SKILL.md` | Added explicit polling procedure |
   | glab has no --state flag | `/memories/tools.md` | New bullet |

## What to look for (checklist)

- [ ] Did I follow a skill but miss a step? → Update the skill
- [ ] Did the user correct my behavior? → Encode as preference + skill update
- [ ] Did I discover a tool quirk? → `/memories/tools.md`
- [ ] Did I learn a debugging pattern? → `/memories/debugging.md`
- [ ] Did I discover a repo convention? → `/memories/repo/`
- [ ] Did the user express a new preference? → `/memories/preferences.md`
- [ ] Did a workflow emerge that could be a new skill? → Create it
- [ ] Are there existing skills that reference outdated info? → Fix them

## Relationship to record-learnings

- `record-learnings` = passive, continuous, fires as you work
- `ums` = active, explicit, user-invoked checkpoint

Both write to the same destinations. UMS is for when you forgot to
record-as-you-go, or when the user wants to ensure nothing was missed.

## Anti-patterns

- ❌ Saying "I'll remember that" without actually writing it down
- ❌ Updating memories but not pushing skill changes to origin
- ❌ Recording vague lessons ("be more careful") instead of specific ones
  ("always poll for new review after pushing — check commit SHA matches")
- ❌ Skipping the "check existing notes" step and creating duplicates
- ❌ Updating only preferences when a skill also needs the fix
- ❌ `git add -A` — it sweeps unrelated in-flight edits (the user's work, other
  draft skills) into your commit/PR. Stage the specific files you touched.
