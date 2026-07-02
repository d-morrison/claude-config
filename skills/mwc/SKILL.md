---
name: mwc
description: "Grant standing session-scoped permission to merge fully-clean PRs autonomously, without asking per PR, for the rest of the current session. Use when the user says 'merge when confident', 'mwc', 'merge at will', 'maw', 'you can merge PRs when you're confident', or otherwise grants a forward-looking, session-wide merge exception."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# mwc — merge-when-confident (session-scoped merge permission)

## What this grants

Merging is normally human-gated (see `ardi.md`, `merge-it`): a PR gets driven
to fully-clean and reported ready, then I wait for an explicit "merge it" per
PR. `mwc` is a standing exception the user grants **once per session**: for
the rest of **this** session, I may squash-merge any PR I'm driving once it
reaches **fully clean** (`fully-clean.md`) and I'm confident in it — no
separate "merge it" needed for each one.

## When this fires

- "merge when confident", "mwc"
- "merge at will", "maw" (an earlier phrasing for the same grant)
- "you can merge PRs when you're confident (and they're green with
  all-clear reviews)", "merge PRs on your own this session", or any similar
  explicit, forward-looking grant

Distinguish from `merge-it`: `merge-it` means "merge THIS PR now"; `mwc`
means "stop asking me per PR, for the rest of the session."

## Scope and limits

- **Session-scoped, not a standing preference.** Applies only to the current
  conversation; a fresh session (new tab, `/clear`, container restart) starts
  without it. Don't write this grant into `memories/preferences.md` — the
  point is that the user asks for it explicitly, session by session, not that
  it becomes a silent default everywhere.
- **Still requires fully-clean.** Never merge a PR that isn't fully clean
  (`fully-clean.md`: every CI workflow green, latest review has zero
  outstanding findings) just because `mwc` is active — it removes the
  "ask first" step, not the CI-green / review-clean bar.
- **Still requires actual confidence.** If a merge call is genuinely
  ambiguous, CI status is unclear, or `mergeStateStatus` is blocked (see
  `merge-it`'s branch-protection note), stop and ask even with `mwc` active
  — the grant covers routine, unambiguous merges, not judgment calls.
- **Applies session-wide unless the user narrows it.** If the user scopes the
  grant to one PR or repo ("mwc for #42 only"), honor that narrower scope
  instead of extending it everywhere.
- **Merge permission only.** Force-push, `--no-verify`, deleting a branch
  outside the normal `post-merge` tidy, and every other destructive action
  stay gated exactly as before — `mwc` doesn't extend to those.
- **Revocable immediately.** An explicit "stop merging on your own" (or the
  session ending) revokes the grant right away.

## Procedure

1. Acknowledge the grant in one sentence so the user knows it's active for
   the session, and what it does and doesn't cover.
2. For the rest of the session, when a PR I'm driving (via `ardi` or
   otherwise) reaches fully-clean, run `merge-it`'s merge + verify +
   post-merge chain directly instead of stopping to report "ready, merge
   it?" and waiting.
3. Because the grant is a live, explicit user instruction rather than a
   self-authored one, it's safe to bake a self-merge step into a
   `ScheduleWakeup`/`/loop` prompt while `mwc` is active for that session —
   this is the one case where `ardi.md`'s "never bake a self-merge directive
   into a wakeup prompt" caveat doesn't apply, because the merge
   authorization already came from the human, not from a prior Claude turn.

## Relationship to other skills

- **`merge-it`** — the actual merge mechanics (squash, verify, chain to
  `post-merge`). `mwc` just removes the per-PR "merge it" trigger requirement
  for the rest of the session.
- **`ardi`** — drives a PR to fully-clean; `mwc` is what lets that loop merge
  on its own once it gets there, instead of stopping to report ready.
- **`ardia` / `gia`** — multi-PR sweeps; `mwc` lets them merge each PR as it
  clears, instead of accumulating a batch of "ready" reports for the user to
  approve one by one.

## Anti-patterns

- Merging a PR that isn't fully clean because `mwc` is active — the bar for
  "clean" doesn't move.
- Treating `mwc` as a standing preference and writing it into
  `preferences.md` — it's granted per session by the user, not banked as a
  default.
- Assuming `mwc` survives past the session it was granted in.
- Merging through genuine ambiguity (a branch-protection block, unclear CI,
  a deadlocked review) just because asking first is now optional.
