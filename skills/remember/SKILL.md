---
name: remember
description: >
  Persist an instruction or fact to long-term memory so it survives across
  sessions. Routes user-wide working preferences to ~/.claude/CLAUDE.md and
  project-specific facts to the project's recalled memory store, choosing scope
  automatically. Use when the user says /remember <instruction>, "remember that
  ...", "from now on ...", or "always/never ...".
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# remember

`/remember <instruction>` persists `<instruction>` to long-term memory so it
applies in future sessions. Two decisions: **where** it belongs (user-wide vs
project-specific) and **how** to write it cleanly.

## Scope: user-wide vs project-specific

Decide from the instruction's content:

- **User-wide** — a general working preference or rule that applies across ALL
  repos and tasks ("always link PRs in tables", "use Pacific time in recaps",
  "prefer X style"). Persist to the user's global instructions,
  `~/.claude/CLAUDE.md`.
- **Project-specific** — a fact, convention, gotcha, or ongoing-work note tied
  to THIS repository ("this package renders with renv via `R_LIBS_USER`", "the
  power report lives in `inst/analyses`"). Persist to the project memory store.

When genuinely ambiguous, ask which scope; otherwise pick the obvious one and
say which you chose.

## Automated behaviors need hooks, not memory

If the instruction is an *automated action* the harness must perform every time
("after each commit run X", "whenever I edit Y do Z"), memory alone can't
execute it — that needs a hook in `settings.json`. Route those to the
`update-config` skill instead (and say so) rather than writing a memory that
never fires.

## Writing a user-wide instruction (`~/.claude/CLAUDE.md`)

1. Read `~/.claude/CLAUDE.md`.
2. If it fits an existing `## section`, append a concise bullet there; otherwise
   add a new `## <short title>` section with a one-paragraph rule.
3. Match the file's voice and formatting. State the rule and, briefly, the why.
4. Don't duplicate an existing rule — update it in place instead.

## Writing a project-specific memory

Use the project memory store that is recalled each session, at
`~/.claude/projects/<project-slug>/memory/` (the `<project-slug>` is the current
repo path with `/` → `-`).

1. Write one fact per file, `memory/<short-kebab-slug>.md`, with frontmatter:

   ```markdown
   ---
   name: <short-kebab-slug>
   description: <one-line summary used for recall>
   metadata:
     type: user | feedback | project | reference
   ---

   <the fact; for feedback/project add **Why:** and **How to apply:** lines>
   ```

2. Add a one-line pointer to `memory/MEMORY.md`:
   `- [Title](slug.md) — hook`.
3. Convert relative dates to absolute. Link related memories with `[[slug]]`.
4. Check for an existing file covering the same thing and update it instead of
   creating a duplicate; delete memories that turn out wrong.
5. Don't memorize what the repo already records (code structure, git history,
   CLAUDE.md). If asked to remember one of those, capture what was *non-obvious*
   about it instead.

## After writing

- Confirm in one line what you saved and the file path.
- If `~/.claude` or the project is a git repo the user version-controls, offer
  to commit the change; don't push unprompted.
