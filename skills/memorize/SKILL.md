---
name: memorize
description: "Add a fact or preference to persistent memory. Use when the user says 'memorize', 'remember that', 'add to memories', 'note that', or gives a directive that should persist across sessions."
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
---

# Memorize

Lightweight single-fact persistence. Unlike `ums` (which does a full session
review), this skill stores exactly what the user says — no scanning, no
skill updates, no ai-config commits.

## When this fires

- User says "memorize …", "remember that …", "add to memories: …",
  "note that …", or similar
- User gives a standing directive phrased as a preference ("always …",
  "never …", "I prefer …", "from now on …")

## Procedure

1. **Parse** the fact/preference from the user's message.
2. **Choose scope**:
   - If it's about the current repo/project → `/memories/repo/`
   - If it's a personal preference or cross-project fact → `/memories/`
   - If it's only relevant to this conversation → `/memories/session/`
   - When ambiguous, default to `/memories/` (user-wide).
3. **Choose file**: read the target directory listing first. Append to an
   existing topical file if one fits; otherwise create a new file with a
   descriptive name.
4. **Write**: add a concise bullet point (one line preferred). Don't
   duplicate — if the fact is already recorded, say so and skip.
5. **Confirm**: tell the user what was stored and where (one sentence).

## Don't

- Don't run a full session review (that's `ums`).
- Don't commit to ai-config (that's `ums`'s job at session end).
- Don't store secrets, tokens, or passwords.
- Don't over-elaborate — one bullet per fact.
