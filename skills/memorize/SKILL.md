---
name: memorize
description: "Persist a fact or preference to memory that survives across sessions, machines, and agents — routed by relevance to project-specific or general scope. Use when the user says 'memorize', 'remember that …', '/remember', 'from now on …', 'always/never …', 'note that …', or 'add to memories'. (`remember` / `/remember` and `always` / `/always` are synonyms.)"
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# Memorize

Persist a single fact or preference so it survives across sessions, machines,
and agents. **`remember` / `/remember` and `always` / `/always` are synonyms
for this skill** — same behavior; the wording the user happens to use doesn't
change anything.

Unlike `ums` (which reviews the whole session and may also update skill
definitions), this stores exactly what the user says — no scanning, no skill
updates. Memory files — and `~/.claude/CLAUDE.md` — are symlinked into the
ai-config repo, so memorize **commits and pushes** the one change; otherwise
the note is lost when the session ends (ephemeral cloud containers are
reclaimed) and never syncs elsewhere.

## When this fires

- "memorize …", "remember that …", "/remember …", "note that …",
  "add to memories: …"
- A standing directive phrased as a preference: "always …", "never …",
  "I prefer …", "from now on …"

## First: is it actually a memory?

If the request is an **automated every-time action** ("after each commit run
X", "whenever I edit Y do Z"), memory can't execute it — that needs a **hook**
in `settings.json` / `settings.local.json` (use the `update-config` skill).
Say so and route it there; don't store a note that will never fire.

## Procedure

1. **Parse** the fact/preference from the user's message.
2. **Choose scope by relevance**:
   - **Project-specific** — a fact, convention, or gotcha tied to ONE specific repo
     ("renders with renv via `R_LIBS_USER`") → write directly to that repo's
     Claude project memory: `~/.claude/projects/<project-path>/memory/<file>.md`
     (NOT `memories/repo/` inside ai-config; that directory is removed). The
     project path is the repo's directory path with `/` replaced by `-` — e.g.
     `/Users/you/Documents/GitHub/rme` → `-Users-you-Documents-GitHub-rme`.
     No git commit is needed for project memory writes — they persist locally.
   - **General standing rule** — an always-apply working preference across ALL
     repos ("always link PRs in tables", "use Pacific time") →
     `~/.claude/CLAUDE.md` (it's loaded every session)
   - **General reference fact** — a cross-project fact that only matters when
     relevant ("gh opens a pager — pipe to cat") → a topical file in
     `/memories/` (e.g. `tools.md`, `debugging.md`)
   - **Conversation-only** → `/memories/session/`
   - When ambiguous between project and general, judge by relevance; default
     to general.
3. **Choose file**: read the target's current contents first. Append to an
   existing section/file if one fits; otherwise create a descriptively named
   file. Don't duplicate — if it's already recorded, update in place rather
   than stacking a second copy, and say so. Delete a memory that turns out
   wrong instead of leaving a contradiction.
4. **Write** a concise bullet (one line preferred), matching the file's voice;
   include the *why* if it isn't obvious. Don't record what the repo already
   documents (code structure, git history) — capture only the non-obvious.
5. **Commit & push** the change so it persists. Skip *only* for
   `/memories/session/` (conversation-only notes shouldn't enter the shared
   repo); **everything else — including `~/.claude/CLAUDE.md` writes — gets
   committed**. This assumes `bootstrap.sh` has symlinked `memories/` and
   `CLAUDE.md` into the ai-config repo (the expected setup). Resolve the repo
   from the `memories/` symlink and stage the file by its path *within* the
   repo (`git rev-parse --show-toplevel` follows the symlink to the repo root,
   robust across one or many hops — unlike single-hop `readlink`):

   ```bash
   [ -L ~/.claude/memories ] || { echo "~/.claude/memories isn't a symlink — run bootstrap.sh first"; exit 1; }
   repo="$(git -C ~/.claude/memories rev-parse --show-toplevel)"   # ai-config repo root
   rel="CLAUDE.md"   # or memories/<file>.md  (NOT memories/repo/ — that's gone)
   git -C "$repo" add "$rel" \
     && git -C "$repo" commit -m "memorize: <one-line summary>" \
     && git -C "$repo" push origin HEAD   # current branch; not HEAD:main — that would push a feature branch's commits onto main
   ```

   The push targets the ai-config repo's **current branch**, so run memorize
   from a checkout on `main` (the normal case) — that's where shared memory
   belongs. In an ephemeral cloud session the push is mandatory: an unpushed
   commit dies with the container.

   **Worktree session / occupied main checkout.** `~/.claude/memories` and
   `~/.claude/CLAUDE.md` are symlinked to the **main** checkout, so
   `git -C ~/.claude/memories rev-parse --show-toplevel` resolves to the main
   checkout — *not* your worktree. If that checkout is on a non-`main` branch
   (e.g. another session is working there, possibly with uncommitted edits),
   committing through the symlink lands your memory on the wrong branch and can
   tangle with that session's work. In that case don't commit through the
   symlink: edit the memory file at its path inside **your** worktree, commit on
   your worktree branch, and land it via branch + PR + merge. It only reaches the
   live symlinked memory once it merges to `main` and the main checkout updates.
   (See the worktree-isolation and no-`cd`-in-worktree bullets in
   `memories/preferences.md`, and the `session-lock` skill.)
6. **Confirm**: one sentence — what was stored, where, and that it was pushed.

## Don't

- Don't run a full session review or touch skill files (that's `ums`).
- Don't commit unrelated changes — stage only the file you wrote.
- Don't push conversation-only (`/memories/session/`) notes to the shared repo.
- Don't store secrets, tokens, or passwords.
- Don't over-elaborate — one bullet per fact.
