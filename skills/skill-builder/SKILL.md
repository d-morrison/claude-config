---
name: skill-builder
description: "Build a new skill for the ai-config repo the right way — FIRST check whether an existing skill should be extended instead (search skills/ AND scan every branch for in-flight similar work), and only then scaffold skills/<name>/SKILL.md with proper frontmatter, a discoverable trigger-rich description, a spelled-out/short alias as appropriate, cross-links, and (if it encodes a standing rule) matching preferences.md / CLAUDE.md updates — shipped via branch + PR, reviewer requested, ARDI'd to clean. Use when asked to 'build a skill', 'create a skill', 'make a new skill', 'add a skill', or 'skill-builder'."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# skill-builder — author a new skill (extend-first)

Create — or, preferably, *extend* — an ai-config skill following the repo's
conventions. The prime directive: **don't create a new skill until you've
confirmed no existing one should be extended instead**, and that no other
branch is already building it.

## When this fires

- "build a skill", "create a skill", "make a new skill", "add a skill",
  "skill-builder"
- Any time a repeatable multi-step workflow emerges that's worth codifying —
  proactively suggest capturing it as a skill.

## Step 0 — Extend before you create (do this FIRST, always)

Rule out extending an existing skill *before* scaffolding anything:

1. **Search the live skills** for something that already owns (or is adjacent
   to) this concern:
   ```bash
   cd "$(git -C ~/.claude/skills/skill-builder rev-parse --show-toplevel)"   # the ai-config repo
   ls skills/
   grep -ril "<keywords>" skills/*/SKILL.md
   ```
   If a skill already covers it, **extend that skill** (a new alias, a new
   section, an extra trigger phrase) rather than adding a near-duplicate.

2. **Scan EVERY branch for in-flight work** — you, another CLI session, or the
   `@claude` bot may already be adding it:
   ```bash
   git fetch origin --prune
   for b in $(git branch -r --format='%(refname:short)' | grep -v HEAD); do
     git ls-tree -r --name-only "$b" | grep -iE "skills/[^/]*<keyword>" \
       | sed "s|^|$b: |"
   done
   ```
   If a branch is already building it, **continue that work** (check it out /
   extend its PR) instead of opening a colliding parallel branch.

3. **Decide explicitly: extend (preferred) or new.** State which and why before
   writing a line. A new alias or section almost always beats a whole new skill.

## Anatomy of a skill

One directory per skill, `name` matching the directory:

```
skills/<name>/SKILL.md
```

```yaml
---
name: <name>                 # MUST equal the directory name
description: "<what it does>. Use when asked to '<trigger>', '<trigger>', …"
user-invocable: true
allowed-tools:               # include for real skills; omit on thin alias files
  - Bash
  - Read
  - Edit
  - Write
---
```

- **`description` is how the skill gets discovered.** Pack it with *what it
  does* AND the natural-language triggers (`Use when asked to '…'`). The matcher
  reads this — be generous with trigger phrasings.
- Body shape: `# <name> — <tagline>`, then `## When this fires`,
  `## Procedure`, `## Relationship to other skills`, `## Anti-patterns`.
  Concrete commands beat prose.

## Conventions (match the existing family)

- **Pair short names with spelled-out aliases.** When the canonical skill has an
  acronym/short name (`gi`, `sup`, `ums`, `dc`), also create the spelled-out
  alias dir (`grab-issue`, `send-upstream`, `update-memories-and-skills`) — and
  give a memorable short alias to a spelled-out canonical where it helps. The
  alias file is thin and only redirects:
  ```markdown
  ---
  name: <alias>
  description: "Alias for `<canonical>`. <one-line>. Use when asked to '<trigger>'."
  user-invocable: true
  ---

  # <alias> (alias for `<canonical>`)

  This is a spelled-out alias. Read and follow the canonical skill:

  → **`~/.claude/skills/<canonical>/SKILL.md`**
  ```
  Keep the real content in **one** canonical file; aliases never duplicate it.
- **Cross-link** related skills under `## Relationship to other skills`.
- **No registry to update.** Skills are auto-discovered from `skills/` (the
  bootstrap symlink and the plugin root both read the directory) — adding the
  directory is enough.

## If the skill encodes a standing rule

When the skill codifies general guidance or a preference (not just a one-off
procedure), **also** update `memories/preferences.md`, and for top-level
workflow policy add a `CLAUDE.md` section. Standing rule: update **BOTH** the
skill AND preferences — the skill encodes the behavior, preferences make it
persist and fire across all contexts even when the skill isn't invoked.

## Ship it

Skills and memories all live in the ai-config repo — never leave changes
local-only. Commit via a **branch + PR** (not direct to main), request
`d-morrison` as reviewer, then **ARDI to clean**.

> **In a worktree session, the repo toplevel below is the MAIN checkout, not
> your worktree.** `~/.claude/skills` symlinks into the main `ai-config`
> checkout, so `git -C ~/.claude/skills … rev-parse --show-toplevel` returns the
> main repo root — often on another session's branch. Don't `cd` there and don't
> pass that path to Write/Edit: the skill files (and git commits) would land in
> the main checkout, clobbering another session's working tree. Instead author
> the files in your **worktree's own** `skills/<name>/` dir and run git from the
> worktree (it's a full checkout of the same repo). Confirm with
> `git branch --show-current` before committing.

```bash
cd "$(git -C ~/.claude/skills/skill-builder rev-parse --show-toplevel)"   # ai-config root — NOTE: the MAIN checkout, NOT your worktree (see caveat above)
git fetch origin main && git checkout -b add-<name>-skill origin/main
# write skills/<name>/SKILL.md (+ alias dir, + preferences/CLAUDE.md if it's a rule)
git add skills/<name>/SKILL.md memories/preferences.md      # stage the files you
                                                            # touched — NOT `-A`,
                                                            # which sweeps in
                                                            # unrelated edits
git commit -m "skills: add <name> — <summary>"
git push -u origin HEAD && gh pr create --fill
```

Then, as their own explicit steps (don't leave them buried in a comment):

1. **Request the reviewer:** `gh pr edit --add-reviewer d-morrison` (see
   `request-pr-review`).
2. **Drive to clean:** run the `ardi` skill on the new PR until the verdict has
   zero findings.

> Why `git -C … rev-parse --show-toplevel` over `dirname "$(readlink …)"`:
> bare `readlink` (no `-f`) resolves only a single hop and behaves
> inconsistently across macOS/Linux; `rev-parse --show-toplevel` returns the
> repo root directly regardless of how the symlink chain is set up.

## Relationship to other skills

- **`ums` / `record-learnings`** — when a session reveals a workflow worth
  codifying, they hand off to this skill to build it.
- **`memorize` / `remember`** — for a one-line fact or preference (not a
  procedure), write a memory instead of a skill.
- **`request-pr-review`, `ardi`** — used to ship and clean the new skill's PR.
- **`simplify` / `tidy`** — when extending, prefer collapsing into an existing
  skill over proliferating near-duplicates.
- **`heal-skill`** — the repair counterpart: this skill authors a skill,
  `heal-skill` fixes one that misfired after it shipped.
- **`link-skills`** — this skill cross-links the one skill it authors;
  `link-skills` is the corpus-wide audit that catches cross-reference gaps a
  single authoring pass missed.

## Anti-patterns

- ❌ Creating a new skill when an existing one should be extended (skipping step 0).
- ❌ Not scanning other branches → colliding parallel work / duplicate skills.
- ❌ Duplicating canonical content across alias files (aliases must only redirect).
- ❌ A thin description with no trigger phrases — the skill never gets discovered.
- ❌ `name:` not matching the directory name.
- ❌ Encoding a standing rule in the skill but not in `preferences.md`.
- ❌ Leaving the new skill as a local-only uncommitted file (or pushing direct to main).
- ❌ In a worktree session, writing the skill files to the `rev-parse --show-toplevel`
  path — it resolves to the main checkout (via the `~/.claude/skills` symlink), not
  your worktree, so the files land on another session's branch. Author in the
  worktree's own `skills/` dir.
