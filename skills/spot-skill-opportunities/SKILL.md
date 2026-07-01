---
name: spot-skill-opportunities
description: "Proactively notice, in the moment and not just at a session-end checkpoint, when a repeatable multi-step workflow, decision framework, or tool-integration pattern is emerging during ANY task — then surface it as a candidate skill and hand off to skill-builder, rather than quietly repeating the same hand-rolled steps next time. This is the recognition step; skill-builder is the construction step. Use continuously, whenever you catch yourself repeating a multi-step dance done earlier in this session or a prior one, improvising a workaround for something that will recur, or the user says 'again', 'like last time', 'we did this before', or 'always do X'. Also fires as a standing checklist item inside record-learnings, ums, wrap-up, and post-merge."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# spot-skill-opportunities — notice when work is skill-shaped

The recognition half of "always look for opportunities to create new reusable
skills" (`memories/preferences.md`). `skill-builder` is the construction
half — it scaffolds a skill once one is needed. This skill is what decides
*that* one is needed, and it fires continuously, in the middle of ordinary
work, not only at a session or PR-end checkpoint.

## When this fires

- You repeat a multi-step procedure you (or another session) already did
  earlier — in this conversation or a prior one recorded in memory.
- You improvise a workaround, diagnostic recipe, or decision framework that
  is clearly general enough to recur (not a one-off fix specific to this bug).
- The user says "again", "like last time", "we did this before", "every
  time you...", or gives a verbal standing rule ("always do X") that isn't
  yet backed by a skill.
- A review round (human or bot) surfaces the same correction more than once.
- As a standing checklist item inside `record-learnings` (continuous),
  `ums` (explicit checkpoint), `wrap-up` (session end), and `post-merge`
  (PR end) — those skills defer the recognition judgment call to this one.

## Procedure

1. **Name the candidate pattern.** State in one sentence what the repeatable
   unit is (the trigger, the steps, the output) — if you can't state it
   crisply, it probably isn't skill-shaped yet.
2. **Rule out one-off.** Would this plausibly recur across sessions, repos,
   or users of this config — or is it specific to this single task? Only
   the former is worth a skill. When in doubt, lean toward surfacing it
   anyway and let the user decide (see step 4).
3. **Check it isn't already covered.** Search for an existing skill or an
   in-flight branch before proposing a new one:
   ```bash
   grep -ril "<keywords>" skills/*/SKILL.md
   ```
   If something already owns this concern, suggest extending it instead of a
   new skill.
4. **Surface the suggestion — don't build silently.** Per the standing
   preference, *propose* creating the skill; don't scaffold one unasked
   mid-task (that would derail the task at hand). The exception: when
   you're already inside an explicit skill-authoring context (mid-`ums`,
   mid-`skill-builder`), proceed straight to building.
5. **Hand off to `skill-builder`.** Once the user agrees (or the context
   already sanctioned it), let `skill-builder` do the extend-first check
   and scaffolding — don't duplicate its step 0 here.

## Relationship to other skills

- **`skill-builder`** — the construction step this hands off to. This skill
  never scaffolds a `SKILL.md` itself; it only recognizes the need and routes
  there.
- **`record-learnings`** — passive and continuous like this skill, but covers
  the broader category of learnings (facts, tool quirks, preferences). Its
  "if it's a skill, create it" step is this skill's specific case.
- **`ums`** — the explicit checkpoint version. Its checklist item "did a
  workflow emerge that could be a new skill?" is this skill's standing
  version, run continuously instead of only at the checkpoint.
- **`wrap-up` / `post-merge`** — session- and PR-level bookends that already
  embed a UMS pass looking for exactly this signal; this skill is what fires
  *during* the work, so the pattern is caught before the bookend rather than
  only at it.
- **`consolidate-skills` / `find-overlap`** — the cleanup counterparts for
  skills that already shipped and turned out to overlap; this skill tries to
  prevent that overlap from being created in the first place by checking for
  an existing owner before proposing a new skill.

## Anti-patterns

- ❌ Proposing a skill for a genuinely one-off task with no plausible recurrence.
- ❌ Scaffolding a skill mid-task without surfacing the suggestion first —
  that derails the task at hand and skips the user's call.
- ❌ Skipping the existing-skill check and proposing a near-duplicate.
- ❌ Only noticing the pattern at session end (`wrap-up`) instead of live, in
  the moment when the repetition first appears.
- ❌ Staying silent when a clear multi-step recipe repeats — the standing
  preference is to *always* surface it, not to wait to be asked.
