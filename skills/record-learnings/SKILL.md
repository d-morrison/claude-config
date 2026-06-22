---
name: record-learnings
description: "Persist discoveries, debugging insights, and working patterns to memory and shared instruction files as you work. Ensures knowledge survives across sessions and is accessible to other AI agents via the shared ai-config repo. Use continuously — after solving a tricky bug, discovering a codebase convention, or learning a tool quirk."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# record-learnings

As you work, actively record what you learn so it's available in future
sessions — both to you and to other AI agents sharing the same config.

## When this fires

- After solving a non-obvious bug (record the diagnosis + fix)
- After discovering a codebase convention (record in repo memory)
- After learning a tool quirk (record in user memory)
- After a failed approach (record what didn't work and why)
- After finding a useful command or pattern (record it)
- When the user says "remember that..." (write it to the memory system directly)

## Where to write

### User-wide memory (`/memories/`)
For facts that apply across all projects:
- Tool quirks (e.g., "gh opens a pager — always pipe to cat")
- Debugging patterns (e.g., "CRLF causes bash EOF errors")
- General preferences
- Cross-project conventions

### Repository memory (`/memories/repo/`)
For facts specific to the current workspace:
- Build commands and their quirks
- Project structure conventions
- CI/CD pipeline behavior
- Test commands and expected outputs

### Shared ai-config skills (`~/.claude/skills/`)
For reusable workflows that other agents should also follow:
- Multi-step procedures (review loops, deployment steps)
- Decision frameworks (when to defer, when to split MRs)
- Tool integration patterns (forge CLI usage)

### CLAUDE.md / copilot-instructions.md
For standing instructions that should always be in context:
- Only for the most critical, always-applicable rules
- Keep these files short — they're loaded every session

## What to record

| Category | Example | Where |
|----------|---------|-------|
| Bug diagnosis | "bash EOF error = CRLF line endings" | `/memories/debugging.md` |
| Tool quirk | "glab has no GITLAB_TOKEN env var" | `/memories/tools.md` |
| Codebase fact | "CI only runs on branch pushes, not PR events" | `/memories/repo/` |
| Workflow | "Always run r-pkg-spellcheck before push" | Skill file |
| Preference | "Always request d-morrison as reviewer" | `/memories/preferences.md` |
| Failed approach | "Don't use merge_request_event with $CI_OPEN_MERGE_REQUESTS" | `/memories/repo/` |

## Process

1. **Recognize the learning moment** — you just solved something, discovered
   something, or the user told you something worth remembering
2. **Categorize** — is it user-wide, repo-specific, or a reusable workflow?
3. **Check existing notes** — read the target file first to avoid duplicates
   and maintain organization
4. **Write concisely** — bullet points, not prose. Include the *why* not just
   the *what*
5. **If it's a skill** — create it in `~/.claude/skills/` (symlink to the
   cloned repo; discover the repo path with
   `git -C ~/.claude/skills/record-learnings rev-parse --show-toplevel`)

## Sharing with other agents

The `~/.claude/skills/` directory is a symlink to wherever you cloned
`ai-config` (discover the path with
`git -C ~/.claude/skills/record-learnings rev-parse --show-toplevel`).
Any skill written there is:
- Available to this agent via the skills system
- Shareable with other agents by cloning/pulling the ai-config repo
- Version-controlled and reviewable via PRs

When creating a new skill that other agents should use:
1. Write it in `~/.claude/skills/<name>/SKILL.md`
2. Branch, commit, push, and open a PR on the ai-config repo
3. The skill becomes available locally immediately (via symlink)
4. Other agents get it after the PR merges and they pull

## General guidance = update both skills AND preferences

When the user provides general guidance or a new preference (not just a one-off
instruction), always update **both**:
1. The relevant skill file(s) — so the behavior is encoded in the workflow
2. `/memories/preferences.md` — so it persists and is visible across all contexts

Skills without a matching preference risk being forgotten when the skill isn't
invoked. Preferences without matching skill updates risk being ignored during
skill-driven workflows.

## Always push skill changes

After adding or updating any skill file, always commit and push to origin:
- If a PR/branch for skill changes is already open, push there.
- Otherwise, create a new branch + PR on the ai-config repo.
- Never leave skill edits as local-only uncommitted changes.

## Anti-patterns

- ❌ Learning something and not writing it down
- ❌ Writing a long paragraph when a one-line bullet suffices
- ❌ Recording in session memory what should be permanent
- ❌ Updating only a skill OR only preferences when general guidance is given
- ❌ Editing skills locally without committing and pushing to origin
- ❌ Duplicating information already in a skill file
- ❌ Forgetting to check if a note already exists before adding
